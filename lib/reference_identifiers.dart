import 'bible_book_enum.dart';
import 'references.dart';

/// The OSIS and USFM identifiers assigned to a [BibleBookEnum].
///
/// The OSIS values follow the CrossWire OSIS book abbreviation vocabulary:
/// https://wiki.crosswire.org/OSIS_Book_Abbreviations
///
/// The USFM values follow the official USFM book identifier vocabulary:
/// https://ubsicap.github.io/usfm/usfm3.0/identification/books.html
final class BibleBookIdentifiers {
  const BibleBookIdentifiers({
    required this.osis,
    required this.usfm,
  });

  /// The case-sensitive OSIS book identifier, such as `John` or `1Cor`.
  final String osis;

  /// The case-sensitive USFM book identifier, such as `JHN` or `1CO`.
  final String usfm;
}

/// Complete OSIS and USFM mappings for the books supported by this package.
///
/// Several traditions incorporate Greek Esther, the Daniel additions, or
/// Psalm 151 into another book. Because [BibleBookEnum] models them as
/// separate works, this table uses their separate-work identifiers:
///
/// * `AddEsth` / `ADE` for the additions to Esther
/// * `PrAzar` / `S3Y` for the Song of the Three Young Men
/// * `Sus` / `SUS` and `Bel` / `BEL` for the other Daniel additions
/// * `AddPs` / `PS2` for Psalm 151
///
/// Current USFM assigns `ESG` to the complete Greek Esther and has no distinct
/// identifier for only its additions. `ADE` is the established Paratext code
/// paired with OSIS `AddEsth`, and is the one package-specific book-code
/// extension in this table. `AddPs` is the CrossWire/SWORD OSIS identifier for
/// a separately encoded Psalm 151. Other OSIS producers may instead use
/// `Ps151` or include it in `Ps`; those representations are intentionally not
/// aliases here so reverse lookup remains deterministic.
const Map<BibleBookEnum, BibleBookIdentifiers> bibleBookIdentifiers = {
  BibleBookEnum.genesis: BibleBookIdentifiers(osis: 'Gen', usfm: 'GEN'),
  BibleBookEnum.exodus: BibleBookIdentifiers(osis: 'Exod', usfm: 'EXO'),
  BibleBookEnum.leviticus: BibleBookIdentifiers(osis: 'Lev', usfm: 'LEV'),
  BibleBookEnum.numbers: BibleBookIdentifiers(osis: 'Num', usfm: 'NUM'),
  BibleBookEnum.deuteronomy: BibleBookIdentifiers(osis: 'Deut', usfm: 'DEU'),
  BibleBookEnum.joshua: BibleBookIdentifiers(osis: 'Josh', usfm: 'JOS'),
  BibleBookEnum.judges: BibleBookIdentifiers(osis: 'Judg', usfm: 'JDG'),
  BibleBookEnum.ruth: BibleBookIdentifiers(osis: 'Ruth', usfm: 'RUT'),
  BibleBookEnum.firstSamuel: BibleBookIdentifiers(osis: '1Sam', usfm: '1SA'),
  BibleBookEnum.secondSamuel: BibleBookIdentifiers(osis: '2Sam', usfm: '2SA'),
  BibleBookEnum.firstKings: BibleBookIdentifiers(osis: '1Kgs', usfm: '1KI'),
  BibleBookEnum.secondKings: BibleBookIdentifiers(osis: '2Kgs', usfm: '2KI'),
  BibleBookEnum.firstChronicles:
      BibleBookIdentifiers(osis: '1Chr', usfm: '1CH'),
  BibleBookEnum.secondChronicles:
      BibleBookIdentifiers(osis: '2Chr', usfm: '2CH'),
  BibleBookEnum.ezra: BibleBookIdentifiers(osis: 'Ezra', usfm: 'EZR'),
  BibleBookEnum.nehemiah: BibleBookIdentifiers(osis: 'Neh', usfm: 'NEH'),
  BibleBookEnum.esther: BibleBookIdentifiers(osis: 'Esth', usfm: 'EST'),
  BibleBookEnum.job: BibleBookIdentifiers(osis: 'Job', usfm: 'JOB'),
  BibleBookEnum.psalms: BibleBookIdentifiers(osis: 'Ps', usfm: 'PSA'),
  BibleBookEnum.proverbs: BibleBookIdentifiers(osis: 'Prov', usfm: 'PRO'),
  BibleBookEnum.ecclesiastes: BibleBookIdentifiers(osis: 'Eccl', usfm: 'ECC'),
  BibleBookEnum.songOfSolomon: BibleBookIdentifiers(osis: 'Song', usfm: 'SNG'),
  BibleBookEnum.isaiah: BibleBookIdentifiers(osis: 'Isa', usfm: 'ISA'),
  BibleBookEnum.jeremiah: BibleBookIdentifiers(osis: 'Jer', usfm: 'JER'),
  BibleBookEnum.lamentations: BibleBookIdentifiers(osis: 'Lam', usfm: 'LAM'),
  BibleBookEnum.ezekiel: BibleBookIdentifiers(osis: 'Ezek', usfm: 'EZK'),
  BibleBookEnum.daniel: BibleBookIdentifiers(osis: 'Dan', usfm: 'DAN'),
  BibleBookEnum.hosea: BibleBookIdentifiers(osis: 'Hos', usfm: 'HOS'),
  BibleBookEnum.joel: BibleBookIdentifiers(osis: 'Joel', usfm: 'JOL'),
  BibleBookEnum.amos: BibleBookIdentifiers(osis: 'Amos', usfm: 'AMO'),
  BibleBookEnum.obadiah: BibleBookIdentifiers(osis: 'Obad', usfm: 'OBA'),
  BibleBookEnum.jonah: BibleBookIdentifiers(osis: 'Jonah', usfm: 'JON'),
  BibleBookEnum.micah: BibleBookIdentifiers(osis: 'Mic', usfm: 'MIC'),
  BibleBookEnum.nahum: BibleBookIdentifiers(osis: 'Nah', usfm: 'NAM'),
  BibleBookEnum.habakkuk: BibleBookIdentifiers(osis: 'Hab', usfm: 'HAB'),
  BibleBookEnum.zephaniah: BibleBookIdentifiers(osis: 'Zeph', usfm: 'ZEP'),
  BibleBookEnum.haggai: BibleBookIdentifiers(osis: 'Hag', usfm: 'HAG'),
  BibleBookEnum.zechariah: BibleBookIdentifiers(osis: 'Zech', usfm: 'ZEC'),
  BibleBookEnum.malachi: BibleBookIdentifiers(osis: 'Mal', usfm: 'MAL'),
  BibleBookEnum.matthew: BibleBookIdentifiers(osis: 'Matt', usfm: 'MAT'),
  BibleBookEnum.mark: BibleBookIdentifiers(osis: 'Mark', usfm: 'MRK'),
  BibleBookEnum.luke: BibleBookIdentifiers(osis: 'Luke', usfm: 'LUK'),
  BibleBookEnum.john: BibleBookIdentifiers(osis: 'John', usfm: 'JHN'),
  BibleBookEnum.acts: BibleBookIdentifiers(osis: 'Acts', usfm: 'ACT'),
  BibleBookEnum.romans: BibleBookIdentifiers(osis: 'Rom', usfm: 'ROM'),
  BibleBookEnum.firstCorinthians:
      BibleBookIdentifiers(osis: '1Cor', usfm: '1CO'),
  BibleBookEnum.secondCorinthians:
      BibleBookIdentifiers(osis: '2Cor', usfm: '2CO'),
  BibleBookEnum.galatians: BibleBookIdentifiers(osis: 'Gal', usfm: 'GAL'),
  BibleBookEnum.ephesians: BibleBookIdentifiers(osis: 'Eph', usfm: 'EPH'),
  BibleBookEnum.philippians: BibleBookIdentifiers(osis: 'Phil', usfm: 'PHP'),
  BibleBookEnum.colossians: BibleBookIdentifiers(osis: 'Col', usfm: 'COL'),
  BibleBookEnum.firstThessalonians:
      BibleBookIdentifiers(osis: '1Thess', usfm: '1TH'),
  BibleBookEnum.secondThessalonians:
      BibleBookIdentifiers(osis: '2Thess', usfm: '2TH'),
  BibleBookEnum.firstTimothy: BibleBookIdentifiers(osis: '1Tim', usfm: '1TI'),
  BibleBookEnum.secondTimothy: BibleBookIdentifiers(osis: '2Tim', usfm: '2TI'),
  BibleBookEnum.titus: BibleBookIdentifiers(osis: 'Titus', usfm: 'TIT'),
  BibleBookEnum.philemon: BibleBookIdentifiers(osis: 'Phlm', usfm: 'PHM'),
  BibleBookEnum.hebrews: BibleBookIdentifiers(osis: 'Heb', usfm: 'HEB'),
  BibleBookEnum.james: BibleBookIdentifiers(osis: 'Jas', usfm: 'JAS'),
  BibleBookEnum.firstPeter: BibleBookIdentifiers(osis: '1Pet', usfm: '1PE'),
  BibleBookEnum.secondPeter: BibleBookIdentifiers(osis: '2Pet', usfm: '2PE'),
  BibleBookEnum.firstJohn: BibleBookIdentifiers(osis: '1John', usfm: '1JN'),
  BibleBookEnum.secondJohn: BibleBookIdentifiers(osis: '2John', usfm: '2JN'),
  BibleBookEnum.thirdJohn: BibleBookIdentifiers(osis: '3John', usfm: '3JN'),
  BibleBookEnum.jude: BibleBookIdentifiers(osis: 'Jude', usfm: 'JUD'),
  BibleBookEnum.revelation: BibleBookIdentifiers(osis: 'Rev', usfm: 'REV'),
  BibleBookEnum.tobit: BibleBookIdentifiers(osis: 'Tob', usfm: 'TOB'),
  BibleBookEnum.judith: BibleBookIdentifiers(osis: 'Jdt', usfm: 'JDT'),
  BibleBookEnum.wisdom: BibleBookIdentifiers(osis: 'Wis', usfm: 'WIS'),
  BibleBookEnum.sirach: BibleBookIdentifiers(osis: 'Sir', usfm: 'SIR'),
  BibleBookEnum.baruch: BibleBookIdentifiers(osis: 'Bar', usfm: 'BAR'),
  BibleBookEnum.firstMaccabees:
      BibleBookIdentifiers(osis: '1Macc', usfm: '1MA'),
  BibleBookEnum.secondMaccabees:
      BibleBookIdentifiers(osis: '2Macc', usfm: '2MA'),
  BibleBookEnum.estherAdditions:
      BibleBookIdentifiers(osis: 'AddEsth', usfm: 'ADE'),
  BibleBookEnum.danielSongOfThree:
      BibleBookIdentifiers(osis: 'PrAzar', usfm: 'S3Y'),
  BibleBookEnum.danielSusanna: BibleBookIdentifiers(osis: 'Sus', usfm: 'SUS'),
  BibleBookEnum.danielBelAndTheDragon:
      BibleBookIdentifiers(osis: 'Bel', usfm: 'BEL'),
  BibleBookEnum.firstEsdras: BibleBookIdentifiers(osis: '1Esd', usfm: '1ES'),
  BibleBookEnum.secondEsdras: BibleBookIdentifiers(osis: '2Esd', usfm: '2ES'),
  BibleBookEnum.prayerOfManasseh:
      BibleBookIdentifiers(osis: 'PrMan', usfm: 'MAN'),
  BibleBookEnum.psalm151: BibleBookIdentifiers(osis: 'AddPs', usfm: 'PS2'),
  BibleBookEnum.thirdMaccabees:
      BibleBookIdentifiers(osis: '3Macc', usfm: '3MA'),
  BibleBookEnum.fourthMaccabees:
      BibleBookIdentifiers(osis: '4Macc', usfm: '4MA'),
};

final Map<String, BibleBookEnum> _booksByOsisIdentifier = {
  for (final entry in bibleBookIdentifiers.entries) entry.value.osis: entry.key,
};

final Map<String, BibleBookEnum> _booksByUsfmIdentifier = {
  for (final entry in bibleBookIdentifiers.entries) entry.value.usfm: entry.key,
};

/// Adds standard machine-readable identifiers to [BibleBookEnum].
extension BibleBookReferenceIdentifiers on BibleBookEnum {
  /// Both standard identifiers associated with this book.
  BibleBookIdentifiers get referenceIdentifiers => bibleBookIdentifiers[this]!;

  /// The case-sensitive OSIS book identifier.
  String get osisIdentifier => referenceIdentifiers.osis;

  /// The case-sensitive USFM book identifier.
  String get usfmIdentifier => referenceIdentifiers.usfm;
}

/// Resolves an exact, case-sensitive OSIS book [identifier].
///
/// Throws [ArgumentError] when [identifier] is empty, has surrounding
/// whitespace, has the wrong case, or is not represented by [BibleBookEnum].
BibleBookEnum bibleBookFromOsisIdentifier(String identifier) =>
    _bookFromIdentifier(
      identifier,
      formatName: 'OSIS',
      lookup: _booksByOsisIdentifier,
    );

/// Resolves an exact, case-sensitive USFM book [identifier].
///
/// Throws [ArgumentError] when [identifier] is empty, has surrounding
/// whitespace, has the wrong case, or is not represented by [BibleBookEnum].
BibleBookEnum bibleBookFromUsfmIdentifier(String identifier) =>
    _bookFromIdentifier(
      identifier,
      formatName: 'USFM',
      lookup: _booksByUsfmIdentifier,
    );

BibleBookEnum _bookFromIdentifier(
  String identifier, {
  required String formatName,
  required Map<String, BibleBookEnum> lookup,
}) {
  final book = lookup[identifier];
  if (book == null) {
    throw ArgumentError.value(
      identifier,
      'identifier',
      'unknown or non-canonical $formatName book identifier',
    );
  }
  return book;
}

/// Adds canonical OSIS and USFM serialization to verse references.
extension ReferenceMachineIdentifiers on Reference {
  /// Encodes this reference as an OSIS identifier.
  ///
  /// Ranges repeat both full endpoints, for example
  /// `2Cor.6.14-2Cor.7.1`.
  /// Verse subdivisions use OSIS sub-identifiers, such as `John.1.5!a`.
  /// See section 15.3 of the OSIS 2.1.1 User's Manual:
  /// https://www.crosswire.org/osis/OSIS%202.1.1%20User%20Manual%2006March2006.pdf
  String get osisIdentifier => switch (this) {
        VerseRef verse => _verseToOsis(verse),
        VerseRangeRef range =>
          '${_verseToOsis(range.start)}-${_verseToOsis(range.end)}',
      };

  /// Encodes this reference as a USFM machine-readable reference.
  ///
  /// Same-book ranges use the compact official form, such as
  /// `JHN 3:16-17` or `JHN 3:16-4:1`.
  /// Verse subdivisions retain their lowercase suffix, such as `JHN 1:5a`.
  ///
  /// For a range spanning books, this package uses
  /// `JHN-ACT 21:25-1:2`. USFM defines the `BOOK-BOOK` prefix for book ranges,
  /// but does not define a universal coordinate-pair form for a cross-book
  /// verse range; the two coordinate groups are therefore a documented,
  /// reversible extension used by this package.
  String get usfmIdentifier => switch (this) {
        VerseRef verse => _verseToUsfm(verse),
        VerseRangeRef range => _rangeToUsfm(range),
      };
}

/// Adds canonical OSIS and USFM serialization to passage expressions.
extension PassageMachineIdentifiers on Passage {
  /// Encodes this passage using OSIS book and coordinate identifiers.
  ///
  /// Verse selections retain their complete [Reference.osisIdentifier]
  /// values. Multiple OSIS values are conventionally separated by spaces.
  String get osisIdentifier => switch (this) {
        BookPassage passage => passage.book.osisIdentifier,
        ChapterPassage passage => _chapterPassageToOsis(passage),
        VersePassage passage => passage.selections
            .map((selection) => selection.osisIdentifier)
            .join(' '),
        PassageSequence passage => passage.passages
            .map((selection) => selection.osisIdentifier)
            .join(' '),
      };

  /// Encodes this passage using USFM book and coordinate identifiers.
  ///
  /// Same-book, same-chapter verse selections use compact comma notation,
  /// such as `JHN 3:16,18-20`. A selection whose book or chapter changes
  /// retains its complete [Reference.usfmIdentifier]. Passage sequences are
  /// separated by `; `.
  String get usfmIdentifier => switch (this) {
        BookPassage passage => passage.book.usfmIdentifier,
        ChapterPassage passage => _chapterPassageToUsfm(passage),
        VersePassage passage => _versePassageToUsfm(passage),
        PassageSequence passage => passage.passages
            .map((selection) => selection.usfmIdentifier)
            .join('; '),
      };
}

String _chapterPassageToOsis(ChapterPassage passage) {
  final book = passage.book.osisIdentifier;
  final start = '$book.${passage.startChapter}';
  final end = passage.endChapter;
  return end == null ? start : '$start-$book.$end';
}

String _chapterPassageToUsfm(ChapterPassage passage) {
  final start = '${passage.book.usfmIdentifier} ${passage.startChapter}';
  final end = passage.endChapter;
  return end == null ? start : '$start-$end';
}

String _versePassageToUsfm(VersePassage passage) {
  final first = passage.selections.first;
  if (passage.selections.length == 1) return first.usfmIdentifier;

  final anchor = _identifierReferenceStart(first);
  final buffer = StringBuffer(first.usfmIdentifier);
  for (final selection in passage.selections.skip(1)) {
    buffer
      ..write(',')
      ..write(_compactUsfmSelection(selection, anchor));
  }
  return buffer.toString();
}

String _compactUsfmSelection(Reference selection, VerseRef anchor) {
  return switch (selection) {
    VerseRef verse
        when verse.book == anchor.book && verse.chapter == anchor.chapter =>
      verse.verseLabel,
    VerseRangeRef range
        when range.start.book == anchor.book &&
            range.end.book == anchor.book &&
            range.start.chapter == anchor.chapter &&
            range.end.chapter == anchor.chapter =>
      '${range.start.verseLabel}-${range.end.verseLabel}',
    _ => selection.usfmIdentifier,
  };
}

VerseRef _identifierReferenceStart(Reference reference) => switch (reference) {
      VerseRef() => reference,
      VerseRangeRef() => reference.start,
    };

String _verseToOsis(VerseRef verse) =>
    '${verse.book.osisIdentifier}.${verse.chapter}.${verse.verse}'
    '${verse.subdivision == null ? '' : '!${verse.subdivision}'}';

String _verseToUsfm(VerseRef verse) =>
    '${verse.book.usfmIdentifier} ${verse.chapter}:${verse.verseLabel}';

String _rangeToUsfm(VerseRangeRef range) {
  final start = range.start;
  final end = range.end;
  if (start.book != end.book) {
    return '${start.book.usfmIdentifier}-${end.book.usfmIdentifier} '
        '${start.chapter}:${start.verseLabel}-${end.chapter}:${end.verseLabel}';
  }
  if (start.chapter == end.chapter) {
    return '${start.book.usfmIdentifier} '
        '${start.chapter}:${start.verseLabel}-${end.verseLabel}';
  }
  return '${start.book.usfmIdentifier} '
      '${start.chapter}:${start.verseLabel}-${end.chapter}:${end.verseLabel}';
}

final RegExp _osisReferencePattern = RegExp(
  r'^([A-Za-z0-9]+)\.([0-9]+)\.([0-9]+)(?:!([a-z]))?(?:-([A-Za-z0-9]+)\.([0-9]+)\.([0-9]+)(?:!([a-z]))?)?$',
);

final RegExp _usfmSameBookReferencePattern = RegExp(
  r'^([A-Z1-4]{3}) ([0-9]+):([0-9]+)([a-z])?(?:-(?:([0-9]+):)?([0-9]+)([a-z])?)?$',
);

final RegExp _usfmCrossBookReferencePattern = RegExp(
  r'^([A-Z1-4]{3})-([A-Z1-4]{3}) ([0-9]+):([0-9]+)([a-z])?-([0-9]+):([0-9]+)([a-z])?$',
);

/// Parses a verse or full-endpoint range OSIS [identifier].
///
/// Supported shapes are `John.3.16` and
/// `2Cor.6.14-2Cor.7.1`. The syntax and book identifiers are
/// case-sensitive. Throws [FormatException] for malformed input, unknown book
/// identifiers, invalid coordinates, or non-ascending ranges.
/// A verse may have a single lowercase subdivision after `!`, as in
/// `John.1.5!a` or `John.1.5!a-John.1.5!b`. Other OSIS sub-identifiers are
/// outside this package's verse model and are rejected.
Reference referenceFromOsisIdentifier(String identifier) {
  final match = _osisReferencePattern.firstMatch(identifier);
  if (match == null) {
    throw FormatException(
      'Invalid OSIS reference identifier; expected BOOK.CHAPTER.VERSE or '
      'BOOK.CHAPTER.VERSE-BOOK.CHAPTER.VERSE',
      identifier,
    );
  }

  final start = _parseVerseEndpoint(
    identifier,
    formatName: 'OSIS',
    bookIdentifier: match[1]!,
    chapterToken: match[2]!,
    verseToken: match[3]!,
    subdivision: match[4],
    bookLookup: bibleBookFromOsisIdentifier,
  );
  if (match[5] == null) return start;

  final end = _parseVerseEndpoint(
    identifier,
    formatName: 'OSIS',
    bookIdentifier: match[5]!,
    chapterToken: match[6]!,
    verseToken: match[7]!,
    subdivision: match[8],
    bookLookup: bibleBookFromOsisIdentifier,
  );
  return _checkedRange(start, end, identifier, formatName: 'OSIS');
}

/// Parses a USFM verse or range [identifier].
///
/// Supported standard shapes are `JHN 3:16`, `JHN 3:16-17`, and
/// `JHN 3:16-4:1`. The package's reversible cross-book extension,
/// `JHN-ACT 21:25-1:2`, is also supported. Syntax and book identifiers are
/// case-sensitive. Throws [FormatException] for malformed input, unknown book
/// identifiers, invalid coordinates, or non-ascending ranges.
/// A verse may have a single lowercase subdivision, as in `JHN 1:5a` or
/// `JHN 1:5a-5b`. USFM reference syntax and verse bridge examples are documented
/// at https://ubsicap.github.io/usfm/linking/index.html.
Reference referenceFromUsfmIdentifier(String identifier) {
  final crossBookMatch = _usfmCrossBookReferencePattern.firstMatch(identifier);
  if (crossBookMatch != null) {
    final start = _parseVerseEndpoint(
      identifier,
      formatName: 'USFM',
      bookIdentifier: crossBookMatch[1]!,
      chapterToken: crossBookMatch[3]!,
      verseToken: crossBookMatch[4]!,
      subdivision: crossBookMatch[5],
      bookLookup: bibleBookFromUsfmIdentifier,
    );
    final end = _parseVerseEndpoint(
      identifier,
      formatName: 'USFM',
      bookIdentifier: crossBookMatch[2]!,
      chapterToken: crossBookMatch[6]!,
      verseToken: crossBookMatch[7]!,
      subdivision: crossBookMatch[8],
      bookLookup: bibleBookFromUsfmIdentifier,
    );
    return _checkedRange(start, end, identifier, formatName: 'USFM');
  }

  final match = _usfmSameBookReferencePattern.firstMatch(identifier);
  if (match == null) {
    throw FormatException(
      'Invalid USFM reference identifier; expected BOOK CHAPTER:VERSE, '
      'BOOK CHAPTER:VERSE-VERSE, BOOK CHAPTER:VERSE-CHAPTER:VERSE, or '
      'BOOK-BOOK CHAPTER:VERSE-CHAPTER:VERSE',
      identifier,
    );
  }

  final start = _parseVerseEndpoint(
    identifier,
    formatName: 'USFM',
    bookIdentifier: match[1]!,
    chapterToken: match[2]!,
    verseToken: match[3]!,
    subdivision: match[4],
    bookLookup: bibleBookFromUsfmIdentifier,
  );
  if (match[6] == null) return start;

  final end = _parseVerseEndpoint(
    identifier,
    formatName: 'USFM',
    bookIdentifier: match[1]!,
    chapterToken: match[5] ?? match[2]!,
    verseToken: match[6]!,
    subdivision: match[7],
    bookLookup: bibleBookFromUsfmIdentifier,
  );
  return _checkedRange(start, end, identifier, formatName: 'USFM');
}

VerseRef _parseVerseEndpoint(
  String source, {
  required String formatName,
  required String bookIdentifier,
  required String chapterToken,
  required String verseToken,
  String? subdivision,
  required BibleBookEnum Function(String) bookLookup,
}) {
  try {
    return VerseRef.checked(
      book: bookLookup(bookIdentifier),
      chapter: int.parse(chapterToken),
      verse: int.parse(verseToken),
      subdivision: subdivision,
    );
  } on ArgumentError catch (error) {
    throw FormatException(
      'Invalid $formatName reference identifier: ${error.message}',
      source,
    );
  }
}

VerseRangeRef _checkedRange(
  VerseRef start,
  VerseRef end,
  String source, {
  required String formatName,
}) {
  try {
    return VerseRangeRef.checked(start: start, end: end);
  } on ArgumentError catch (error) {
    throw FormatException(
      'Invalid $formatName reference identifier: ${error.message}',
      source,
    );
  }
}
