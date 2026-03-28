/// Supported languages for localized parsing.
enum BibleLanguageEnum {
  auto('Auto', 'auto', 'auto', ['all', 'global']),
  arabic('Arabic', 'ar', 'arb', []),
  chinese('Chinese', 'zh', 'zho', []),
  english('English', 'en', 'eng', []),
  esperanto('Esperanto', 'eo', 'epo', []),
  finnish('Finnish', 'fi', 'fin', []),
  french('French', 'fr', 'fra', []),
  german('German', 'de', 'deu', []),
  greek('Greek', 'el', 'ell', []),
  hebrew('Hebrew', 'he', 'heb', []),
  hindi('Hindi', 'hi', 'hin', []),
  indonesian('Indonesian', 'id', 'ind', []),
  korean('Korean', 'ko', 'kor', []),
  portuguese('Portuguese', 'pt', 'por', []),
  romanian('Romanian', 'ro', 'ron', []),
  russian('Russian', 'ru', 'rus', []),
  spanish('Spanish', 'es', 'spa', []),
  tagalog('Tagalog', 'tl', 'tgl', ['fil']),
  vietnamese('Vietnamese', 'vi', 'vie', []);

  const BibleLanguageEnum(
    this.displayName,
    this.code,
    this.identifierPrefix,
    this.aliases,
  );

  final String displayName;
  final String code;
  final String identifierPrefix;
  final List<String> aliases;

  List<String> get allAliases => [
        name.toLowerCase(),
        displayName.toLowerCase(),
        code.toLowerCase(),
        identifierPrefix.toLowerCase(),
        ...aliases,
      ];

  /// Create an enum member from a string.
  static BibleLanguageEnum fromStr(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('language must be a non-empty string');
    }
    final normalized = value.trim().toLowerCase();
    final identifierPrefix = normalized.split('-').first;
    for (final lang in values) {
      if (lang.allAliases.contains(normalized) ||
          lang.allAliases.contains(identifierPrefix)) {
        return lang;
      }
    }
    throw ArgumentError('unknown language: $value');
  }

  @override
  String toString() => displayName;
}