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

  /// The original book token, trimmed but otherwise unchanged.
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
}

/// Metadata captured while a reference is parsed successfully.
final class ReferenceParseMetadata {
  ReferenceParseMetadata({
    required this.normalizedInput,
    Iterable<ReferenceBookTokenMatch> bookMatches = const [],
  }) : bookMatches = List.unmodifiable(bookMatches);

  const ReferenceParseMetadata._({
    required this.normalizedInput,
    required this.bookMatches,
  });

  /// Empty metadata used by manually-created [ParseSuccess] values.
  static const empty = ReferenceParseMetadata._(
    normalizedInput: '',
    bookMatches: <ReferenceBookTokenMatch>[],
  );

  /// The trimmed, whitespace-normalized source text.
  final String normalizedInput;

  /// Matches for each explicit book token in source order.
  final List<ReferenceBookTokenMatch> bookMatches;

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
      };
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
    _ensureReferenceIsNotEmpty(ref);
    if (_verseRangeRefPattern.hasMatch(ref)) {
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
    _ensureReferenceIsNotEmpty(ref);
    _validateLanguage(language);
    final match = _verseRefPattern.firstMatch(ref);
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
    return _ParsedReference(
      value,
      _metadata(ref, [resolution.match]),
    );
  }

  _ParsedReference<VerseRangeRef> _parseRange(
    String ref, {
    BibleLanguageEnum? language,
  }) {
    _ensureReferenceIsNotEmpty(ref);
    _validateLanguage(language);
    final match = _verseRangeRefPattern.firstMatch(ref);
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
    final endVerse = _parseReferenceNumber(
      match.group(6)!,
      component: 'end verse',
      maximum: maxReferenceVerseNumber,
    );
    final endChapterToken = match.group(5);
    final endChapter = endChapterToken == null
        ? startChapter
        : _parseReferenceNumber(
            endChapterToken,
            component: 'end chapter',
            maximum: maxReferenceChapterNumber,
          );

    final startResolution = _resolveBook(match.group(1)!, language: language);
    final matches = <ReferenceBookTokenMatch>[startResolution.match];
    final endBookToken = match.group(4);
    final BibleBookEnum endBook;
    if (endBookToken == null) {
      endBook = startResolution.match.selected.book;
    } else {
      final endResolution = _resolveBook(endBookToken, language: language);
      endBook = endResolution.match.selected.book;
      matches.add(endResolution.match);
    }

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
      _metadata(ref, matches),
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

final class _BookResolution {
  const _BookResolution(this.match);

  final ReferenceBookTokenMatch match;
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
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

Set<String> _parserAliasKeys(String normalized) {
  final withoutPeriods = normalized.replaceAll('.', '');
  return {
    normalized,
    withoutPeriods,
    withoutPeriods.replaceAll(' ', ''),
  };
}
