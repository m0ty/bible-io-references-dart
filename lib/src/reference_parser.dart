part of '../references.dart';

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

    return ReferenceParser._(
      aliases: aliasesCopy,
      aliasesByLanguage: Map.unmodifiable(localizedCopy),
      preferredLanguages: List.unmodifiable(preferredCopy),
      ambiguityPolicy: ambiguityPolicy,
    );
  }

  ReferenceParser._({
    required this.aliases,
    required this.aliasesByLanguage,
    required this.preferredLanguages,
    required this.ambiguityPolicy,
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
    final verse = _parseVerseToken(
      match.group(3)!,
      component: 'verse',
    );
    final resolution = _resolveBook(match.group(1)!, language: language);
    final value = VerseRef.checked(
      book: resolution.match.selected.book,
      chapter: chapter,
      verse: verse.verse,
      subdivision: verse.subdivision,
    );
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
    final startVerse = _parseVerseToken(
      match.group(3)!,
      component: 'start verse',
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
    final endVerse = _parseVerseToken(
      endVerseToken,
      component: 'end verse',
    );

    final start = VerseRef.checked(
      book: startResolution.match.selected.book,
      chapter: startChapter,
      verse: startVerse.verse,
      subdivision: startVerse.subdivision,
    );
    final end = VerseRef.checked(
      book: endBook,
      chapter: endChapter,
      verse: endVerse.verse,
      subdivision: endVerse.subdivision,
    );
    if (start.compareTo(end) >= 0) {
      final code = start.book == end.book
          ? ReferenceParseErrorCode.sameBookRangeNotAscending
          : ReferenceParseErrorCode.crossBookRangeNotAscending;
      throw ParseVerseRefError.typed(
        code: code,
        details: 'end reference must come after start reference',
      );
    }

    return _ParsedReference(
      VerseRangeRef.checked(start: start, end: end),
      _metadata(normalizedRef, matches),
    );
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
      );
}

final ReferenceParser _standardReferenceParser = ReferenceParser.standard;

final class _ParsedReference<T> {
  const _ParsedReference(this.value, this.metadata);

  final T value;
  final ReferenceParseMetadata metadata;
}

final _flexibleVerseRangeRefPattern = RegExp(
  r'^\s*(.+?)\s*(\d+)\s*[:.]\s*(\d+[a-zA-Z]?)\s*[-\u2013\u2014\u2015]\s*(.+?)\s*$',
);
final _sameChapterRangeEndPattern = RegExp(r'^(\d+[a-zA-Z]?)$');
final _crossChapterRangeEndPattern = RegExp(r'^(\d+)\s*[:.]\s*(\d+[a-zA-Z]?)$');
final _crossBookRangeEndPattern =
    RegExp(r'^(.+?)\s*(\d+)\s*[:.]\s*(\d+[a-zA-Z]?)$');
