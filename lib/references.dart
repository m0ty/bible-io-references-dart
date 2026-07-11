import 'bible_book_enum.dart';
import 'bible_language_enum.dart';
import 'bible_profile.dart';
import 'canon_profile.dart';
import 'languages.dart';
import 'reference_input_normalizer.dart';
import 'reference_limits.dart';
import 'versification_profile.dart';

export 'reference_limits.dart';

part 'src/reference_parser.dart';
part 'src/passage_parser.dart';

/// A typed classification for reference parsing failures.
enum ReferenceParseErrorCode {
  emptyReference('empty_reference'),
  patternMismatch('pattern_mismatch'),
  unknownBook('unknown_book'),
  invalidNumericToken('invalid_numeric_token'),
  nonPositiveNumericToken('non_positive_numeric_token'),
  numericTokenOutOfRange('numeric_token_out_of_range'),
  emptyBookToken('empty_book_token'),
  ambiguousBook('ambiguous_book'),
  unsupportedLanguage('unsupported_language'),
  bookNotInCanon('book_not_in_canon'),
  chapterOutOfRange('chapter_out_of_range'),
  verseOutOfRange('verse_out_of_range'),
  sameBookRangeNotAscending('same_book_range_not_ascending'),
  crossBookRangeNotAscending('cross_book_range_not_ascending'),
  missingNumericToken('missing_numeric_token'),
  unknown('unknown');

  const ReferenceParseErrorCode(this.wireName);

  /// Stable machine-readable name used by the legacy [ParseVerseRefError.code].
  final String wireName;

  /// Resolves a legacy string code to its typed equivalent.
  static ReferenceParseErrorCode fromWireName(String value) {
    for (final code in values) {
      if (code.wireName == value) return code;
    }
    return unknown;
  }
}

/// The result of a non-throwing parse operation.
sealed class ParseResult<T> {
  const ParseResult();

  bool get isSuccess;

  T? get valueOrNull;

  ParseVerseRefError? get errorOrNull;

  /// Metadata recorded while parsing, or `null` when parsing failed.
  ReferenceParseMetadata? get metadataOrNull;
}

/// A successful [ParseResult].
final class ParseSuccess<T> extends ParseResult<T> {
  const ParseSuccess(
    this.value, {
    this.metadata = ReferenceParseMetadata.empty,
  });

  final T value;

  /// Information about normalization, language detection, and book matching.
  final ReferenceParseMetadata metadata;

  @override
  bool get isSuccess => true;

  @override
  T get valueOrNull => value;

  @override
  ParseVerseRefError? get errorOrNull => null;

  @override
  ReferenceParseMetadata get metadataOrNull => metadata;
}

/// A failed [ParseResult].
final class ParseFailure<T> extends ParseResult<T> {
  const ParseFailure(this.error);

  final ParseVerseRefError error;

  @override
  bool get isSuccess => false;

  @override
  T? get valueOrNull => null;

  @override
  ParseVerseRefError get errorOrNull => error;

  @override
  ReferenceParseMetadata? get metadataOrNull => null;
}

/// Raised when a verse reference string cannot be parsed.
///
/// This exception provides machine-readable error codes and optional details
/// to help callers handle parsing failures appropriately.
///
/// Example:
/// ```dart
/// try {
///   final ref = VerseRef.parse("InvalidBook 3:16");
/// } on ParseVerseRefError catch (e) {
///   print("Error: ${e.code}"); // "unknown_book"
///   if (e.details != null) print("Details: ${e.details}");
/// }
/// ```
class ParseVerseRefError implements Exception {
  /// Machine-readable error code identifying the type of parsing failure.
  ///
  /// Common codes:
  /// - `"pattern_mismatch"`: Input doesn't match expected format
  /// - `"unknown_book"`: Book name/abbreviation not recognized
  /// - `"invalid_numeric_token"`: Chapter/verse is not a valid number
  /// - `"non_positive_numeric_token"`: Chapter/verse is zero or negative
  /// - `"numeric_token_out_of_range"`: Chapter/verse exceeds broad sanity limits
  /// - `"empty_reference"`: Input is empty or only whitespace
  /// - `"empty_book_token"`: Book token is empty after normalization
  /// - `"ambiguous_book"`: Several books match under a rejecting policy
  /// - `"unsupported_language"`: Language code not supported
  /// - `"book_not_in_canon"`: Book is outside the selected canon profile
  /// - `"chapter_out_of_range"`: Chapter is absent from the versification
  /// - `"verse_out_of_range"`: Verse is absent from the versification
  /// - `"same_book_range_not_ascending"`: Range end comes before start
  /// - `"missing_numeric_token"`: Required numeric component missing
  final String code;

  /// Optional human-readable details about the parsing failure.
  final String? details;

  /// Typed equivalent of the legacy string [code].
  ReferenceParseErrorCode get errorCode =>
      ReferenceParseErrorCode.fromWireName(code);

  ParseVerseRefError({
    required this.code,
    this.details,
  });

  ParseVerseRefError.typed({
    required ReferenceParseErrorCode code,
    this.details,
  }) : code = code.wireName;

  @override
  String toString() => details == null
      ? 'ParseVerseRefError($code)'
      : 'ParseVerseRefError($code): $details';
}

/// Base class for all Bible reference types.
///
/// This sealed class provides a unified interface for working with either
/// single verses or verse ranges. Use [Reference.parse] for flexible parsing
/// that automatically determines the appropriate subtype.
///
/// Example:
/// ```dart
/// final ref = Reference.parse("John 3:16");
/// if (ref is VerseRef) {
///   print("Single verse: ${ref.displayString}");
/// } else if (ref is VerseRangeRef) {
///   print("Range: ${ref.displayString}");
/// }
/// ```
sealed class Reference {
  const Reference();

  /// Parses a Bible reference string, automatically determining whether it's
  /// a single verse or range.
  ///
  /// This method classifies range syntax first, avoiding ambiguity between an
  /// ending book name and the leading book token of a single verse.
  ///
  /// Parameters:
  /// - [ref]: The Bible reference string to parse
  /// - [language]: Optional language for book name parsing. Defaults to auto-detection.
  ///
  /// Returns: A [VerseRef] or [VerseRangeRef] instance
  ///
  /// Throws: [ParseVerseRefError] if parsing fails
  ///
  /// Example:
  /// ```dart
  /// final verse = Reference.parse("John 3:16"); // VerseRef
  /// final range = Reference.parse("John 3:16-17"); // VerseRangeRef
  /// ```
  static Reference parse(String ref, {BibleLanguageEnum? language}) {
    return _standardReferenceParser.parse(ref, language: language);
  }

  /// Parses [ref], returning `null` instead of throwing for invalid input.
  static Reference? tryParse(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      parseResult(ref, language: language).valueOrNull;

  /// Parses [ref] into an explicit success or failure value.
  static ParseResult<Reference> parseResult(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      _standardReferenceParser.parseResult(ref, language: language);

  /// Restores a reference produced by [toJson].
  static Reference fromJson(
    Map<String, Object?> json, {
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    return switch (json['type']) {
      'verse' => VerseRef.fromJson(
          json,
          profile: profile,
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
      'range' => VerseRangeRef.fromJson(
          json,
          profile: profile,
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
      final type => throw FormatException('unknown reference type: $type'),
    };
  }

  /// Returns a human-readable string representation of this reference.
  String get displayString;

  /// Converts this reference to a stable JSON-compatible map.
  Map<String, Object?> toJson();
}

/// A reference to a single Bible verse.
///
/// This class represents a specific verse location with a book, chapter, and verse number.
/// Instances are immutable and thread-safe.
///
/// Example:
/// ```dart
/// final verse = VerseRef.parse("John 3:16");
/// print(verse.book.fullName); // "John"
/// print(verse.chapter); // 3
/// print(verse.verse); // 16
/// print(verse.displayString); // "John 3:16"
/// ```
class VerseRef extends Reference implements Comparable<VerseRef> {
  /// The Bible book containing this verse.
  final BibleBookEnum book;

  /// The chapter number (1-based).
  final int chapter;

  /// The verse number within the chapter (1-based).
  final int verse;

  const VerseRef({
    required this.book,
    required this.chapter,
    required this.verse,
  })  : assert(chapter > 0 && chapter <= maxReferenceChapterNumber),
        assert(verse > 0 && verse <= maxReferenceVerseNumber);

  /// Creates a reference while enforcing broad numeric sanity limits.
  ///
  /// Supplying [canonProfile] additionally checks membership. Supplying
  /// [versificationProfile] checks real chapter and verse bounds and implies
  /// that profile's canon.
  factory VerseRef.checked({
    required BibleBookEnum book,
    required int chapter,
    required int verse,
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    _validateReferenceNumber(
      chapter,
      component: 'chapter',
      maximum: maxReferenceChapterNumber,
    );
    _validateReferenceNumber(
      verse,
      component: 'verse',
      maximum: maxReferenceVerseNumber,
    );
    final validation = _resolveValidationProfiles(
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
    final effectiveCanon = validation.canonProfile;
    if (effectiveCanon != null) {
      _validateBookInCanon(book, effectiveCanon);
    }
    validation.versificationProfile?.validateCoordinate(
      book: book,
      chapter: chapter,
      verse: verse,
    );
    return VerseRef(book: book, chapter: chapter, verse: verse);
  }

  /// Parses a string into a single verse reference.
  ///
  /// Expected format: "Book Chapter:Verse" (e.g., "John 3:16")
  /// Also supports dot separator: "Book Chapter.Verse" (e.g., "John 3.16")
  ///
  /// Parameters:
  /// - [ref]: The verse reference string to parse
  /// - [language]: Optional language for book name parsing
  ///
  /// Returns: A parsed [VerseRef] instance
  ///
  /// Throws: [ParseVerseRefError] if parsing fails
  ///
  /// Example:
  /// ```dart
  /// final verse = VerseRef.parse("John 3:16");
  /// final spanishVerse = VerseRef.parse("Juan 3:16", language: BibleLanguageEnum.spanish);
  /// ```
  static VerseRef parse(String ref, {BibleLanguageEnum? language}) {
    return _standardReferenceParser.parseVerse(ref, language: language);
  }

  /// Parses [ref], returning `null` instead of throwing for invalid input.
  static VerseRef? tryParse(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      parseResult(ref, language: language).valueOrNull;

  /// Parses [ref] into an explicit success or failure value.
  static ParseResult<VerseRef> parseResult(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      _standardReferenceParser.parseVerseResult(ref, language: language);

  /// Restores a verse reference produced by [toJson].
  static VerseRef fromJson(
    Map<String, Object?> json, {
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final book = _bookFromJson(json['book']);
    final chapter = _intFromJson(json, 'chapter');
    final verse = _intFromJson(json, 'verse');
    return VerseRef.checked(
      book: book,
      chapter: chapter,
      verse: verse,
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
  }

  VerseRef copyWith({
    BibleBookEnum? book,
    int? chapter,
    int? verse,
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) =>
      VerseRef.checked(
        book: book ?? this.book,
        chapter: chapter ?? this.chapter,
        verse: verse ?? this.verse,
        profile: profile,
        canonProfile: canonProfile,
        versificationProfile: versificationProfile,
      );

  @override
  String get displayString => '${book.fullName} $chapter:$verse';

  @override
  Map<String, Object?> toJson() => {
        'type': 'verse',
        'book': book.abbreviation,
        'chapter': chapter,
        'verse': verse,
      };

  /// Compares using the legacy declaration order of [BibleBookEnum].
  ///
  /// For edition-aware ordering, use a [VersificationProfile] or the
  /// profile-aware operations exported by `reference_range_operations.dart`.
  @override
  int compareTo(VerseRef other) {
    final bookComparison = book.index.compareTo(other.book.index);
    if (bookComparison != 0) return bookComparison;
    final chapterComparison = chapter.compareTo(other.chapter);
    if (chapterComparison != 0) return chapterComparison;
    return verse.compareTo(other.verse);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseRef &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);

  @override
  String toString() => displayString;
}

/// A reference to a range of Bible verses.
///
/// This class represents a contiguous range of verses from a start verse to an end verse.
/// The range can span multiple chapters within the same book, or even cross book boundaries.
/// Instances are immutable and thread-safe.
///
/// Example:
/// ```dart
/// final range = VerseRangeRef.parse("John 3:16-17");
/// print(range.start.displayString); // "John 3:16"
/// print(range.end.displayString); // "John 3:17"
/// print(range.displayString); // "John 3:16-17"
/// ```
class VerseRangeRef extends Reference {
  /// The first verse in the range (inclusive).
  final VerseRef start;

  /// The last verse in the range (inclusive).
  final VerseRef end;

  const VerseRangeRef({
    required this.start,
    required this.end,
  });

  /// Creates an ascending range.
  ///
  /// When a canon or versification is supplied, ordering follows that profile
  /// rather than the legacy [BibleBookEnum] declaration order.
  factory VerseRangeRef.checked({
    required VerseRef start,
    required VerseRef end,
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final validation = _resolveValidationProfiles(
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
    final effectiveCanon = validation.canonProfile;
    if (effectiveCanon != null) {
      _validateBookInCanon(start.book, effectiveCanon);
      _validateBookInCanon(end.book, effectiveCanon);
    }
    final comparison = validation.versificationProfile != null
        ? _compareVersesInProfile(
            start,
            end,
            validation.versificationProfile!,
          )
        : effectiveCanon != null
            ? _compareVersesInCanon(start, end, effectiveCanon)
            : start.compareTo(end);
    if (comparison >= 0) {
      throw ArgumentError.value(
        end,
        'end',
        'must come after start',
      );
    }
    return VerseRangeRef(start: start, end: end);
  }

  /// Parses a string into a verse range reference.
  ///
  /// Supported formats:
  /// - Same chapter: "Book Chapter:VerseStart-VerseEnd" (e.g., "John 3:16-17")
  /// - Cross-chapter: "Book ChapterStart:VerseStart-ChapterEnd:VerseEnd" (e.g., "John 3:16-4:1")
  /// - Cross-book: "BookStart Chapter:Verse-BookEnd Chapter:Verse" (e.g., "John 3:16-Acts 1:2")
  /// - Dot separators: "Book Chapter.VerseStart-VerseEnd" (e.g., "John 3.16-17")
  /// - Various dash types: hyphens (-), en dashes (–), em dashes (—)
  ///
  /// Parameters:
  /// - [ref]: The verse range string to parse
  /// - [language]: Optional language for book name parsing
  ///
  /// Returns: A parsed [VerseRangeRef] instance
  ///
  /// Throws: [ParseVerseRefError] if parsing fails or range is invalid
  ///
  /// Example:
  /// ```dart
  /// final sameChapter = VerseRangeRef.parse("John 3:16-17");
  /// final crossChapter = VerseRangeRef.parse("John 3:16-4:1");
  /// final crossBook = VerseRangeRef.parse("John 3:16-Acts 1:2");
  /// ```
  static VerseRangeRef parse(String ref, {BibleLanguageEnum? language}) {
    return _standardReferenceParser.parseRange(ref, language: language);
  }

  /// Parses [ref], returning `null` instead of throwing for invalid input.
  static VerseRangeRef? tryParse(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      parseResult(ref, language: language).valueOrNull;

  /// Parses [ref] into an explicit success or failure value.
  static ParseResult<VerseRangeRef> parseResult(
    String ref, {
    BibleLanguageEnum? language,
  }) =>
      _standardReferenceParser.parseRangeResult(ref, language: language);

  /// Restores a range reference produced by [toJson].
  static VerseRangeRef fromJson(
    Map<String, Object?> json, {
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final start = VerseRef.fromJson(
      _mapFromJson(json, 'start'),
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
    final end = VerseRef.fromJson(
      _mapFromJson(json, 'end'),
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
    return VerseRangeRef.checked(
      start: start,
      end: end,
      profile: profile,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
  }

  VerseRangeRef copyWith({
    VerseRef? start,
    VerseRef? end,
    BibleProfile? profile,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) =>
      VerseRangeRef.checked(
        start: start ?? this.start,
        end: end ?? this.end,
        profile: profile,
        canonProfile: canonProfile,
        versificationProfile: versificationProfile,
      );

  @override
  String get displayString {
    if (start.book == end.book) {
      if (start.chapter == end.chapter) {
        return '${start.book.fullName} ${start.chapter}:${start.verse}-${end.verse}';
      }
      return '${start.book.fullName} ${start.chapter}:${start.verse}-${end.chapter}:${end.verse}';
    }
    return '${start.book.fullName} ${start.chapter}:${start.verse}-${end.book.fullName} ${end.chapter}:${end.verse}';
  }

  @override
  Map<String, Object?> toJson() => {
        'type': 'range',
        'start': start.toJson(),
        'end': end.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseRangeRef && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => displayString;
}

/// Regex patterns for parsing.
final _verseRefPattern = RegExp(r'^\s*(.+?)\s*(\d+)\s*[:.]\s*(\d+)\s*$');
final _verseRangeRefPattern = RegExp(
  r'^\s*(.+?)\s+(\d+)\s*[:.]\s*(\d+)\s*[-\u2013\u2014\u2015]\s*(?:(.+?)\s+)?(?:(\d+)\s*[:.]\s*)?(\d+)\s*$',
);
final _flexibleVerseRangeRefPattern = RegExp(
  r'^\s*(.+?)\s*(\d+)\s*[:.]\s*(\d+)\s*[-\u2013\u2014\u2015]\s*(.+?)\s*$',
);
final _sameChapterRangeEndPattern = RegExp(r'^(\d+)$');
final _crossChapterRangeEndPattern = RegExp(r'^(\d+)\s*[:.]\s*(\d+)$');
final _crossBookRangeEndPattern = RegExp(r'^(.+?)\s*(\d+)\s*[:.]\s*(\d+)$');

/// Book term lookup helper.
class _BookTermLookup {
  static const autoLanguagePrecedence = [
    'ar',
    'zh',
    'fr',
    'de',
    'he',
    'hi',
    'id',
    'ko',
    'pt',
    'ru',
    'es',
    'tl',
  ];

  late final Map<String, BibleBookEnum> _english;
  late final Map<String, BibleBookEnum> _allLanguages;
  late final Map<String, Set<BibleBookEnum>> _autoCollisions;
  late final Map<String, Map<String, BibleBookEnum>> _byLanguage;

  _BookTermLookup() {
    _english = _buildEnglishLookup();
    _allLanguages = Map.from(_english);
    _autoCollisions = {};

    _registerTermsByLanguage(_allLanguages, bookNamesByLanguage,
        preferExisting: true, collisions: _autoCollisions);
    _registerTermsByLanguage(_allLanguages, bookAbbreviationsByLanguage,
        preferExisting: true, collisions: _autoCollisions);

    _byLanguage = {};
    final languageCodes = autoLanguagePrecedence.where((code) =>
        bookNamesByLanguage.containsKey(code) ||
        bookAbbreviationsByLanguage.containsKey(code));
    final unorderedCodes = (bookNamesByLanguage.keys.toSet()
          ..addAll(bookAbbreviationsByLanguage.keys))
        .where((code) => !languageCodes.contains(code));

    for (final code in [...languageCodes, ...unorderedCodes]) {
      final table = <String, BibleBookEnum>{};
      final names = bookNamesByLanguage[code];
      if (names != null) {
        _registerTerms(table, names);
      }
      final abbreviations = bookAbbreviationsByLanguage[code];
      if (abbreviations != null) {
        _registerTerms(table, abbreviations);
      }
      _byLanguage[code] = table;
    }
    _byLanguage[BibleLanguageEnum.english.code] = Map.from(_english);
  }

  Map<String, Set<BibleBookEnum>> get autoCollisions => {
        for (final entry in _autoCollisions.entries)
          entry.key: Set.from(entry.value),
      };

  BibleLanguageEnum normalizeLanguage(BibleLanguageEnum? language) {
    return language ?? BibleLanguageEnum.auto;
  }

  BibleBookEnum parseBookName(String bookText, BibleLanguageEnum language) {
    final normalized =
        bookText.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) {
      throw ParseVerseRefError(
          code: 'empty_book_token',
          details: 'book token is empty after normalization');
    }

    final compact = normalized.replaceAll('.', '').replaceAll(' ', '');
    Map<String, BibleBookEnum>? lookup;

    if (language == BibleLanguageEnum.auto) {
      final englishMatch = _lookupTerm(_english, normalized);
      if (englishMatch != null) return englishMatch;
      lookup = _allLanguages;
    } else {
      lookup = _byLanguage[language.code];
    }

    if (lookup == null) {
      throw ParseVerseRefError(
          code: 'unsupported_language',
          details: 'unsupported language code: ${language.code}');
    }

    var matched = _lookupTerm(lookup, normalized);
    if (matched != null) return matched;

    if (language == BibleLanguageEnum.auto) {
      try {
        return BibleBookEnum.fromStr(compact);
      } on ParseBibleBookError {
        throw ParseVerseRefError(
            code: 'unknown_book',
            details: 'book token "$bookText" did not match known books');
      }
    }

    throw ParseVerseRefError(
        code: 'unknown_book',
        details:
            'book token "$bookText" is unknown for language ${language.code}');
  }

  static Map<String, BibleBookEnum> _buildEnglishLookup() {
    final lookup = <String, BibleBookEnum>{};
    for (final book in BibleBookEnum.values) {
      lookup[book.fullName.toLowerCase()] = book;
      lookup[book.asStr().toLowerCase()] = book;
    }
    return lookup;
  }

  static void _registerTerms(
      Map<String, BibleBookEnum> table, Map<BibleBookEnum, List<String>> source,
      {bool preferExisting = false,
      Map<String, Set<BibleBookEnum>>? collisions}) {
    for (final entry in source.entries) {
      final book = entry.key;
      for (final term in entry.value) {
        final normalized = term.toLowerCase();
        final existing = table[normalized];
        if (existing != null && existing != book && collisions != null) {
          collisions.putIfAbsent(normalized, () => {}).add(existing);
          collisions[normalized]!.add(book);
        }
        if (existing == null || !preferExisting) {
          table[normalized] = book;
        }
      }
    }
  }

  static void _registerTermsByLanguage(Map<String, BibleBookEnum> table,
      Map<String, Map<BibleBookEnum, List<String>>> source,
      {bool preferExisting = false,
      Map<String, Set<BibleBookEnum>>? collisions}) {
    final orderedLanguageCodes =
        autoLanguagePrecedence.where((code) => source.containsKey(code));
    final unorderedLanguageCodes =
        source.keys.where((code) => !orderedLanguageCodes.contains(code));
    for (final languageCode in [
      ...orderedLanguageCodes,
      ...unorderedLanguageCodes
    ]) {
      final booksForLanguage = source[languageCode]!;
      _registerTerms(table, booksForLanguage,
          preferExisting: preferExisting, collisions: collisions);
    }
  }

  static BibleBookEnum? _lookupTerm(
      Map<String, BibleBookEnum> lookup, String normalized) {
    var direct = lookup[normalized];
    if (direct != null) return direct;

    final withoutPeriods = normalized.replaceAll('.', '');
    final noPeriodMatch = lookup[withoutPeriods];
    if (noPeriodMatch != null) return noPeriodMatch;

    return lookup[withoutPeriods.replaceAll(' ', '')];
  }
}

/// Shared book lookup instance.
final _bookLookup = _BookTermLookup();

/// Auto language precedence.
final autoLanguagePrecedence = _BookTermLookup.autoLanguagePrecedence;

/// Auto language collisions.
final autoLanguageCollisions = _bookLookup.autoCollisions;

/// Parse a string into a VerseRef.
VerseRef verseRefFromStr(String ref, {BibleLanguageEnum? language}) {
  _ensureReferenceIsNotEmpty(ref);
  final normalizedLanguage = _bookLookup.normalizeLanguage(language);

  final match = _verseRefPattern.firstMatch(ref);
  if (match == null) {
    throw ParseVerseRefError(
        code: 'pattern_mismatch',
        details: 'reference "$ref" does not match expected format');
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
  final book = _bookLookup.parseBookName(match.group(1)!, normalizedLanguage);

  return VerseRef.checked(book: book, chapter: chapter, verse: verse);
}

/// Parse a string into a VerseRangeRef.
VerseRangeRef verseRangeRefFromStr(String ref, {BibleLanguageEnum? language}) {
  _ensureReferenceIsNotEmpty(ref);
  final normalizedLanguage = _bookLookup.normalizeLanguage(language);

  final match = _verseRangeRefPattern.firstMatch(ref);
  if (match == null) {
    throw ParseVerseRefError(
        code: 'pattern_mismatch',
        details: 'reference "$ref" does not match expected format');
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
  final endVerse = _parseReferenceNumber(
    match.group(6)!,
    component: 'end verse',
    maximum: maxReferenceVerseNumber,
  );

  final endChapterMatch = match.group(5);
  final endChapter = endChapterMatch != null
      ? _parseReferenceNumber(
          endChapterMatch,
          component: 'end chapter',
          maximum: maxReferenceChapterNumber,
        )
      : startChapter;

  final startBook =
      _bookLookup.parseBookName(match.group(1)!, normalizedLanguage);
  final endBookMatch = match.group(4);
  final endBook = endBookMatch != null
      ? _bookLookup.parseBookName(endBookMatch, normalizedLanguage)
      : startBook;

  if (endBook == startBook &&
      (endChapter < startChapter ||
          (endChapter == startChapter && endVerse <= startVerse))) {
    throw ParseVerseRefError(
        code: 'same_book_range_not_ascending',
        details:
            'end reference must come after start reference for same-book ranges');
  }

  final start =
      VerseRef(book: startBook, chapter: startChapter, verse: startVerse);
  final end = VerseRef(book: endBook, chapter: endChapter, verse: endVerse);

  if (start.compareTo(end) >= 0) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.crossBookRangeNotAscending,
      details: 'end reference must come after start reference',
    );
  }

  return VerseRangeRef.checked(start: start, end: end);
}

void _ensureReferenceIsNotEmpty(String ref) {
  if (ref.trim().isEmpty) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.emptyReference,
      details: 'reference must not be empty',
    );
  }
}

/// Parse and broadly validate a chapter or verse number.
int _parseReferenceNumber(
  String value, {
  required String component,
  required int maximum,
}) {
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.invalidNumericToken,
      details: '$component token "$value" is not an integer',
    );
  }
  if (parsed <= 0) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.nonPositiveNumericToken,
      details: '$component token "$value" must be greater than zero',
    );
  }
  if (parsed > maximum) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.numericTokenOutOfRange,
      details: '$component token "$value" exceeds the sanity limit $maximum',
    );
  }
  return parsed;
}

void _validateReferenceNumber(
  int value, {
  required String component,
  required int maximum,
}) {
  if (value < 1 || value > maximum) {
    throw RangeError.range(value, 1, maximum, component);
  }
}

final class _ValidationProfiles {
  const _ValidationProfiles({
    required this.profile,
    required this.canonProfile,
    required this.versificationProfile,
  });

  final BibleProfile? profile;
  final CanonProfile? canonProfile;
  final VersificationProfile? versificationProfile;
}

_ValidationProfiles _resolveValidationProfiles({
  BibleProfile? profile,
  CanonProfile? canonProfile,
  VersificationProfile? versificationProfile,
}) {
  if (profile != null &&
      (canonProfile != null || versificationProfile != null)) {
    throw ArgumentError.value(
      profile,
      'profile',
      'cannot be combined with canonProfile or versificationProfile',
    );
  }
  final resolvedVersification = profile?.versification ?? versificationProfile;
  final resolvedCanon =
      profile?.canon ?? canonProfile ?? resolvedVersification?.canon;
  if (resolvedCanon != null &&
      resolvedVersification != null &&
      !_sameCanonBooks(resolvedCanon, resolvedVersification.canon)) {
    throw ArgumentError.value(
      resolvedCanon,
      'canonProfile',
      'must use the same books and order as versificationProfile',
    );
  }
  return _ValidationProfiles(
    profile: profile,
    canonProfile: resolvedCanon,
    versificationProfile: resolvedVersification,
  );
}

bool _sameCanonBooks(CanonProfile left, CanonProfile right) {
  if (left.books.length != right.books.length) return false;
  for (var index = 0; index < left.books.length; index++) {
    if (left.books[index] != right.books[index]) return false;
  }
  return true;
}

void _validateBookInCanon(BibleBookEnum book, CanonProfile canon) {
  if (canon.contains(book)) return;
  throw ReferenceValidationException(
    code: ReferenceValidationErrorCode.bookNotInCanon,
    profileId: canon.id,
    book: book,
    details: '${book.fullName} is not part of the ${canon.displayName} canon',
  );
}

int _compareVersesInCanon(
  VerseRef left,
  VerseRef right,
  CanonProfile canon,
) {
  final bookComparison = canon.compare(left.book, right.book);
  if (bookComparison != 0) return bookComparison;
  final chapterComparison = left.chapter.compareTo(right.chapter);
  if (chapterComparison != 0) return chapterComparison;
  return left.verse.compareTo(right.verse);
}

int _compareVersesInProfile(
  VerseRef left,
  VerseRef right,
  VersificationProfile profile,
) {
  final leftOrdinal = profile.ordinalOf(
    book: left.book,
    chapter: left.chapter,
    verse: left.verse,
  );
  final rightOrdinal = profile.ordinalOf(
    book: right.book,
    chapter: right.chapter,
    verse: right.verse,
  );
  return leftOrdinal.compareTo(rightOrdinal);
}

int _intFromJson(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('"$key" must be an integer');
  }
  return value;
}

Map<String, Object?> _mapFromJson(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('"$key" must be an object');
  }
  return Map<String, Object?>.from(value);
}

BibleBookEnum _bookFromJson(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('"book" must be a non-empty string');
  }
  final normalized = value.trim().toLowerCase();
  for (final book in BibleBookEnum.values) {
    if (book.abbreviation.toLowerCase() == normalized ||
        book.name.toLowerCase() == normalized ||
        book.fullName.toLowerCase() == normalized) {
      return book;
    }
  }
  throw FormatException('unknown Bible book: $value');
}

/// Parse a Bible reference string into either a VerseRef or VerseRangeRef.
///
/// @deprecated Use [Reference.parse] instead for a more ergonomic API.
@Deprecated('Use Reference.parse instead')
Reference parseReference(String ref, {BibleLanguageEnum? language}) {
  return Reference.parse(ref, language: language);
}
