part of '../references.dart';

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
      return _ParsedPassageSegment(
        BookPassage(wholeBook.match.selected.book),
        [wholeBook.match],
      );
    }

    final split = _splitBookAndBody(input, language: language);
    final book = split.resolution.match.selected.book;
    final body = split.body;

    final chapter = _passageChapterPattern.firstMatch(body);
    if (chapter != null) {
      final number = _parseReferenceNumber(
        chapter.group(1)!,
        component: singleChapterBooks.contains(book) ? 'verse' : 'chapter',
        maximum: singleChapterBooks.contains(book)
            ? maxReferenceVerseNumber
            : maxReferenceChapterNumber,
      );
      final value = singleChapterBooks.contains(book)
          ? VersePassage([
              VerseRef.checked(book: book, chapter: 1, verse: number),
            ])
          : ChapterPassage(book, number);
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
        value = VersePassage([
          VerseRangeRef.checked(
            start: VerseRef.checked(book: book, chapter: 1, verse: start),
            end: VerseRef.checked(book: book, chapter: 1, verse: end),
          ),
        ]);
      } else {
        value = ChapterPassage(book, start, end);
      }
      return _ParsedPassageSegment(value, [split.resolution.match]);
    }

    if (singleChapterBooks.contains(book) &&
        _passageBareVersePattern.hasMatch(body)) {
      return _ParsedPassageSegment(
        VersePassage([_parseVerseSelection(body, book, 1)]),
        [split.resolution.match],
      );
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
    final startVerse = _parseVerseToken(
      match.group(2)!,
      component: 'start verse',
    );
    final start = VerseRef.checked(
      book: book,
      chapter: startChapter,
      verse: startVerse.verse,
      subdivision: startVerse.subdivision,
    );

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
    final endVerse = _parseVerseToken(endVerseToken, component: 'end verse');
    final end = VerseRef.checked(
      book: book,
      chapter: endChapter,
      verse: endVerse.verse,
      subdivision: endVerse.subdivision,
    );
    if (start.compareTo(end) >= 0) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.sameBookRangeNotAscending,
        details: 'end reference must come after start reference',
      );
    }
    return VerseRangeRef.checked(start: start, end: end);
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
  r'^(?:(\d+)\s*[:.]\s*)?(\d+[a-zA-Z]?)(?:\s*[-\u2013\u2014\u2015]\s*(?:(\d+)\s*[:.]\s*)?(\d+[a-zA-Z]?))?$',
);
final _passageBareVersePattern =
    RegExp(r'^\d+[a-zA-Z]?(?:\s*[-\u2013\u2014\u2015]\s*\d+[a-zA-Z]?)?$');
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
