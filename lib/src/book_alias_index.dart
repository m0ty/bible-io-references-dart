part of '../references.dart';

const _defaultAutoLanguagePrecedence = [
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

/// Auto language precedence.
final autoLanguagePrecedence = _defaultAutoLanguagePrecedence;

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
  for (final code in _defaultAutoLanguagePrecedence) {
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
