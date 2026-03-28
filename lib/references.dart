import 'bible_book_enum.dart';
import 'bible_language_enum.dart';
import 'languages.dart';

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
  /// - `"empty_book_token"`: Book token is empty after normalization
  /// - `"unsupported_language"`: Language code not supported
  /// - `"same_book_range_not_ascending"`: Range end comes before start
  /// - `"missing_numeric_token"`: Required numeric component missing
  final String code;

  /// Optional human-readable details about the parsing failure.
  final String? details;

  ParseVerseRefError({
    required this.code,
    this.details,
  });

  @override
  String toString() => 'invalid verse reference';
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
  /// This method first attempts to parse as a [VerseRef], and if that fails
  /// with a "pattern_mismatch" error, it tries parsing as a [VerseRangeRef].
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
    try {
      return VerseRef.parse(ref, language: language);
    } on ParseVerseRefError catch (e) {
      if (e.code != 'pattern_mismatch') rethrow;
    }
    return VerseRangeRef.parse(ref, language: language);
  }

  /// Returns a human-readable string representation of this reference.
  String get displayString;
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
class VerseRef extends Reference {
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
  });

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
    return verseRefFromStr(ref, language: language);
  }

  @override
  String get displayString => '${book.fullName} $chapter:$verse';

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
    return verseRangeRefFromStr(ref, language: language);
  }

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
  String toString() => displayString;
}

/// Regex patterns for parsing.
final _verseRefPattern = RegExp(r'^\s*(.+?)\s+(\d+)\s*[:.]\s*(\d+)\s*$');
final _verseRangeRefPattern = RegExp(r'^\s*(.+?)\s+(\d+)\s*[:.]\s*(\d+)\s*[-\u2013\u2014]\s*(?:(.+?)\s+)?(?:(\d+)\s*[:.]\s*)?(\d+)\s*$');

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

    _registerTermsByLanguage(_allLanguages, bookNamesByLanguage, preferExisting: true, collisions: _autoCollisions);
    _registerTermsByLanguage(_allLanguages, bookAbbreviationsByLanguage, preferExisting: true, collisions: _autoCollisions);

    _byLanguage = {};
    final languageCodes = autoLanguagePrecedence.where((code) => bookNamesByLanguage.containsKey(code) || bookAbbreviationsByLanguage.containsKey(code));
    final unorderedCodes = (bookNamesByLanguage.keys.toSet()..addAll(bookAbbreviationsByLanguage.keys)).where((code) => !languageCodes.contains(code));

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
    for (final entry in _autoCollisions.entries) entry.key: Set.from(entry.value),
  };

  BibleLanguageEnum normalizeLanguage(BibleLanguageEnum? language) {
    return language ?? BibleLanguageEnum.auto;
  }

  BibleBookEnum parseBookName(String bookText, BibleLanguageEnum language) {
    final normalized = bookText.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) {
      throw ParseVerseRefError(code: 'empty_book_token', details: 'book token is empty after normalization');
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
      throw ParseVerseRefError(code: 'unsupported_language', details: 'unsupported language code: ${language.code}');
    }

    var matched = _lookupTerm(lookup, normalized);
    if (matched != null) return matched;

    if (language == BibleLanguageEnum.auto) {
      try {
        return BibleBookEnum.fromStr(compact);
      } on ParseBibleBookError {
        throw ParseVerseRefError(code: 'unknown_book', details: 'book token "$bookText" did not match known books');
      }
    }

    throw ParseVerseRefError(code: 'unknown_book', details: 'book token "$bookText" is unknown for language ${language.code}');
  }

  static Map<String, BibleBookEnum> _buildEnglishLookup() {
    final lookup = <String, BibleBookEnum>{};
    for (final book in BibleBookEnum.values) {
      lookup[book.fullName.toLowerCase()] = book;
      lookup[book.asStr().toLowerCase()] = book;
    }
    return lookup;
  }

  static void _registerTerms(Map<String, BibleBookEnum> table, Map<BibleBookEnum, List<String>> source, {bool preferExisting = false, Map<String, Set<BibleBookEnum>>? collisions}) {
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

  static void _registerTermsByLanguage(Map<String, BibleBookEnum> table, Map<String, Map<BibleBookEnum, List<String>>> source, {bool preferExisting = false, Map<String, Set<BibleBookEnum>>? collisions}) {
    final orderedLanguageCodes = autoLanguagePrecedence.where((code) => source.containsKey(code));
    final unorderedLanguageCodes = source.keys.where((code) => !orderedLanguageCodes.contains(code));
    for (final languageCode in [...orderedLanguageCodes, ...unorderedLanguageCodes]) {
      final booksForLanguage = source[languageCode]!;
      _registerTerms(table, booksForLanguage, preferExisting: preferExisting, collisions: collisions);
    }
  }

  static BibleBookEnum? _lookupTerm(Map<String, BibleBookEnum> lookup, String normalized) {
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
  final normalizedLanguage = _bookLookup.normalizeLanguage(language);

  final match = _verseRefPattern.firstMatch(ref);
  if (match == null) {
    throw ParseVerseRefError(code: 'pattern_mismatch', details: 'reference "$ref" does not match expected format');
  }

  final chapter = _parsePositiveInt(match.group(2)!);
  final verse = _parsePositiveInt(match.group(3)!);
  final book = _bookLookup.parseBookName(match.group(1)!, normalizedLanguage);

  return VerseRef(book: book, chapter: chapter, verse: verse);
}

/// Parse a string into a VerseRangeRef.
VerseRangeRef verseRangeRefFromStr(String ref, {BibleLanguageEnum? language}) {
  final normalizedLanguage = _bookLookup.normalizeLanguage(language);

  final match = _verseRangeRefPattern.firstMatch(ref);
  if (match == null) {
    throw ParseVerseRefError(code: 'pattern_mismatch', details: 'reference "$ref" does not match expected format');
  }

  final startChapter = _parsePositiveInt(match.group(2)!);
  final startVerse = _parsePositiveInt(match.group(3)!);
  final endVerse = _parsePositiveInt(match.group(6)!);

  final endChapterMatch = match.group(5);
  final endChapter = endChapterMatch != null ? _parsePositiveInt(endChapterMatch) : startChapter;

  final startBook = _bookLookup.parseBookName(match.group(1)!, normalizedLanguage);
  final endBookMatch = match.group(4);
  final endBook = endBookMatch != null ? _bookLookup.parseBookName(endBookMatch, normalizedLanguage) : startBook;

  if (endBook == startBook && (endChapter < startChapter || (endChapter == startChapter && endVerse <= startVerse))) {
    throw ParseVerseRefError(code: 'same_book_range_not_ascending', details: 'end reference must come after start reference for same-book ranges');
  }

  final start = VerseRef(book: startBook, chapter: startChapter, verse: startVerse);
  final end = VerseRef(book: endBook, chapter: endChapter, verse: endVerse);

  return VerseRangeRef(start: start, end: end);
}

/// Parse a string as a positive integer.
int _parsePositiveInt(String value) {
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw ParseVerseRefError(code: 'invalid_numeric_token', details: 'numeric token "$value" is not an integer');
  }
  if (parsed <= 0) {
    throw ParseVerseRefError(code: 'non_positive_numeric_token', details: 'numeric token "$value" must be greater than zero');
  }
  return parsed;
}

/// Parse a Bible reference string into either a VerseRef or VerseRangeRef.
/// 
/// @deprecated Use [Reference.parse] instead for a more ergonomic API.
@Deprecated('Use Reference.parse instead')
Reference parseReference(String ref, {BibleLanguageEnum? language}) {
  return Reference.parse(ref, language: language);
}