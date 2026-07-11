part of '../references.dart';

/// A complete Bible passage expression.
///
/// Unlike [Reference], passages can describe whole books or chapters, a
/// selection of verses, or a semicolon-separated sequence of those forms.
sealed class Passage {
  const Passage();

  /// Parses [input] using the shared standard passage parser.
  static Passage parse(
    String input, {
    BibleLanguageEnum? language,
  }) =>
      _standardPassageParser.parse(input, language: language);

  /// Parses [input], returning `null` instead of throwing when it is invalid.
  static Passage? tryParse(
    String input, {
    BibleLanguageEnum? language,
  }) =>
      _standardPassageParser.tryParse(input, language: language);

  /// Parses [input] into an explicit success or failure value.
  static ParseResult<Passage> parseResult(
    String input, {
    BibleLanguageEnum? language,
  }) =>
      _standardPassageParser.parseResult(input, language: language);

  /// Restores a passage produced by [toJson].
  static Passage fromJson(
    Map<String, Object?> json, {
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    return switch (json['type']) {
      'book' => BookPassage.fromJson(
          json,
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
      'chapter' => ChapterPassage.fromJson(
          json,
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
      'verses' => VersePassage.fromJson(
          json,
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
      'sequence' => PassageSequence.fromJson(
          json,
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
      final type => throw FormatException('unknown passage type: $type'),
    };
  }

  /// A compact, canonical representation of this passage.
  String get displayString;

  /// Converts this passage to a stable JSON-compatible map.
  Map<String, Object?> toJson();

  @override
  String toString() => displayString;
}

/// A passage covering an entire Bible book.
final class BookPassage extends Passage {
  const BookPassage(this.book);

  final BibleBookEnum book;

  static BookPassage fromJson(
    Map<String, Object?> json, {
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final book = _bookFromJson(json['book']);
    final effectiveCanon = _effectiveCanonProfile(
      canonProfile,
      versificationProfile,
    );
    if (effectiveCanon != null) {
      _validateBookInCanon(book, effectiveCanon);
    }
    versificationProfile?.chapterCount(book);
    return BookPassage(book);
  }

  @override
  String get displayString => book.fullName;

  @override
  Map<String, Object?> toJson() => {
        'type': 'book',
        'book': book.abbreviation,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BookPassage && book == other.book;

  @override
  int get hashCode => book.hashCode;
}

/// A passage covering one chapter or an inclusive range of chapters.
final class ChapterPassage extends Passage {
  factory ChapterPassage(
    BibleBookEnum book,
    int startChapter, [
    int? endChapter,
  ]) {
    _validateReferenceNumber(
      startChapter,
      component: 'startChapter',
      maximum: maxReferenceChapterNumber,
    );
    if (endChapter != null) {
      _validateReferenceNumber(
        endChapter,
        component: 'endChapter',
        maximum: maxReferenceChapterNumber,
      );
      if (endChapter <= startChapter) {
        throw ArgumentError.value(
          endChapter,
          'endChapter',
          'must come after startChapter',
        );
      }
    }
    return ChapterPassage._(book, startChapter, endChapter);
  }

  const ChapterPassage._(this.book, this.startChapter, this.endChapter);

  /// Creates a chapter passage while enforcing numeric and ordering checks.
  factory ChapterPassage.checked({
    required BibleBookEnum book,
    required int startChapter,
    int? endChapter,
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final effectiveCanon = _effectiveCanonProfile(
      canonProfile,
      versificationProfile,
    );
    if (effectiveCanon != null) {
      _validateBookInCanon(book, effectiveCanon);
    }
    versificationProfile?.verseCount(book, startChapter);
    if (endChapter != null) {
      versificationProfile?.verseCount(book, endChapter);
    }
    return ChapterPassage(book, startChapter, endChapter);
  }

  final BibleBookEnum book;
  final int startChapter;
  final int? endChapter;

  static ChapterPassage fromJson(
    Map<String, Object?> json, {
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final end = json['endChapter'];
    if (end != null && end is! int) {
      throw const FormatException('"endChapter" must be an integer or null');
    }
    return ChapterPassage.checked(
      book: _bookFromJson(json['book']),
      startChapter: _intFromJson(json, 'startChapter'),
      endChapter: end as int?,
      canonProfile: canonProfile,
      versificationProfile: versificationProfile,
    );
  }

  @override
  String get displayString => endChapter == null
      ? '${book.fullName} $startChapter'
      : '${book.fullName} $startChapter-$endChapter';

  @override
  Map<String, Object?> toJson() => {
        'type': 'chapter',
        'book': book.abbreviation,
        'startChapter': startChapter,
        'endChapter': endChapter,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterPassage &&
          book == other.book &&
          startChapter == other.startChapter &&
          endChapter == other.endChapter;

  @override
  int get hashCode => Object.hash(book, startChapter, endChapter);
}

/// One or more discrete verse references belonging to one passage expression.
final class VersePassage extends Passage {
  factory VersePassage(List<Reference> selections) {
    if (selections.isEmpty) {
      throw ArgumentError.value(
        selections,
        'selections',
        'must contain at least one reference',
      );
    }
    return VersePassage._(List<Reference>.unmodifiable(selections));
  }

  const VersePassage._(this.selections);

  /// Creates a verse passage while checking that it is not empty.
  factory VersePassage.checked({
    required Iterable<Reference> selections,
  }) =>
      VersePassage(List<Reference>.of(selections));

  final List<Reference> selections;

  static VersePassage fromJson(
    Map<String, Object?> json, {
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final values = json['selections'];
    if (values is! List) {
      throw const FormatException('"selections" must be an array');
    }
    return VersePassage([
      for (final value in values)
        Reference.fromJson(
          _passageJsonMap(value, 'selection'),
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
    ]);
  }

  @override
  String get displayString {
    final first = selections.first;
    final anchor = _referenceStart(first);
    final buffer = StringBuffer(first.displayString);
    for (final selection in selections.skip(1)) {
      buffer
        ..write(',')
        ..write(_compactSelectionString(selection, anchor));
    }
    return buffer.toString();
  }

  @override
  Map<String, Object?> toJson() => {
        'type': 'verses',
        'selections': [
          for (final selection in selections) selection.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersePassage && _passageListsEqual(selections, other.selections);

  @override
  int get hashCode => Object.hashAll(selections);
}

/// A source-ordered sequence of passage expressions.
final class PassageSequence extends Passage {
  factory PassageSequence(List<Passage> passages) {
    if (passages.isEmpty) {
      throw ArgumentError.value(
        passages,
        'passages',
        'must contain at least one passage',
      );
    }
    return PassageSequence._(List<Passage>.unmodifiable(passages));
  }

  const PassageSequence._(this.passages);

  /// Creates a sequence while checking that it is not empty.
  factory PassageSequence.checked({
    required Iterable<Passage> passages,
  }) =>
      PassageSequence(List<Passage>.of(passages));

  final List<Passage> passages;

  static PassageSequence fromJson(
    Map<String, Object?> json, {
    CanonProfile? canonProfile,
    VersificationProfile? versificationProfile,
  }) {
    final values = json['passages'];
    if (values is! List) {
      throw const FormatException('"passages" must be an array');
    }
    return PassageSequence([
      for (final value in values)
        Passage.fromJson(
          _passageJsonMap(value, 'passage'),
          canonProfile: canonProfile,
          versificationProfile: versificationProfile,
        ),
    ]);
  }

  @override
  String get displayString =>
      passages.map((passage) => passage.displayString).join('; ');

  @override
  Map<String, Object?> toJson() => {
        'type': 'sequence',
        'passages': [for (final passage in passages) passage.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassageSequence && _passageListsEqual(passages, other.passages);

  @override
  int get hashCode => Object.hashAll(passages);
}

/// A reusable parser for book, chapter, verse-list, and passage sequences.
final class PassageParser {
  factory PassageParser({
    ReferenceParser? referenceParser,
    Set<BibleBookEnum>? singleChapterBooks,
  }) {
    final books = singleChapterBooks ?? _defaultSingleChapterBooks;
    return PassageParser._(
      referenceParser ?? ReferenceParser.standard,
      Set<BibleBookEnum>.unmodifiable(books),
    );
  }

  const PassageParser._(this.referenceParser, this.singleChapterBooks);

  /// The parser used for localized and caller-supplied book aliases.
  final ReferenceParser referenceParser;

  /// Books for which a bare number is interpreted as a verse in chapter one.
  final Set<BibleBookEnum> singleChapterBooks;

  Passage parse(String input, {BibleLanguageEnum? language}) =>
      _parse(input, language: language).value;

  Passage? tryParse(String input, {BibleLanguageEnum? language}) =>
      parseResult(input, language: language).valueOrNull;

  ParseResult<Passage> parseResult(
    String input, {
    BibleLanguageEnum? language,
  }) {
    try {
      final parsed = _parse(input, language: language);
      return ParseSuccess(parsed.value, metadata: parsed.metadata);
    } on ParseVerseRefError catch (error) {
      return ParseFailure(error);
    }
  }

  _ParsedPassage _parse(
    String input, {
    BibleLanguageEnum? language,
  }) {
    final normalizedInput = ReferenceInputNormalizer.normalize(input);
    _ensureReferenceIsNotEmpty(normalizedInput);
    referenceParser._validateLanguage(language);

    final sourceSegments = normalizedInput.split(';');
    if (sourceSegments.any((segment) => segment.trim().isEmpty)) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'passage sequence contains an empty expression',
      );
    }

    final passages = <Passage>[];
    final matches = <ReferenceBookTokenMatch>[];
    for (final sourceSegment in sourceSegments) {
      final parsed = _parseSegment(sourceSegment.trim(), language: language);
      passages.add(parsed.value);
      matches.addAll(parsed.bookMatches);
    }

    final value =
        passages.length == 1 ? passages.single : PassageSequence(passages);
    return _ParsedPassage(
      value,
      ReferenceParseMetadata(
        normalizedInput: _normalizePassageWhitespace(normalizedInput),
        bookMatches: matches,
      ),
    );
  }

  _ParsedPassageSegment _parseSegment(
    String input, {
    BibleLanguageEnum? language,
  }) {
    final wholeBook = _tryResolveBook(input, language: language);
    if (wholeBook != null) {
      referenceParser._validateBookProfile(wholeBook.match.selected.book);
      return _ParsedPassageSegment(
        BookPassage(wholeBook.match.selected.book),
        [wholeBook.match],
      );
    }

    final split = _splitBookAndBody(input, language: language);
    final book = split.resolution.match.selected.book;
    final body = split.body;
    referenceParser._validateBookProfile(book);

    final chapter = _passageChapterPattern.firstMatch(body);
    if (chapter != null) {
      final number = _parseReferenceNumber(
        chapter.group(1)!,
        component: singleChapterBooks.contains(book) ? 'verse' : 'chapter',
        maximum: singleChapterBooks.contains(book)
            ? maxReferenceVerseNumber
            : maxReferenceChapterNumber,
      );
      final Passage value;
      if (singleChapterBooks.contains(book)) {
        final verse = VerseRef.checked(book: book, chapter: 1, verse: number);
        referenceParser._validateVerseProfile(verse);
        value = VersePassage([verse]);
      } else {
        referenceParser._validateChapterProfile(book, number);
        value = ChapterPassage(book, number);
      }
      return _ParsedPassageSegment(value, [split.resolution.match]);
    }

    final chapterRange = _passageChapterRangePattern.firstMatch(body);
    if (chapterRange != null) {
      final isSingleChapterBook = singleChapterBooks.contains(book);
      final maximum = isSingleChapterBook
          ? maxReferenceVerseNumber
          : maxReferenceChapterNumber;
      final component = isSingleChapterBook ? 'verse' : 'chapter';
      final start = _parseReferenceNumber(
        chapterRange.group(1)!,
        component: 'start $component',
        maximum: maximum,
      );
      final end = _parseReferenceNumber(
        chapterRange.group(2)!,
        component: 'end $component',
        maximum: maximum,
      );
      if (end <= start) {
        throw ParseVerseRefError.typed(
          code: ReferenceParseErrorCode.sameBookRangeNotAscending,
          details: 'end $component must come after start $component',
        );
      }
      final Passage value;
      if (isSingleChapterBook) {
        final startVerse =
            VerseRef.checked(book: book, chapter: 1, verse: start);
        final endVerse = VerseRef.checked(book: book, chapter: 1, verse: end);
        referenceParser
          .._validateVerseProfile(startVerse)
          .._validateVerseProfile(endVerse);
        value = VersePassage([
          VerseRangeRef(start: startVerse, end: endVerse),
        ]);
      } else {
        referenceParser
          .._validateChapterProfile(book, start)
          .._validateChapterProfile(book, end);
        value = ChapterPassage(book, start, end);
      }
      return _ParsedPassageSegment(value, [split.resolution.match]);
    }

    if (body.contains(',')) {
      return _parseVerseList(split, language: language);
    }

    final parsed = referenceParser._parseReference(
      '${split.bookToken} $body',
      language: language,
    );
    return _ParsedPassageSegment(
      VersePassage([parsed.value]),
      parsed.metadata.bookMatches,
    );
  }

  _ParsedPassageSegment _parseVerseList(
    _PassageBookBody split, {
    BibleLanguageEnum? language,
  }) {
    final bodyMatch = _passageVerseListPattern.firstMatch(split.body);
    if (bodyMatch == null) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'verse list "${split.body}" does not match expected format',
      );
    }
    final chapter = _parseReferenceNumber(
      bodyMatch.group(1)!,
      component: 'chapter',
      maximum: maxReferenceChapterNumber,
    );
    final tokens = bodyMatch.group(2)!.split(',');
    if (tokens.any((token) => token.trim().isEmpty)) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'verse list contains an empty selection',
      );
    }

    final book = split.resolution.match.selected.book;
    final selections = <Reference>[];
    for (final token in tokens) {
      selections.add(_parseVerseSelection(token.trim(), book, chapter));
    }
    return _ParsedPassageSegment(
      VersePassage(selections),
      [split.resolution.match],
    );
  }

  Reference _parseVerseSelection(
    String input,
    BibleBookEnum book,
    int defaultChapter,
  ) {
    final match = _passageVerseSelectionPattern.firstMatch(input);
    if (match == null) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'verse selection "$input" does not match expected format',
      );
    }
    final startChapterToken = match.group(1);
    final startChapter = startChapterToken == null
        ? defaultChapter
        : _parseReferenceNumber(
            startChapterToken,
            component: 'start chapter',
            maximum: maxReferenceChapterNumber,
          );
    final startVerse = _parseReferenceNumber(
      match.group(2)!,
      component: 'start verse',
      maximum: maxReferenceVerseNumber,
    );
    final start = VerseRef.checked(
      book: book,
      chapter: startChapter,
      verse: startVerse,
    );
    referenceParser._validateVerseProfile(start);

    final endVerseToken = match.group(4);
    if (endVerseToken == null) return start;
    final endChapterToken = match.group(3);
    final endChapter = endChapterToken == null
        ? startChapter
        : _parseReferenceNumber(
            endChapterToken,
            component: 'end chapter',
            maximum: maxReferenceChapterNumber,
          );
    final end = VerseRef.checked(
      book: book,
      chapter: endChapter,
      verse: _parseReferenceNumber(
        endVerseToken,
        component: 'end verse',
        maximum: maxReferenceVerseNumber,
      ),
    );
    referenceParser._validateVerseProfile(end);
    if (referenceParser._compareVerseProfiles(start, end) >= 0) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.sameBookRangeNotAscending,
        details: 'end reference must come after start reference',
      );
    }
    return VerseRangeRef(start: start, end: end);
  }

  _BookResolution? _tryResolveBook(
    String input, {
    BibleLanguageEnum? language,
  }) {
    try {
      return referenceParser._resolveBook(input, language: language);
    } on ParseVerseRefError catch (error) {
      if (error.errorCode != ReferenceParseErrorCode.unknownBook) rethrow;
      return null;
    }
  }

  _PassageBookBody _splitBookAndBody(
    String input, {
    BibleLanguageEnum? language,
  }) {
    ParseVerseRefError? lastUnknownBook;
    final digitStarts = <int>[];
    for (final match in RegExp(r'[0-9]').allMatches(input)) {
      if (match.start > 0) digitStarts.add(match.start);
    }
    for (final position in digitStarts.reversed) {
      final bookToken = input.substring(0, position).trim();
      final body = input.substring(position).trim();
      if (bookToken.isEmpty || !_passageBodyStartsWithNumber.hasMatch(body)) {
        continue;
      }
      try {
        return _PassageBookBody(
          bookToken,
          body,
          referenceParser._resolveBook(bookToken, language: language),
        );
      } on ParseVerseRefError catch (error) {
        if (error.errorCode != ReferenceParseErrorCode.unknownBook) rethrow;
        lastUnknownBook = error;
      }
    }
    throw lastUnknownBook ??
        ParseVerseRefError.typed(
          code: ReferenceParseErrorCode.patternMismatch,
          details: 'passage "$input" does not match expected format',
        );
  }
}

const Set<BibleBookEnum> _defaultSingleChapterBooks = {
  BibleBookEnum.obadiah,
  BibleBookEnum.philemon,
  BibleBookEnum.secondJohn,
  BibleBookEnum.thirdJohn,
  BibleBookEnum.jude,
};

final PassageParser _standardPassageParser = PassageParser();

final _passageChapterPattern = RegExp(r'^(\d+)$');
final _passageChapterRangePattern =
    RegExp(r'^(\d+)\s*[-\u2013\u2014\u2015]\s*(\d+)$');
final _passageVerseListPattern = RegExp(r'^(\d+)\s*[:.]\s*(.+)$');
final _passageVerseSelectionPattern = RegExp(
  r'^(?:(\d+)\s*[:.]\s*)?(\d+)(?:\s*[-\u2013\u2014\u2015]\s*(?:(\d+)\s*[:.]\s*)?(\d+))?$',
);
final _passageBodyStartsWithNumber = RegExp(r'^\d');

final class _ParsedPassage {
  const _ParsedPassage(this.value, this.metadata);

  final Passage value;
  final ReferenceParseMetadata metadata;
}

final class _ParsedPassageSegment {
  const _ParsedPassageSegment(this.value, this.bookMatches);

  final Passage value;
  final List<ReferenceBookTokenMatch> bookMatches;
}

final class _PassageBookBody {
  const _PassageBookBody(
    this.bookToken,
    this.body,
    this.resolution,
  );

  final String bookToken;
  final String body;
  final _BookResolution resolution;
}

String _normalizePassageWhitespace(String input) =>
    input.trim().replaceAll(RegExp(r'\s+'), ' ');

Map<String, Object?> _passageJsonMap(Object? value, String component) {
  if (value is! Map) {
    throw FormatException('"$component" must be an object');
  }
  return Map<String, Object?>.from(value);
}

bool _passageListsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

VerseRef _referenceStart(Reference reference) => switch (reference) {
      VerseRef() => reference,
      VerseRangeRef() => reference.start,
    };

String _compactSelectionString(Reference reference, VerseRef anchor) {
  final start = _referenceStart(reference);
  if (start.book != anchor.book) return reference.displayString;

  final prefix = start.chapter == anchor.chapter
      ? '${start.verse}'
      : '${start.chapter}:${start.verse}';
  if (reference is VerseRef) return prefix;
  final end = switch (reference) {
    VerseRangeRef(:final end) => end,
    VerseRef() => throw StateError('unreachable verse reference branch'),
  };
  if (end.book != start.book) {
    return '$prefix-${end.book.fullName} ${end.chapter}:${end.verse}';
  }
  if (end.chapter == start.chapter) return '$prefix-${end.verse}';
  return '$prefix-${end.chapter}:${end.verse}';
}
