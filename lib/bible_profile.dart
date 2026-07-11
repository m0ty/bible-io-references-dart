import 'canon_profile.dart';
import 'versification_profile.dart';

/// An immutable pairing of canon membership and exact versification data.
///
/// Canon-only behavior belongs to [CanonProfile]. A [BibleProfile] always
/// names an edition-specific combination, allowing Catholic and Orthodox
/// traditions to expose several profiles without pretending that one numbering
/// system is universal.
final class BibleProfile {
  /// Creates a validated custom Bible profile.
  factory BibleProfile({
    required String id,
    required String displayName,
    required CanonProfile canon,
    required VersificationProfile versification,
  }) {
    _validateProfileKey(id, 'id');
    _validateDisplayName(displayName);
    if (!_sameBookOrder(canon, versification.canon)) {
      throw ArgumentError.value(
        versification,
        'versification',
        'must use the same books and order as canon',
      );
    }
    return BibleProfile._(
      id: id,
      displayName: displayName,
      canon: canon,
      versification: versification,
    );
  }

  const BibleProfile._({
    required this.id,
    required this.displayName,
    required this.canon,
    required this.versification,
  });

  /// The conventional Protestant canon with KJV chapter/verse numbering.
  static final BibleProfile protestantKingJames = BibleProfile(
    id: 'protestant-kjv',
    displayName: 'Protestant / King James Version',
    canon: CanonProfile.protestant,
    versification: VersificationProfile.kingJames,
  );

  /// Alias for [protestantKingJames].
  static BibleProfile get kingJames => protestantKingJames;

  /// Compact alias for [protestantKingJames].
  static BibleProfile get protestantKjv => protestantKingJames;

  /// Every built-in composite profile.
  static List<BibleProfile> get values => _builtInBibleProfiles;

  /// Registry containing all built-in profiles and their CLI-friendly aliases.
  static BibleProfileRegistry get builtIns => BibleProfileRegistry.standard;

  /// Finds a built-in profile by stable ID or alias.
  static BibleProfile? lookup(String idOrAlias) => builtIns.lookup(idOrAlias);

  /// Finds a built-in profile by stable ID or alias, or throws.
  static BibleProfile require(String idOrAlias) => builtIns.require(idOrAlias);

  /// Resolves a serialized profile description through a registry.
  ///
  /// Custom IDs require the caller's custom [registry]; they never silently
  /// fall back to a similarly shaped built-in profile.
  static BibleProfile fromJson(
    Map<String, Object?> json, {
    BibleProfileRegistry? registry,
  }) {
    final id = json['id'];
    if (id is! String) {
      throw const FormatException('Bible profile "id" must be a string');
    }
    final resolved = (registry ?? builtIns).lookup(id);
    if (resolved == null) {
      throw FormatException('unknown Bible profile ID: $id');
    }
    _checkSerializedComponent(
      json,
      key: 'canonProfileId',
      expected: resolved.canon.id,
    );
    _checkSerializedComponent(
      json,
      key: 'versificationProfileId',
      expected: resolved.versification.id,
    );
    return resolved;
  }

  /// Stable lowercase, hyphen-separated machine identifier.
  final String id;

  /// Human-readable profile name.
  final String displayName;

  /// Book membership and canonical ordering.
  final CanonProfile canon;

  /// Explicitly named alias for [canon].
  CanonProfile get canonProfile => canon;

  /// Edition-specific chapter and verse numbering.
  final VersificationProfile versification;

  /// Explicitly named alias for [versification].
  VersificationProfile get versificationProfile => versification;

  /// A stable JSON-compatible description of this configuration.
  Map<String, Object?> toJson() => {
        'id': id,
        'displayName': displayName,
        'canonProfileId': canon.id,
        'versificationProfileId': versification.id,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleProfile &&
          id == other.id &&
          displayName == other.displayName &&
          canon == other.canon &&
          versification == other.versification;

  @override
  int get hashCode => Object.hash(id, displayName, canon, versification);

  @override
  String toString() => 'BibleProfile(id: $id, canon: ${canon.id}, '
      'versification: ${versification.id})';
}

/// An immutable lookup registry for built-in or caller-defined profiles.
final class BibleProfileRegistry {
  /// Creates a registry with unique profile IDs and optional aliases.
  ///
  /// Alias values must name a profile by its canonical ID. IDs and aliases are
  /// matched case-insensitively after trimming input, but stored in canonical
  /// lowercase form.
  factory BibleProfileRegistry({
    required Iterable<BibleProfile> profiles,
    Map<String, String> aliases = const {},
  }) {
    final profileList = List<BibleProfile>.of(profiles);
    final profilesById = <String, BibleProfile>{};
    for (final profile in profileList) {
      final key = profile.id.toLowerCase();
      if (profilesById.containsKey(key)) {
        throw ArgumentError.value(
          profile.id,
          'profiles',
          'contains a duplicate profile ID',
        );
      }
      profilesById[key] = profile;
    }

    final byKey = Map<String, BibleProfile>.of(profilesById);
    final copiedAliases = <String, String>{};
    for (final entry in aliases.entries) {
      _validateProfileKey(entry.key, 'aliases');
      final alias = entry.key.toLowerCase();
      if (byKey.containsKey(alias)) {
        throw ArgumentError.value(
          entry.key,
          'aliases',
          'conflicts with a profile ID or alias',
        );
      }
      final targetId = entry.value.trim().toLowerCase();
      final target = profilesById[targetId];
      if (target == null) {
        throw ArgumentError.value(
          entry.value,
          'aliases',
          'does not name a registered profile ID',
        );
      }
      byKey[alias] = target;
      copiedAliases[alias] = target.id;
    }

    return BibleProfileRegistry._(
      profiles: List<BibleProfile>.unmodifiable(profileList),
      aliases: Map<String, String>.unmodifiable(copiedAliases),
      byKey: Map<String, BibleProfile>.unmodifiable(byKey),
    );
  }

  const BibleProfileRegistry._({
    required this.profiles,
    required this.aliases,
    required Map<String, BibleProfile> byKey,
  }) : _byKey = byKey;

  /// Shared registry containing the package's built-in exact-edition profiles.
  static BibleProfileRegistry get standard => _builtInBibleProfileRegistry;

  /// Registered profiles in declaration order.
  final List<BibleProfile> profiles;

  /// Alias-to-canonical-ID mappings.
  final Map<String, String> aliases;

  final Map<String, BibleProfile> _byKey;

  /// Finds a profile by ID or alias, returning `null` when it is unknown.
  BibleProfile? lookup(String idOrAlias) =>
      _byKey[idOrAlias.trim().toLowerCase()];

  /// Alias for [lookup].
  BibleProfile? tryResolve(String idOrAlias) => lookup(idOrAlias);

  /// Finds a profile by ID or alias, throwing when it is unknown.
  BibleProfile require(String idOrAlias) {
    final profile = lookup(idOrAlias);
    if (profile == null) {
      throw ArgumentError.value(
        idOrAlias,
        'idOrAlias',
        'unknown Bible profile',
      );
    }
    return profile;
  }

  /// Alias for [require].
  BibleProfile resolve(String idOrAlias) => require(idOrAlias);

  /// Whether an ID or alias is registered.
  bool contains(String idOrAlias) => lookup(idOrAlias) != null;
}

final List<BibleProfile> _builtInBibleProfiles =
    List<BibleProfile>.unmodifiable([
  BibleProfile.protestantKingJames,
]);

final BibleProfileRegistry _builtInBibleProfileRegistry = BibleProfileRegistry(
  profiles: _builtInBibleProfiles,
  aliases: const {
    'kjv': 'protestant-kjv',
  },
);

bool _sameBookOrder(CanonProfile left, CanonProfile right) {
  if (left.books.length != right.books.length) return false;
  for (var index = 0; index < left.books.length; index++) {
    if (left.books[index] != right.books[index]) return false;
  }
  return true;
}

void _validateProfileKey(String value, String parameterName) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      parameterName,
      'must be a lowercase, hyphen-separated identifier',
    );
  }
}

void _validateDisplayName(String value) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(
      value,
      'displayName',
      'must be non-empty and have no surrounding whitespace',
    );
  }
}

void _checkSerializedComponent(
  Map<String, Object?> json, {
  required String key,
  required String expected,
}) {
  final value = json[key];
  if (value == null) return;
  if (value is! String) {
    throw FormatException('Bible profile "$key" must be a string');
  }
  if (value != expected) {
    throw FormatException(
      'Bible profile "$key" is "$value" but registry expects "$expected"',
    );
  }
}
