import 'bible_book_enum.dart';
import 'canon_profile.dart';
import 'reference_limits.dart';

/// Machine-readable reasons why a coordinate is invalid for a versification.
enum ReferenceValidationErrorCode {
  /// The book is not part of the versification's canon.
  bookNotInCanon('book_not_in_canon'),

  /// The chapter is outside the selected book's chapter range.
  chapterOutOfRange('chapter_out_of_range'),

  /// The verse is outside the selected chapter's verse range.
  verseOutOfRange('verse_out_of_range'),

  /// A zero-based verse ordinal is outside the versification.
  ordinalOutOfRange('ordinal_out_of_range');

  const ReferenceValidationErrorCode(this.wireName);

  /// Stable snake-case representation suitable for JSON and CLI output.
  final String wireName;
}

/// Thrown when a book, chapter, verse, or ordinal is outside a versification.
final class ReferenceValidationException implements Exception {
  /// Creates a typed coordinate-validation exception.
  const ReferenceValidationException({
    required this.code,
    required this.profileId,
    this.book,
    this.chapter,
    this.verse,
    this.ordinal,
    this.details,
  });

  /// The machine-readable failure classification.
  final ReferenceValidationErrorCode code;

  /// The profile against which validation failed.
  final String profileId;

  /// The invalid coordinate's book, when applicable.
  final BibleBookEnum? book;

  /// The invalid coordinate's chapter, when applicable.
  final int? chapter;

  /// The invalid coordinate's verse, when applicable.
  final int? verse;

  /// The invalid zero-based ordinal, when applicable.
  final int? ordinal;

  /// Optional human-readable diagnostic details.
  final String? details;

  @override
  String toString() {
    final message = details == null ? '' : ': $details';
    return 'ReferenceValidationException(${code.wireName}, '
        'profile: $profileId)$message';
  }
}

/// An immutable book/chapter/verse coordinate value.
///
/// Coordinates are validated when they are supplied to a
/// [VersificationProfile] operation.
final class VersificationCoordinate {
  /// Creates a coordinate value.
  const VersificationCoordinate({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  /// The coordinate's book.
  final BibleBookEnum book;

  /// The one-based chapter number.
  final int chapter;

  /// The one-based verse number.
  final int verse;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersificationCoordinate &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);

  @override
  String toString() => '${book.fullName} $chapter:$verse';
}

/// Immutable chapter and verse bounds for a particular biblical edition.
///
/// Canon membership and ordering are supplied by [canon]. Each map value
/// contains the maximum verse number for every chapter of its book, in order.
/// Custom profiles must provide exactly one non-empty, positive list for every
/// book in the canon and no entries for books outside it. Chapter and verse
/// counts must also fit the shared reference-model limits.
final class VersificationProfile {
  /// Creates a validated custom versification profile.
  factory VersificationProfile({
    required String id,
    required String displayName,
    required CanonProfile canon,
    required Map<BibleBookEnum, Iterable<int>> verseCountsByBook,
  }) {
    _validateText(id, 'id');
    _validateText(displayName, 'displayName');

    final extraBooks = verseCountsByBook.keys
        .where((book) => !canon.contains(book))
        .toList(growable: false);
    if (extraBooks.isNotEmpty) {
      throw ArgumentError.value(
        extraBooks,
        'verseCountsByBook',
        'contains books outside the ${canon.displayName} canon',
      );
    }

    final copiedCounts = <BibleBookEnum, List<int>>{};
    final bookStarts = <int>[0];
    final chapterStarts = <BibleBookEnum, List<int>>{};
    var totalVerses = 0;

    for (final book in canon.books) {
      final sourceCounts = verseCountsByBook[book];
      if (sourceCounts == null) {
        throw ArgumentError.value(
          book,
          'verseCountsByBook',
          'is missing a canon book',
        );
      }

      final counts = List<int>.of(sourceCounts);
      if (counts.isEmpty) {
        throw ArgumentError.value(
          counts,
          'verseCountsByBook',
          '${book.fullName} must contain at least one chapter',
        );
      }
      if (counts.length > maxReferenceChapterNumber) {
        throw ArgumentError.value(
          counts.length,
          'verseCountsByBook',
          '${book.fullName} exceeds the representable limit of '
              '$maxReferenceChapterNumber chapters',
        );
      }

      final startsForBook = <int>[0];
      var versesInBook = 0;
      for (var chapterIndex = 0; chapterIndex < counts.length; chapterIndex++) {
        final count = counts[chapterIndex];
        if (count <= 0) {
          throw ArgumentError.value(
            count,
            'verseCountsByBook',
            '${book.fullName} ${chapterIndex + 1} must have a positive '
                'verse count',
          );
        }
        if (count > maxReferenceVerseNumber) {
          throw ArgumentError.value(
            count,
            'verseCountsByBook',
            '${book.fullName} ${chapterIndex + 1} exceeds the representable '
                'limit of $maxReferenceVerseNumber verses',
          );
        }
        versesInBook += count;
        startsForBook.add(versesInBook);
      }

      copiedCounts[book] = List<int>.unmodifiable(counts);
      chapterStarts[book] = List<int>.unmodifiable(startsForBook);
      totalVerses += versesInBook;
      bookStarts.add(totalVerses);
    }

    return VersificationProfile._(
      id: id,
      displayName: displayName,
      canon: canon,
      verseCountsByBook: Map<BibleBookEnum, List<int>>.unmodifiable(
        copiedCounts,
      ),
      bookStartOrdinals: List<int>.unmodifiable(bookStarts),
      chapterStartOrdinalsByBook:
          Map<BibleBookEnum, List<int>>.unmodifiable(chapterStarts),
      totalVerseCount: totalVerses,
    );
  }

  const VersificationProfile._({
    required this.id,
    required this.displayName,
    required this.canon,
    required this.verseCountsByBook,
    required List<int> bookStartOrdinals,
    required Map<BibleBookEnum, List<int>> chapterStartOrdinalsByBook,
    required this.totalVerseCount,
  })  : _bookStartOrdinals = bookStartOrdinals,
        _chapterStartOrdinalsByBook = chapterStartOrdinalsByBook;

  /// The conventional 66-book King James Version versification.
  ///
  /// Counts are generated from SIL's English Paratext versification table,
  /// with KJV-specific Revelation 12 and 3 John corrections documented in
  /// `THIRD_PARTY_NOTICES.md`.
  static final VersificationProfile kingJames = VersificationProfile(
    id: 'kjv',
    displayName: 'King James Version',
    canon: CanonProfile.protestant,
    verseCountsByBook: _kingJamesVerseCounts,
  );

  /// Backward-friendly alias for the built-in Protestant KJV profile.
  static VersificationProfile get protestant => kingJames;

  /// Stable machine-readable identifier for this profile.
  final String id;

  /// Human-readable profile name.
  final String displayName;

  /// Canon membership and canonical book ordering used by this profile.
  final CanonProfile canon;

  /// Maximum verse number for every chapter, keyed by canon book.
  ///
  /// Both the map and its lists are unmodifiable defensive copies.
  final Map<BibleBookEnum, List<int>> verseCountsByBook;

  final List<int> _bookStartOrdinals;
  final Map<BibleBookEnum, List<int>> _chapterStartOrdinalsByBook;

  /// Total number of addressable verses in this profile.
  final int totalVerseCount;

  /// Returns the number of chapters in [book].
  ///
  /// Throws [ReferenceValidationException] when [book] is outside [canon].
  int chapterCount(BibleBookEnum book) => _requireBook(book).length;

  /// Returns the maximum verse number in [chapter] of [book].
  ///
  /// Throws [ReferenceValidationException] when the book or chapter is invalid.
  int verseCount(BibleBookEnum book, int chapter) {
    final chapters = _requireBook(book);
    if (chapter < 1 || chapter > chapters.length) {
      throw ReferenceValidationException(
        code: ReferenceValidationErrorCode.chapterOutOfRange,
        profileId: id,
        book: book,
        chapter: chapter,
        details: '${book.fullName} has chapters 1-${chapters.length} in '
            '$displayName',
      );
    }
    return chapters[chapter - 1];
  }

  /// Validates a complete coordinate, throwing a typed exception on failure.
  void validateCoordinate({
    required BibleBookEnum book,
    required int chapter,
    required int verse,
  }) {
    final lastVerse = verseCount(book, chapter);
    if (verse < 1 || verse > lastVerse) {
      throw ReferenceValidationException(
        code: ReferenceValidationErrorCode.verseOutOfRange,
        profileId: id,
        book: book,
        chapter: chapter,
        verse: verse,
        details: '${book.fullName} $chapter has verses 1-$lastVerse in '
            '$displayName',
      );
    }
  }

  /// Returns the zero-based canonical verse ordinal of a coordinate.
  int ordinalOf({
    required BibleBookEnum book,
    required int chapter,
    required int verse,
  }) {
    validateCoordinate(book: book, chapter: chapter, verse: verse);
    final bookIndex = canon.requireIndexOf(book);
    final chapterStarts = _chapterStartOrdinalsByBook[book]!;
    return _bookStartOrdinals[bookIndex] +
        chapterStarts[chapter - 1] +
        verse -
        1;
  }

  /// Resolves a zero-based canonical verse [ordinal] to its coordinate.
  VersificationCoordinate coordinateAt(int ordinal) {
    if (ordinal < 0 || ordinal >= totalVerseCount) {
      throw ReferenceValidationException(
        code: ReferenceValidationErrorCode.ordinalOutOfRange,
        profileId: id,
        ordinal: ordinal,
        details: 'ordinal must be between 0 and ${totalVerseCount - 1}',
      );
    }

    final bookIndex = _containingIndex(_bookStartOrdinals, ordinal);
    final book = canon.books[bookIndex];
    final ordinalInBook = ordinal - _bookStartOrdinals[bookIndex];
    final chapterStarts = _chapterStartOrdinalsByBook[book]!;
    final chapterIndex = _containingIndex(chapterStarts, ordinalInBook);

    return VersificationCoordinate(
      book: book,
      chapter: chapterIndex + 1,
      verse: ordinalInBook - chapterStarts[chapterIndex] + 1,
    );
  }

  /// Compares two coordinates using this profile's canonical ordering.
  int compareCoordinates(
    VersificationCoordinate left,
    VersificationCoordinate right,
  ) =>
      ordinalOf(
        book: left.book,
        chapter: left.chapter,
        verse: left.verse,
      ).compareTo(
        ordinalOf(
          book: right.book,
          chapter: right.chapter,
          verse: right.verse,
        ),
      );

  List<int> _requireBook(BibleBookEnum book) {
    final chapters = verseCountsByBook[book];
    if (chapters == null) {
      throw ReferenceValidationException(
        code: ReferenceValidationErrorCode.bookNotInCanon,
        profileId: id,
        book: book,
        details: '${book.fullName} is not part of the ${canon.displayName} '
            'canon',
      );
    }
    return chapters;
  }

  static int _containingIndex(List<int> boundaries, int value) {
    var low = 0;
    var high = boundaries.length - 2;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      if (value < boundaries[middle]) {
        high = middle - 1;
      } else if (value >= boundaries[middle + 1]) {
        low = middle + 1;
      } else {
        return middle;
      }
    }
    throw StateError('invalid versification prefix table');
  }

  static void _validateText(String value, String parameterName) {
    if (value.isEmpty || value.trim().isEmpty) {
      throw ArgumentError.value(value, parameterName, 'must not be empty');
    }
    if (value != value.trim()) {
      throw ArgumentError.value(
        value,
        parameterName,
        'must not have surrounding whitespace',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VersificationProfile ||
        id != other.id ||
        displayName != other.displayName ||
        canon != other.canon ||
        totalVerseCount != other.totalVerseCount) {
      return false;
    }
    for (final book in canon.books) {
      final left = verseCountsByBook[book]!;
      final right = other.verseCountsByBook[book];
      if (right == null || left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (left[index] != right[index]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        canon,
        Object.hashAll(
          canon.books.map(
            (book) =>
                Object.hash(book, Object.hashAll(verseCountsByBook[book]!)),
          ),
        ),
      );

  @override
  String toString() =>
      'VersificationProfile(id: $id, displayName: $displayName, '
      'verses: $totalVerseCount)';
}

// Generated from SIL libpalaso eng.vrs.txt at commit
// ba68a4a7a7509766a1aa66d7664cff3ddf95c195. Revelation 12 and 3 John
// use the KJV maxima from the pinned MIT OpenBibleInfo table. See
// THIRD_PARTY_NOTICES.md for sources, transformations, and license notices.
const Map<BibleBookEnum, List<int>> _kingJamesVerseCounts = {
  BibleBookEnum.genesis: [
    31,
    25,
    24,
    26,
    32,
    22,
    24,
    22,
    29,
    32,
    32,
    20,
    18,
    24,
    21,
    16,
    27,
    33,
    38,
    18,
    34,
    24,
    20,
    67,
    34,
    35,
    46,
    22,
    35,
    43,
    55,
    32,
    20,
    31,
    29,
    43,
    36,
    30,
    23,
    23,
    57,
    38,
    34,
    34,
    28,
    34,
    31,
    22,
    33,
    26,
  ],
  BibleBookEnum.exodus: [
    22,
    25,
    22,
    31,
    23,
    30,
    25,
    32,
    35,
    29,
    10,
    51,
    22,
    31,
    27,
    36,
    16,
    27,
    25,
    26,
    36,
    31,
    33,
    18,
    40,
    37,
    21,
    43,
    46,
    38,
    18,
    35,
    23,
    35,
    35,
    38,
    29,
    31,
    43,
    38,
  ],
  BibleBookEnum.leviticus: [
    17,
    16,
    17,
    35,
    19,
    30,
    38,
    36,
    24,
    20,
    47,
    8,
    59,
    57,
    33,
    34,
    16,
    30,
    37,
    27,
    24,
    33,
    44,
    23,
    55,
    46,
    34,
  ],
  BibleBookEnum.numbers: [
    54,
    34,
    51,
    49,
    31,
    27,
    89,
    26,
    23,
    36,
    35,
    16,
    33,
    45,
    41,
    50,
    13,
    32,
    22,
    29,
    35,
    41,
    30,
    25,
    18,
    65,
    23,
    31,
    40,
    16,
    54,
    42,
    56,
    29,
    34,
    13,
  ],
  BibleBookEnum.deuteronomy: [
    46,
    37,
    29,
    49,
    33,
    25,
    26,
    20,
    29,
    22,
    32,
    32,
    18,
    29,
    23,
    22,
    20,
    22,
    21,
    20,
    23,
    30,
    25,
    22,
    19,
    19,
    26,
    68,
    29,
    20,
    30,
    52,
    29,
    12,
  ],
  BibleBookEnum.joshua: [
    18,
    24,
    17,
    24,
    15,
    27,
    26,
    35,
    27,
    43,
    23,
    24,
    33,
    15,
    63,
    10,
    18,
    28,
    51,
    9,
    45,
    34,
    16,
    33,
  ],
  BibleBookEnum.judges: [
    36,
    23,
    31,
    24,
    31,
    40,
    25,
    35,
    57,
    18,
    40,
    15,
    25,
    20,
    20,
    31,
    13,
    31,
    30,
    48,
    25,
  ],
  BibleBookEnum.ruth: [22, 23, 18, 22],
  BibleBookEnum.firstSamuel: [
    28,
    36,
    21,
    22,
    12,
    21,
    17,
    22,
    27,
    27,
    15,
    25,
    23,
    52,
    35,
    23,
    58,
    30,
    24,
    42,
    15,
    23,
    29,
    22,
    44,
    25,
    12,
    25,
    11,
    31,
    13,
  ],
  BibleBookEnum.secondSamuel: [
    27,
    32,
    39,
    12,
    25,
    23,
    29,
    18,
    13,
    19,
    27,
    31,
    39,
    33,
    37,
    23,
    29,
    33,
    43,
    26,
    22,
    51,
    39,
    25,
  ],
  BibleBookEnum.firstKings: [
    53,
    46,
    28,
    34,
    18,
    38,
    51,
    66,
    28,
    29,
    43,
    33,
    34,
    31,
    34,
    34,
    24,
    46,
    21,
    43,
    29,
    53,
  ],
  BibleBookEnum.secondKings: [
    18,
    25,
    27,
    44,
    27,
    33,
    20,
    29,
    37,
    36,
    21,
    21,
    25,
    29,
    38,
    20,
    41,
    37,
    37,
    21,
    26,
    20,
    37,
    20,
    30,
  ],
  BibleBookEnum.firstChronicles: [
    54,
    55,
    24,
    43,
    26,
    81,
    40,
    40,
    44,
    14,
    47,
    40,
    14,
    17,
    29,
    43,
    27,
    17,
    19,
    8,
    30,
    19,
    32,
    31,
    31,
    32,
    34,
    21,
    30,
  ],
  BibleBookEnum.secondChronicles: [
    17,
    18,
    17,
    22,
    14,
    42,
    22,
    18,
    31,
    19,
    23,
    16,
    22,
    15,
    19,
    14,
    19,
    34,
    11,
    37,
    20,
    12,
    21,
    27,
    28,
    23,
    9,
    27,
    36,
    27,
    21,
    33,
    25,
    33,
    27,
    23,
  ],
  BibleBookEnum.ezra: [11, 70, 13, 24, 17, 22, 28, 36, 15, 44],
  BibleBookEnum.nehemiah: [11, 20, 32, 23, 19, 19, 73, 18, 38, 39, 36, 47, 31],
  BibleBookEnum.esther: [22, 23, 15, 17, 14, 14, 10, 17, 32, 3],
  BibleBookEnum.job: [
    22,
    13,
    26,
    21,
    27,
    30,
    21,
    22,
    35,
    22,
    20,
    25,
    28,
    22,
    35,
    22,
    16,
    21,
    29,
    29,
    34,
    30,
    17,
    25,
    6,
    14,
    23,
    28,
    25,
    31,
    40,
    22,
    33,
    37,
    16,
    33,
    24,
    41,
    30,
    24,
    34,
    17,
  ],
  BibleBookEnum.psalms: [
    6,
    12,
    8,
    8,
    12,
    10,
    17,
    9,
    20,
    18,
    7,
    8,
    6,
    7,
    5,
    11,
    15,
    50,
    14,
    9,
    13,
    31,
    6,
    10,
    22,
    12,
    14,
    9,
    11,
    12,
    24,
    11,
    22,
    22,
    28,
    12,
    40,
    22,
    13,
    17,
    13,
    11,
    5,
    26,
    17,
    11,
    9,
    14,
    20,
    23,
    19,
    9,
    6,
    7,
    23,
    13,
    11,
    11,
    17,
    12,
    8,
    12,
    11,
    10,
    13,
    20,
    7,
    35,
    36,
    5,
    24,
    20,
    28,
    23,
    10,
    12,
    20,
    72,
    13,
    19,
    16,
    8,
    18,
    12,
    13,
    17,
    7,
    18,
    52,
    17,
    16,
    15,
    5,
    23,
    11,
    13,
    12,
    9,
    9,
    5,
    8,
    28,
    22,
    35,
    45,
    48,
    43,
    13,
    31,
    7,
    10,
    10,
    9,
    8,
    18,
    19,
    2,
    29,
    176,
    7,
    8,
    9,
    4,
    8,
    5,
    6,
    5,
    6,
    8,
    8,
    3,
    18,
    3,
    3,
    21,
    26,
    9,
    8,
    24,
    13,
    10,
    7,
    12,
    15,
    21,
    10,
    20,
    14,
    9,
    6,
  ],
  BibleBookEnum.proverbs: [
    33,
    22,
    35,
    27,
    23,
    35,
    27,
    36,
    18,
    32,
    31,
    28,
    25,
    35,
    33,
    33,
    28,
    24,
    29,
    30,
    31,
    29,
    35,
    34,
    28,
    28,
    27,
    28,
    27,
    33,
    31,
  ],
  BibleBookEnum.ecclesiastes: [18, 26, 22, 16, 20, 12, 29, 17, 18, 20, 10, 14],
  BibleBookEnum.songOfSolomon: [17, 17, 11, 16, 16, 13, 13, 14],
  BibleBookEnum.isaiah: [
    31,
    22,
    26,
    6,
    30,
    13,
    25,
    22,
    21,
    34,
    16,
    6,
    22,
    32,
    9,
    14,
    14,
    7,
    25,
    6,
    17,
    25,
    18,
    23,
    12,
    21,
    13,
    29,
    24,
    33,
    9,
    20,
    24,
    17,
    10,
    22,
    38,
    22,
    8,
    31,
    29,
    25,
    28,
    28,
    25,
    13,
    15,
    22,
    26,
    11,
    23,
    15,
    12,
    17,
    13,
    12,
    21,
    14,
    21,
    22,
    11,
    12,
    19,
    12,
    25,
    24,
  ],
  BibleBookEnum.jeremiah: [
    19,
    37,
    25,
    31,
    31,
    30,
    34,
    22,
    26,
    25,
    23,
    17,
    27,
    22,
    21,
    21,
    27,
    23,
    15,
    18,
    14,
    30,
    40,
    10,
    38,
    24,
    22,
    17,
    32,
    24,
    40,
    44,
    26,
    22,
    19,
    32,
    21,
    28,
    18,
    16,
    18,
    22,
    13,
    30,
    5,
    28,
    7,
    47,
    39,
    46,
    64,
    34,
  ],
  BibleBookEnum.lamentations: [22, 22, 66, 22, 22],
  BibleBookEnum.ezekiel: [
    28,
    10,
    27,
    17,
    17,
    14,
    27,
    18,
    11,
    22,
    25,
    28,
    23,
    23,
    8,
    63,
    24,
    32,
    14,
    49,
    32,
    31,
    49,
    27,
    17,
    21,
    36,
    26,
    21,
    26,
    18,
    32,
    33,
    31,
    15,
    38,
    28,
    23,
    29,
    49,
    26,
    20,
    27,
    31,
    25,
    24,
    23,
    35,
  ],
  BibleBookEnum.daniel: [21, 49, 30, 37, 31, 28, 28, 27, 27, 21, 45, 13],
  BibleBookEnum.hosea: [11, 23, 5, 19, 15, 11, 16, 14, 17, 15, 12, 14, 16, 9],
  BibleBookEnum.joel: [20, 32, 21],
  BibleBookEnum.amos: [15, 16, 15, 13, 27, 14, 17, 14, 15],
  BibleBookEnum.obadiah: [21],
  BibleBookEnum.jonah: [17, 10, 10, 11],
  BibleBookEnum.micah: [16, 13, 12, 13, 15, 16, 20],
  BibleBookEnum.nahum: [15, 13, 19],
  BibleBookEnum.habakkuk: [17, 20, 19],
  BibleBookEnum.zephaniah: [18, 15, 20],
  BibleBookEnum.haggai: [15, 23],
  BibleBookEnum.zechariah: [
    21,
    13,
    10,
    14,
    11,
    15,
    14,
    23,
    17,
    12,
    17,
    14,
    9,
    21
  ],
  BibleBookEnum.malachi: [14, 17, 18, 6],
  BibleBookEnum.matthew: [
    25,
    23,
    17,
    25,
    48,
    34,
    29,
    34,
    38,
    42,
    30,
    50,
    58,
    36,
    39,
    28,
    27,
    35,
    30,
    34,
    46,
    46,
    39,
    51,
    46,
    75,
    66,
    20,
  ],
  BibleBookEnum.mark: [
    45,
    28,
    35,
    41,
    43,
    56,
    37,
    38,
    50,
    52,
    33,
    44,
    37,
    72,
    47,
    20
  ],
  BibleBookEnum.luke: [
    80,
    52,
    38,
    44,
    39,
    49,
    50,
    56,
    62,
    42,
    54,
    59,
    35,
    35,
    32,
    31,
    37,
    43,
    48,
    47,
    38,
    71,
    56,
    53,
  ],
  BibleBookEnum.john: [
    51,
    25,
    36,
    54,
    47,
    71,
    53,
    59,
    41,
    42,
    57,
    50,
    38,
    31,
    27,
    33,
    26,
    40,
    42,
    31,
    25,
  ],
  BibleBookEnum.acts: [
    26,
    47,
    26,
    37,
    42,
    15,
    60,
    40,
    43,
    48,
    30,
    25,
    52,
    28,
    41,
    40,
    34,
    28,
    41,
    38,
    40,
    30,
    35,
    27,
    27,
    32,
    44,
    31,
  ],
  BibleBookEnum.romans: [
    32,
    29,
    31,
    25,
    21,
    23,
    25,
    39,
    33,
    21,
    36,
    21,
    14,
    23,
    33,
    27
  ],
  BibleBookEnum.firstCorinthians: [
    31,
    16,
    23,
    21,
    13,
    20,
    40,
    13,
    27,
    33,
    34,
    31,
    13,
    40,
    58,
    24,
  ],
  BibleBookEnum.secondCorinthians: [
    24,
    17,
    18,
    18,
    21,
    18,
    16,
    24,
    15,
    18,
    33,
    21,
    14
  ],
  BibleBookEnum.galatians: [24, 21, 29, 31, 26, 18],
  BibleBookEnum.ephesians: [23, 22, 21, 32, 33, 24],
  BibleBookEnum.philippians: [30, 30, 21, 23],
  BibleBookEnum.colossians: [29, 23, 25, 18],
  BibleBookEnum.firstThessalonians: [10, 20, 13, 18, 28],
  BibleBookEnum.secondThessalonians: [12, 17, 18],
  BibleBookEnum.firstTimothy: [20, 15, 16, 16, 25, 21],
  BibleBookEnum.secondTimothy: [18, 26, 17, 22],
  BibleBookEnum.titus: [16, 15, 15],
  BibleBookEnum.philemon: [25],
  BibleBookEnum.hebrews: [14, 18, 19, 16, 14, 20, 28, 13, 28, 39, 40, 29, 25],
  BibleBookEnum.james: [27, 26, 18, 17, 20],
  BibleBookEnum.firstPeter: [25, 25, 22, 19, 14],
  BibleBookEnum.secondPeter: [21, 22, 18],
  BibleBookEnum.firstJohn: [10, 29, 24, 21, 21],
  BibleBookEnum.secondJohn: [13],
  BibleBookEnum.thirdJohn: [14],
  BibleBookEnum.jude: [25],
  BibleBookEnum.revelation: [
    20,
    29,
    22,
    11,
    14,
    17,
    17,
    13,
    21,
    11,
    19,
    17,
    18,
    20,
    8,
    21,
    18,
    24,
    21,
    15,
    27,
    21,
  ],
};
