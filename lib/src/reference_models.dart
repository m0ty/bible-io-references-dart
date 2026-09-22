part of '../references.dart';

/// Broad sanity limits used by reference construction and parsing.
///
/// These deliberately exceed chapter and verse numbers used by known Bible
/// traditions. They reject pathological numeric input without claiming that a
/// particular verse exists in a specific edition.
const int maxReferenceChapterNumber = 999;
const int maxReferenceVerseNumber = 999;

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
  static Reference fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'verse' => VerseRef.fromJson(json),
      'range' => VerseRangeRef.fromJson(json),
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

  /// An optional verse subdivision, represented by one lowercase letter a-z.
  ///
  /// For `John 1:5a`, [verse] is `5` and [subdivision] is `a`.
  final String? subdivision;

  /// The verse number with its subdivision, such as `5` or `5a`.
  String get verseLabel => '$verse${subdivision ?? ''}';

  const VerseRef({
    required this.book,
    required this.chapter,
    required this.verse,
    this.subdivision,
  })  : assert(chapter > 0 && chapter <= maxReferenceChapterNumber),
        assert(verse > 0 && verse <= maxReferenceVerseNumber),
        assert(
          subdivision == null ||
              subdivision == 'a' ||
              subdivision == 'b' ||
              subdivision == 'c' ||
              subdivision == 'd' ||
              subdivision == 'e' ||
              subdivision == 'f' ||
              subdivision == 'g' ||
              subdivision == 'h' ||
              subdivision == 'i' ||
              subdivision == 'j' ||
              subdivision == 'k' ||
              subdivision == 'l' ||
              subdivision == 'm' ||
              subdivision == 'n' ||
              subdivision == 'o' ||
              subdivision == 'p' ||
              subdivision == 'q' ||
              subdivision == 'r' ||
              subdivision == 's' ||
              subdivision == 't' ||
              subdivision == 'u' ||
              subdivision == 'v' ||
              subdivision == 'w' ||
              subdivision == 'x' ||
              subdivision == 'y' ||
              subdivision == 'z',
        );

  /// Creates a reference while enforcing broad numeric sanity limits.
  factory VerseRef.checked({
    required BibleBookEnum book,
    required int chapter,
    required int verse,
    String? subdivision,
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
    if (subdivision != null &&
        (subdivision.length != 1 ||
            !_verseSubdivisionPattern.hasMatch(subdivision))) {
      throw ArgumentError.value(
        subdivision,
        'subdivision',
        'must be one lowercase letter a-z',
      );
    }
    return VerseRef(
      book: book,
      chapter: chapter,
      verse: verse,
      subdivision: subdivision,
    );
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
  static VerseRef fromJson(Map<String, Object?> json) {
    final book = _bookFromJson(json['book']);
    final chapter = _intFromJson(json, 'chapter');
    final verse = _intFromJson(json, 'verse');
    final subdivision = json['subdivision'];
    if (subdivision != null && subdivision is! String) {
      throw const FormatException('"subdivision" must be a string or null');
    }
    return VerseRef.checked(
      book: book,
      chapter: chapter,
      verse: verse,
      subdivision: subdivision as String?,
    );
  }

  /// Copies this verse, retaining its subdivision unless [clearSubdivision]
  /// is true or a replacement [subdivision] is supplied.
  VerseRef copyWith({
    BibleBookEnum? book,
    int? chapter,
    int? verse,
    String? subdivision,
    bool clearSubdivision = false,
  }) =>
      VerseRef.checked(
        book: book ?? this.book,
        chapter: chapter ?? this.chapter,
        verse: verse ?? this.verse,
        subdivision: clearSubdivision ? null : subdivision ?? this.subdivision,
      );

  @override
  String get displayString => '${book.fullName} $chapter:$verseLabel';

  @override
  Map<String, Object?> toJson() => {
        'type': 'verse',
        'book': book.abbreviation,
        'chapter': chapter,
        'verse': verse,
        if (subdivision != null) 'subdivision': subdivision,
      };

  /// Orders by book, chapter, verse, then subdivision (`5 < 5a < 5b < 6`).
  /// This is an ordering of identifiers, not a test of text containment.
  @override
  int compareTo(VerseRef other) {
    final bookComparison = book.index.compareTo(other.book.index);
    if (bookComparison != 0) return bookComparison;
    final chapterComparison = chapter.compareTo(other.chapter);
    if (chapterComparison != 0) return chapterComparison;
    final verseComparison = verse.compareTo(other.verse);
    if (verseComparison != 0) return verseComparison;
    return (subdivision ?? '').compareTo(other.subdivision ?? '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseRef &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse &&
          subdivision == other.subdivision;

  @override
  int get hashCode => Object.hash(book, chapter, verse, subdivision);

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
  factory VerseRangeRef.checked({
    required VerseRef start,
    required VerseRef end,
  }) {
    if (start.compareTo(end) >= 0) {
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
  static VerseRangeRef fromJson(Map<String, Object?> json) {
    final start = VerseRef.fromJson(_mapFromJson(json, 'start'));
    final end = VerseRef.fromJson(_mapFromJson(json, 'end'));
    return VerseRangeRef.checked(start: start, end: end);
  }

  VerseRangeRef copyWith({
    VerseRef? start,
    VerseRef? end,
  }) =>
      VerseRangeRef.checked(
        start: start ?? this.start,
        end: end ?? this.end,
      );

  @override
  String get displayString {
    if (start.book == end.book) {
      if (start.chapter == end.chapter) {
        return '${start.book.fullName} ${start.chapter}:${start.verseLabel}-${end.verseLabel}';
      }
      return '${start.book.fullName} ${start.chapter}:${start.verseLabel}-${end.chapter}:${end.verseLabel}';
    }
    return '${start.book.fullName} ${start.chapter}:${start.verseLabel}-${end.book.fullName} ${end.chapter}:${end.verseLabel}';
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
