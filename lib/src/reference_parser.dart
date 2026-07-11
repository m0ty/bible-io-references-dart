part of '../references.dart';

/// Controls how a [ReferenceParser] resolves aliases that match several books.
enum ReferenceAmbiguityPolicy {
  /// Select the first candidate according to custom-alias and language priority.
  preferLanguagePriority,

  /// Fail with [ReferenceParseErrorCode.ambiguousBook] when distinct books match.
  reject,
}

/// A single possible interpretation of a parsed book token.
final class ReferenceBookCandidate {
  const ReferenceBookCandidate({
    required this.book,
    required this.alias,
    required this.language,
    required this.isCustom,
  });

  /// The book represented by this candidate.
  final BibleBookEnum book;

  /// The registered alias that produced this candidate.
  final String alias;

  /// The alias language, or `null` for a language-neutral custom alias.
  final BibleLanguageEnum? language;

  /// Whether this candidate came from caller-provided aliases.
  final bool isCustom;

  Map<String, Object?> toJson() => {
        'book': book.abbreviation,
        'alias': alias,
        'language': language?.code,
        'custom': isCustom,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceBookCandidate &&
          book == other.book &&
          alias == other.alias &&
          language == other.language &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(book, alias, language, isCustom);
}

/// Match information for one explicit book token in the source text.
final class ReferenceBookTokenMatch {
  ReferenceBookTokenMatch({
    required this.input,
    required this.selected,
    Iterable<ReferenceBookCandidate> alternatives = const [],
  }) : alternatives = List.unmodifiable(alternatives);

  /// The syntax-normalized book token, trimmed but otherwise unchanged.
  final String input;

  /// The candidate chosen by the parser.
  final ReferenceBookCandidate selected;

  /// Other candidates that matched the same normalized token.
  final List<ReferenceBookCandidate> alternatives;

  /// The selected language, or `null` for a language-neutral custom alias.
  BibleLanguageEnum? get detectedLanguage => selected.language;

  /// Whether the token could have selected a different book.
  bool get isAmbiguous =>
      alternatives.any((candidate) => candidate.book != selected.book);

  Map<String, Object?> toJson() => {
        'input': input,
        'selected': selected.toJson(),
        'alternatives': [
          for (final candidate in alternatives) candidate.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceBookTokenMatch &&
          input == other.input &&
          selected == other.selected &&
          _referenceListsEqual(alternatives, other.alternatives);

  @override
  int get hashCode =>
      Object.hash(input, selected, Object.hashAll(alternatives));
}

/// Metadata captured while a reference is parsed successfully.
final class ReferenceParseMetadata {
  ReferenceParseMetadata({
    required this.normalizedInput,
    Iterable<ReferenceBookTokenMatch> bookMatches = const [],
    this.profileId,
    this.canonProfileId,
    this.versificationProfileId,
  }) : bookMatches = List.unmodifiable(bookMatches);

  const ReferenceParseMetadata._({
    required this.normalizedInput,
    required this.bookMatches,
    required this.profileId,
    required this.canonProfileId,
    required this.versificationProfileId,
  });

  /// Empty metadata used by manually-created [ParseSuccess] values.
  static const empty = ReferenceParseMetadata._(
    normalizedInput: '',
    bookMatches: <ReferenceBookTokenMatch>[],
    profileId: null,
    canonProfileId: null,
    versificationProfileId: null,
  );

  /// The Unicode-syntax-normalized, trimmed, whitespace-normalized source.
  final String normalizedInput;

  /// Matches for each explicit book token in source order.
  final List<ReferenceBookTokenMatch> bookMatches;

  /// Composite Bible-profile ID used for validation, when configured.
  final String? profileId;

  /// Canon-profile ID used for membership and ordering, when configured.
  final String? canonProfileId;

  /// Versification-profile ID used for coordinate validation, when configured.
  final String? versificationProfileId;

  /// Every distinct language selected for explicit book tokens.
  Set<BibleLanguageEnum> get detectedLanguages => Set.unmodifiable(
        bookMatches
            .map((match) => match.detectedLanguage)
            .whereType<BibleLanguageEnum>(),
      );

  /// The one detected language, or `null` for mixed/no-language matches.
  BibleLanguageEnum? get detectedLanguage {
    final languages = detectedLanguages;
    return languages.length == 1 ? languages.first : null;
  }

  /// All non-selected book candidates in source order.
  List<ReferenceBookCandidate> get alternateMatches => List.unmodifiable(
        bookMatches.expand((match) => match.alternatives),
      );

  /// Whether any explicit token matched more than one distinct book.
  bool get hasAmbiguity => bookMatches.any((match) => match.isAmbiguous);

  Map<String, Object?> toJson() => {
        'normalizedInput': normalizedInput,
        'detectedLanguage': detectedLanguage?.code,
        'detectedLanguages': [
          for (final language in detectedLanguages) language.code,
        ],
        'bookMatches': [for (final match in bookMatches) match.toJson()],
        if (profileId != null ||
            canonProfileId != null ||
            versificationProfileId != null)
          'validation': {
            if (profileId case final value?) 'profile': value,
            if (canonProfileId case final value?) 'canon': value,
            if (versificationProfileId case final value?)
              'versification': value,
          },
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceParseMetadata &&
          normalizedInput == other.normalizedInput &&
          profileId == other.profileId &&
          canonProfileId == other.canonProfileId &&
          versificationProfileId == other.versificationProfileId &&
          _referenceListsEqual(bookMatches, other.bookMatches);

  @override
  int get hashCode => Object.hash(
        normalizedInput,
        Object.hashAll(bookMatches),
        profileId,
        canonProfileId,
        versificationProfileId,
      );
}

/// A configurable, reusable Bible-reference parser.
///
/// Custom aliases are language-neutral and intentionally outrank bundled
/// aliases. [aliasesByLanguage] adds localized aliases that are considered
/// only in auto mode or when that language is explicitly selected.
final class ReferenceParser {
  factory ReferenceParser({
    Map<String, BibleBookEnum> aliases = const {},
    Map<BibleLanguageEnum, Map<String, BibleBookEnum>> aliasesByLanguage =
        const {},
    Iterable<BibleLanguageEnum> preferredLanguages = const [],
    ReferenceAmbiguityPolicy ambiguityPolicy =
        ReferenceAmbiguityPolicy.preferLanguagePriority,
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final aliasesCopy = Map<String, BibleBookEnum>.unmodifiable(aliases);
    final localizedCopy = <BibleLanguageEnum, Map<String, BibleBookEnum>>{};
    for (final entry in aliasesByLanguage.entries) {
      if (entry.key == BibleLanguageEnum.auto) {
        throw ArgumentError.value(
          entry.key,
          'aliasesByLanguage',
          'auto is not a concrete alias language',
        );
      }
      localizedCopy[entry.key] =
          Map<String, BibleBookEnum>.unmodifiable(entry.value);
    }

    final preferredCopy = <BibleLanguageEnum>[];
    for (final language in preferredLanguages) {
      if (language == BibleLanguageEnum.auto) {
        throw ArgumentError.value(
          language,
          'preferredLanguages',
          'auto is not a concrete preferred language',
        );
      }
      if (!preferredCopy.contains(language)) preferredCopy.add(language);
    }

    final validation = _resolveValidationProfiles(
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );

    return ReferenceParser._(
      aliases: aliasesCopy,
      aliasesByLanguage: Map.unmodifiable(localizedCopy),
      preferredLanguages: List.unmodifiable(preferredCopy),
      ambiguityPolicy: ambiguityPolicy,
      profile: validation.profile,
      canonProfile: validation.canonProfile,
      versificationProfile: validation.versificationProfile,
    );
  }

  ReferenceParser._({
    required this.aliases,
    required this.aliasesByLanguage,
    required this.preferredLanguages,
    required this.ambiguityPolicy,
    required this.profile,
    required this.canonProfile,
    required this.versificationProfile,
  })  : _languagePriority = _buildLanguagePriority(preferredLanguages),
        _bookIndex = _ParserBookIndex(
          aliases: aliases,
          aliasesByLanguage: aliasesByLanguage,
        );

  /// Shared parser used by static parsing APIs.
  static final ReferenceParser standard = ReferenceParser();

  /// Language-neutral aliases that override bundled aliases.
  final Map<String, BibleBookEnum> aliases;

  /// Caller-provided aliases scoped to a concrete language.
  final Map<BibleLanguageEnum, Map<String, BibleBookEnum>> aliasesByLanguage;

  /// Languages moved ahead of the default auto-detection order.
  final List<BibleLanguageEnum> preferredLanguages;

  /// The configured collision policy.
  final ReferenceAmbiguityPolicy ambiguityPolicy;

  /// Optional edition-specific composite profile used by this parser.
  final BibleProfile? profile;

  /// Optional canon membership and ordering enforced while parsing.
  ///
  /// A `null` value preserves the package's historically permissive behavior.
  final CanonProfile? canonProfile;

  /// Optional edition-specific chapter and verse limits.
  ///
  /// When supplied, its canon is used unless an equivalent [canonProfile] was
  /// provided explicitly.
  final VersificationProfile? versificationProfile;

  final List<BibleLanguageEnum> _languagePriority;
  final _ParserBookIndex _bookIndex;

  Reference parse(String ref, {BibleLanguageEnum? language}) =>
      _parseReference(ref, language: language).value;

  Reference? tryParse(String ref, {BibleLanguageEnum? language}) =>
      parseResult(ref, language: language).valueOrNull;

  ParseResult<Reference> parseResult(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      _capture(() => _parseReference(ref, language: language));

  VerseRef parseVerse(String ref, {BibleLanguageEnum? language}) =>
      _parseVerse(ref, language: language).value;

  VerseRef? tryParseVerse(String ref, {BibleLanguageEnum? language}) =>
      parseVerseResult(ref, language: language).valueOrNull;

  ParseResult<VerseRef> parseVerseResult(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      _capture(() => _parseVerse(ref, language: language));

  VerseRangeRef parseRange(String ref, {BibleLanguageEnum? language}) =>
      _parseRange(ref, language: language).value;

  VerseRangeRef? tryParseRange(String ref, {BibleLanguageEnum? language}) =>
      parseRangeResult(ref, language: language).valueOrNull;

  ParseResult<VerseRangeRef> parseRangeResult(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      _capture(() => _parseRange(ref, language: language));

  ParseResult<T> _capture<T>(_ParsedReference<T> Function() operation) {
    try {
      final parsed = operation();
      return ParseSuccess(parsed.value, metadata: parsed.metadata);
    } on ParseVerseRefError catch (error) {
      return ParseFailure(error);
    }
  }

  _ParsedReference<Reference> _parseReference(
    String ref, {
    BibleLanguageEnum? language,
  }) {
    final normalizedRef = ReferenceInputNormalizer.normalize(ref);
    _ensureReferenceIsNotEmpty(normalizedRef);
    if (_flexibleVerseRangeRefPattern.hasMatch(normalizedRef)) {
      final parsed = _parseRange(ref, language: language);
      return _ParsedReference(parsed.value, parsed.metadata);
    }
    final parsed = _parseVerse(ref, language: language);
    return _ParsedReference(parsed.value, parsed.metadata);
  }

  _ParsedReference<VerseRef> _parseVerse(
    String ref, {
    BibleLanguageEnum? language,
  }) {
    final normalizedRef = ReferenceInputNormalizer.normalize(ref);
    _ensureReferenceIsNotEmpty(normalizedRef);
    _validateLanguage(language);
    final match = _verseRefPattern.firstMatch(normalizedRef);
    if (match == null) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'reference "$ref" does not match expected format',
      );
    }

    final chapter = _parseReferenceNumber(
      match.group(2)!,
      component: 'chapter',
      maximum: maxReferenceChapterNumber,
    );
    final verse = _parseReferenceNumber(
      match.group(3)!,
      component: 'verse',
      maximum: maxReferenceVerseNumber,
    );
    final resolution = _resolveBook(match.group(1)!, language: language);
    final value = VerseRef.checked(
      book: resolution.match.selected.book,
      chapter: chapter,
      verse: verse,
    );
    _validateVerseProfile(value);
    return _ParsedReference(
      value,
      _metadata(normalizedRef, [resolution.match]),
    );
  }

  _ParsedReference<VerseRangeRef> _parseRange(
    String ref, {
    BibleLanguageEnum? language,
  }) {
    final normalizedRef = ReferenceInputNormalizer.normalize(ref);
    _ensureReferenceIsNotEmpty(normalizedRef);
    _validateLanguage(language);
    final match = _flexibleVerseRangeRefPattern.firstMatch(normalizedRef);
    if (match == null) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'reference "$ref" does not match expected range format',
      );
    }

    final startChapter = _parseReferenceNumber(
      match.group(2)!,
      component: 'start chapter',
      maximum: maxReferenceChapterNumber,
    );
    final startVerse = _parseReferenceNumber(
      match.group(3)!,
      component: 'start verse',
      maximum: maxReferenceVerseNumber,
    );
    final startResolution = _resolveBook(match.group(1)!, language: language);
    final matches = <ReferenceBookTokenMatch>[startResolution.match];
    final endExpression = match.group(4)!.trim();
    final sameChapterEnd =
        _sameChapterRangeEndPattern.firstMatch(endExpression);
    final crossChapterEnd =
        _crossChapterRangeEndPattern.firstMatch(endExpression);
    final crossBookEnd = _crossBookRangeEndPattern.firstMatch(endExpression);
    final BibleBookEnum endBook;
    final int endChapter;
    final String endVerseToken;
    if (sameChapterEnd != null) {
      endBook = startResolution.match.selected.book;
      endChapter = startChapter;
      endVerseToken = sameChapterEnd.group(1)!;
    } else if (crossChapterEnd != null) {
      endBook = startResolution.match.selected.book;
      endChapter = _parseReferenceNumber(
        crossChapterEnd.group(1)!,
        component: 'end chapter',
        maximum: maxReferenceChapterNumber,
      );
      endVerseToken = crossChapterEnd.group(2)!;
    } else if (crossBookEnd != null) {
      final endResolution =
          _resolveBook(crossBookEnd.group(1)!, language: language);
      endBook = endResolution.match.selected.book;
      matches.add(endResolution.match);
      endChapter = _parseReferenceNumber(
        crossBookEnd.group(2)!,
        component: 'end chapter',
        maximum: maxReferenceChapterNumber,
      );
      endVerseToken = crossBookEnd.group(3)!;
    } else {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'range end "$endExpression" does not match expected format',
      );
    }
    final endVerse = _parseReferenceNumber(
      endVerseToken,
      component: 'end verse',
      maximum: maxReferenceVerseNumber,
    );

    final start = VerseRef.checked(
      book: startResolution.match.selected.book,
      chapter: startChapter,
      verse: startVerse,
    );
    final end = VerseRef.checked(
      book: endBook,
      chapter: endChapter,
      verse: endVerse,
    );
    _validateVerseProfile(start);
    _validateVerseProfile(end);
    if (_compareVerseProfiles(start, end) >= 0) {
      final code = start.book == end.book
          ? ReferenceParseErrorCode.sameBookRangeNotAscending
          : ReferenceParseErrorCode.crossBookRangeNotAscending;
      throw ParseVerseRefError.typed(
        code: code,
        details: 'end reference must come after start reference',
      );
    }

    return _ParsedReference(
      VerseRangeRef(start: start, end: end),
      _metadata(normalizedRef, matches),
    );
  }

  void _validateBookProfile(BibleBookEnum book) {
    final canon = canonProfile;
    if (canon != null && !canon.contains(book)) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.bookNotInCanon,
        details: '${book.fullName} is not part of the ${canon.displayName} '
            'canon profile',
      );
    }
  }

  void _validateChapterProfile(BibleBookEnum book, int chapter) {
    _validateBookProfile(book);
    final profile = versificationProfile;
    if (profile == null) return;
    try {
      profile.verseCount(book, chapter);
    } on ReferenceValidationException catch (error) {
      throw _profileParseError(error);
    }
  }

  void _validateVerseProfile(VerseRef verse) {
    _validateBookProfile(verse.book);
    final profile = versificationProfile;
    if (profile == null) return;
    try {
      profile.validateCoordinate(
        book: verse.book,
        chapter: verse.chapter,
        verse: verse.verse,
      );
    } on ReferenceValidationException catch (error) {
      throw _profileParseError(error);
    }
  }

  int _compareVerseProfiles(VerseRef left, VerseRef right) {
    final versification = versificationProfile;
    if (versification != null) {
      return _compareVersesInProfile(left, right, versification);
    }
    final canon = canonProfile;
    if (canon == null) return left.compareTo(right);
    final bookComparison = canon.compare(left.book, right.book);
    if (bookComparison != 0) return bookComparison;
    final chapterComparison = left.chapter.compareTo(right.chapter);
    if (chapterComparison != 0) return chapterComparison;
    return left.verse.compareTo(right.verse);
  }

  ParseVerseRefError _profileParseError(
    ReferenceValidationException error,
  ) {
    final code = switch (error.code) {
      ReferenceValidationErrorCode.bookNotInCanon =>
        ReferenceParseErrorCode.bookNotInCanon,
      ReferenceValidationErrorCode.chapterOutOfRange =>
        ReferenceParseErrorCode.chapterOutOfRange,
      ReferenceValidationErrorCode.verseOutOfRange =>
        ReferenceParseErrorCode.verseOutOfRange,
      ReferenceValidationErrorCode.ordinalOutOfRange =>
        ReferenceParseErrorCode.unknown,
    };
    return ParseVerseRefError.typed(code: code, details: error.details);
  }

  void _validateLanguage(BibleLanguageEnum? language) {
    if (language == null || language == BibleLanguageEnum.auto) return;
    if (!language.isParsingSupported &&
        !aliasesByLanguage.containsKey(language)) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.unsupportedLanguage,
        details: 'unsupported language code: ${language.code}',
      );
    }
  }

  _BookResolution _resolveBook(
    String input, {
    BibleLanguageEnum? language,
  }) {
    final candidates = _bookIndex.lookup(input);
    final explicitLanguage =
        language != null && language != BibleLanguageEnum.auto
            ? language
            : null;
    final filtered = candidates.where((candidate) {
      if (explicitLanguage == null) return true;
      return candidate.language == explicitLanguage ||
          (candidate.isCustom && candidate.language == null);
    }).toList();

    if (filtered.isEmpty) {
      final languageDetails = explicitLanguage == null
          ? 'known books'
          : 'language ${explicitLanguage.code}';
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.unknownBook,
        details: 'book token "$input" did not match $languageDetails',
      );
    }

    filtered.sort(_compareCandidates);
    final customCandidates =
        filtered.where((candidate) => candidate.isCustom).toList();
    final ambiguityPool =
        customCandidates.isEmpty ? filtered : customCandidates;
    final distinctBooks = {
      for (final candidate in ambiguityPool) candidate.book,
    };
    if (ambiguityPolicy == ReferenceAmbiguityPolicy.reject &&
        distinctBooks.length > 1) {
      final descriptions = ambiguityPool
          .map(
            (candidate) =>
                '${candidate.book.fullName} (${candidate.language?.code ?? 'custom'})',
          )
          .toSet()
          .join(', ');
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.ambiguousBook,
        details: 'book token "$input" is ambiguous: $descriptions',
      );
    }

    final selected = filtered.first;
    final alternatives = filtered.where((candidate) => candidate != selected);
    return _BookResolution(
      ReferenceBookTokenMatch(
        input: input.trim(),
        selected: selected,
        alternatives: alternatives,
      ),
    );
  }

  int _compareCandidates(
    ReferenceBookCandidate left,
    ReferenceBookCandidate right,
  ) {
    final customComparison =
        (left.isCustom ? 0 : 1).compareTo(right.isCustom ? 0 : 1);
    if (customComparison != 0) return customComparison;
    final leftRank = _languageRank(left.language);
    final rightRank = _languageRank(right.language);
    final languageComparison = leftRank.compareTo(rightRank);
    if (languageComparison != 0) return languageComparison;
    return left.book.index.compareTo(right.book.index);
  }

  int _languageRank(BibleLanguageEnum? language) {
    if (language == null) return -1;
    final index = _languagePriority.indexOf(language);
    return index < 0 ? _languagePriority.length : index;
  }

  ReferenceParseMetadata _metadata(
    String input,
    Iterable<ReferenceBookTokenMatch> matches,
  ) =>
      ReferenceParseMetadata(
        normalizedInput: input.trim().replaceAll(RegExp(r'\s+'), ' '),
        bookMatches: matches,
        profileId: profile?.id,
        canonProfileId: canonProfile?.id,
        versificationProfileId: versificationProfile?.id,
      );
}

final ReferenceParser _standardReferenceParser = ReferenceParser.standard;

final class _ParsedReference<T> {
  const _ParsedReference(this.value, this.metadata);

  final T value;
  final ReferenceParseMetadata metadata;
}

final class _BookResolution {
  const _BookResolution(this.match);

  final ReferenceBookTokenMatch match;
}

bool _referenceListsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _ParserBookIndex {
  _ParserBookIndex({
    required Map<String, BibleBookEnum> aliases,
    required Map<BibleLanguageEnum, Map<String, BibleBookEnum>>
        aliasesByLanguage,
  }) {
    for (final book in BibleBookEnum.values) {
      _register(
        book.fullName,
        book,
        language: BibleLanguageEnum.english,
      );
      _register(
        book.abbreviation,
        book,
        language: BibleLanguageEnum.english,
      );
    }

    for (final language in BibleLanguageEnum.values) {
      if (language == BibleLanguageEnum.auto ||
          language == BibleLanguageEnum.english) {
        continue;
      }
      final names = bookNamesByLanguage[language.code];
      final abbreviations = bookAbbreviationsByLanguage[language.code];
      if (names != null) {
        _registerTable(names, language: language);
      }
      if (abbreviations != null) {
        _registerTable(abbreviations, language: language);
      }
    }

    for (final entry in aliases.entries) {
      _register(entry.key, entry.value, isCustom: true);
    }
    for (final languageEntry in aliasesByLanguage.entries) {
      for (final aliasEntry in languageEntry.value.entries) {
        _register(
          aliasEntry.key,
          aliasEntry.value,
          language: languageEntry.key,
          isCustom: true,
        );
      }
    }
  }

  final Map<String, List<ReferenceBookCandidate>> _candidatesByKey = {};

  void _registerTable(
    Map<BibleBookEnum, List<String>> table, {
    required BibleLanguageEnum language,
  }) {
    for (final entry in table.entries) {
      for (final alias in entry.value) {
        _register(alias, entry.key, language: language);
      }
    }
  }

  void _register(
    String alias,
    BibleBookEnum book, {
    BibleLanguageEnum? language,
    bool isCustom = false,
  }) {
    final normalized = _normalizeParserAlias(alias);
    if (normalized.isEmpty) {
      if (isCustom) {
        throw ArgumentError.value(alias, 'aliases', 'alias must not be empty');
      }
      return;
    }
    final candidate = ReferenceBookCandidate(
      book: book,
      alias: alias,
      language: language,
      isCustom: isCustom,
    );
    for (final key in _parserAliasKeys(normalized)) {
      final candidates = _candidatesByKey.putIfAbsent(key, () => []);
      final duplicate = candidates.any(
        (existing) =>
            existing.book == candidate.book &&
            existing.language == candidate.language &&
            existing.isCustom == candidate.isCustom,
      );
      if (!duplicate) candidates.add(candidate);
    }
  }

  List<ReferenceBookCandidate> lookup(String input) {
    final normalized = _normalizeParserAlias(input);
    if (normalized.isEmpty) return const [];
    for (final key in _parserAliasKeys(normalized)) {
      final candidates = _candidatesByKey[key];
      if (candidates != null && candidates.isNotEmpty) {
        return List.of(candidates);
      }
    }
    return const [];
  }
}

List<BibleLanguageEnum> _buildLanguagePriority(
  Iterable<BibleLanguageEnum> preferred,
) {
  final result = <BibleLanguageEnum>[];
  void add(BibleLanguageEnum language) {
    if (language != BibleLanguageEnum.auto && !result.contains(language)) {
      result.add(language);
    }
  }

  for (final language in preferred) {
    add(language);
  }
  add(BibleLanguageEnum.english);
  for (final code in _BookTermLookup.autoLanguagePrecedence) {
    for (final language in BibleLanguageEnum.values) {
      if (language.code == code) {
        add(language);
        break;
      }
    }
  }
  for (final language in supportedParsingLanguages) {
    add(language);
  }
  return List.unmodifiable(result);
}

String _normalizeParserAlias(String value) =>
    ReferenceInputNormalizer.normalize(
      value,
    ).trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

Set<String> _parserAliasKeys(String normalized) {
  final withoutPeriods = normalized.replaceAll('.', '');
  return {
    normalized,
    withoutPeriods,
    withoutPeriods.replaceAll(' ', ''),
  };
}
