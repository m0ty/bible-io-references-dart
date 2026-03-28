/// Enumeration of all Bible books with standardized abbreviations and full names.
///
/// This enum includes books from the Protestant canon (66 books), Catholic deuterocanonical
/// books, and Eastern Orthodox additional books. Each book has a unique short abbreviation
/// and a canonical full name.
///
/// The enum values use camelCase naming following Dart conventions, while the abbreviations
/// and full names follow common Biblical conventions.
///
/// Example:
/// ```dart
/// final john = BibleBookEnum.john;
/// print(john.fullName); // "John"
/// print(john.asStr()); // "jo"
///
/// // Parse from abbreviation
/// final book = BibleBookEnum.fromStr("mt"); // BibleBookEnum.matthew
/// ```
enum BibleBookEnum {
  // --- Protestant Canon (66 books) ---

  /// Genesis - First book of the Pentateuch
  genesis('gn', 'Genesis'),

  /// Exodus - Second book of the Pentateuch
  exodus('ex', 'Exodus'),

  /// Leviticus - Third book of the Pentateuch
  leviticus('lv', 'Leviticus'),

  /// Numbers - Fourth book of the Pentateuch
  numbers('nm', 'Numbers'),

  /// Deuteronomy - Fifth and final book of the Pentateuch
  deuteronomy('dt', 'Deuteronomy'),

  /// Joshua - First book of the Historical books
  joshua('js', 'Joshua'),

  /// Judges - Book of the Judges
  judges('jud', 'Judges'),

  /// Ruth - Book of Ruth
  ruth('rt', 'Ruth'),

  /// 1 Samuel - First book of Samuel
  firstSamuel('1sm', '1 Samuel'),

  /// 2 Samuel - Second book of Samuel
  secondSamuel('2sm', '2 Samuel'),

  /// 1 Kings - First book of Kings
  firstKings('1kgs', '1 Kings'),

  /// 2 Kings - Second book of Kings
  secondKings('2kgs', '2 Kings'),

  /// 1 Chronicles - First book of Chronicles
  firstChronicles('1ch', '1 Chronicles'),

  /// 2 Chronicles - Second book of Chronicles
  secondChronicles('2ch', '2 Chronicles'),

  /// Ezra - Book of Ezra
  ezra('ezr', 'Ezra'),

  /// Nehemiah - Book of Nehemiah
  nehemiah('ne', 'Nehemiah'),

  /// Esther - Book of Esther
  esther('et', 'Esther'),

  /// Job - Book of Job
  job('job', 'Job'),

  /// Psalms - Book of Psalms
  psalms('ps', 'Psalms'),

  /// Proverbs - Book of Proverbs
  proverbs('prv', 'Proverbs'),

  /// Ecclesiastes - Book of Ecclesiastes
  ecclesiastes('ec', 'Ecclesiastes'),

  /// Song of Solomon - Song of Solomon (also called Song of Songs)
  songOfSolomon('so', 'Song of Solomon'),

  /// Isaiah - Book of Isaiah
  isaiah('is', 'Isaiah'),

  /// Jeremiah - Book of Jeremiah
  jeremiah('jr', 'Jeremiah'),

  /// Lamentations - Book of Lamentations
  lamentations('lm', 'Lamentations'),

  /// Ezekiel - Book of Ezekiel
  ezekiel('ez', 'Ezekiel'),

  /// Daniel - Book of Daniel
  daniel('dn', 'Daniel'),

  /// Hosea - Book of Hosea
  hosea('ho', 'Hosea'),

  /// Joel - Book of Joel
  joel('jl', 'Joel'),

  /// Amos - Book of Amos
  amos('am', 'Amos'),

  /// Obadiah - Book of Obadiah
  obadiah('ob', 'Obadiah'),

  /// Jonah - Book of Jonah
  jonah('jn', 'Jonah'),

  /// Micah - Book of Micah
  micah('mi', 'Micah'),

  /// Nahum - Book of Nahum
  nahum('na', 'Nahum'),

  /// Habakkuk - Book of Habakkuk
  habakkuk('hk', 'Habakkuk'),

  /// Zephaniah - Book of Zephaniah
  zephaniah('zp', 'Zephaniah'),

  /// Haggai - Book of Haggai
  haggai('hg', 'Haggai'),

  /// Zechariah - Book of Zechariah
  zechariah('zc', 'Zechariah'),

  /// Malachi - Book of Malachi
  malachi('ml', 'Malachi'),

  /// Matthew - Gospel of Matthew
  matthew('mt', 'Matthew'),

  /// Mark - Gospel of Mark
  mark('mk', 'Mark'),

  /// Luke - Gospel of Luke
  luke('lk', 'Luke'),

  /// John - Gospel of John
  john('jo', 'John'),

  /// Acts - Acts of the Apostles
  acts('act', 'Acts'),

  /// Romans - Epistle to the Romans
  romans('rm', 'Romans'),

  /// 1 Corinthians - First Epistle to the Corinthians
  firstCorinthians('1co', '1 Corinthians'),

  /// 2 Corinthians - Second Epistle to the Corinthians
  secondCorinthians('2co', '2 Corinthians'),
  galatians('gl', 'Galatians'),
  ephesians('eph', 'Ephesians'),
  philippians('ph', 'Philippians'),
  colossians('cl', 'Colossians'),
  firstThessalonians('1ts', '1 Thessalonians'),
  secondThessalonians('2ts', '2 Thessalonians'),
  firstTimothy('1tm', '1 Timothy'),
  secondTimothy('2tm', '2 Timothy'),
  titus('tt', 'Titus'),
  philemon('phm', 'Philemon'),
  hebrews('hb', 'Hebrews'),
  james('jm', 'James'),
  firstPeter('1pe', '1 Peter'),
  secondPeter('2pe', '2 Peter'),
  firstJohn('1jo', '1 John'),
  secondJohn('2jo', '2 John'),
  thirdJohn('3jo', '3 John'),
  jude('jd', 'Jude'),
  revelation('re', 'Revelation'),

  // --- Catholic Deuterocanon ---
  tobit('tb', 'Tobit'),
  judith('jdt', 'Judith'),
  wisdom('ws', 'Wisdom'),
  sirach('sir', 'Sirach'),
  baruch('bar', 'Baruch'),
  firstMaccabees('1mc', '1 Maccabees'),
  secondMaccabees('2mc', '2 Maccabees'),
  estherAdditions('etg', 'Esther (Greek)'),
  danielSongOfThree('dn3', 'Daniel (Song of Three)'),
  danielSusanna('dns', 'Daniel (Susanna)'),
  danielBelAndTheDragon('dnb', 'Daniel (Bel and the Dragon)'),

  // --- Eastern Orthodox Additions (Anagignoskomena) ---
  firstEsdras('1es', '1 Esdras'),
  secondEsdras('2es', '2 Esdras'),
  prayerOfManasseh('pmn', 'Prayer of Manasseh'),
  psalm151('ps151', 'Psalm 151'),
  thirdMaccabees('3mc', '3 Maccabees'),
  fourthMaccabees('4mc', '4 Maccabees');

  const BibleBookEnum(this.abbreviation, this.fullName);

  /// The short abbreviation for this book (e.g., "gn", "mt", "jo").
  final String abbreviation;

  /// The full canonical name for this book (e.g., "Genesis", "Matthew", "John").
  final String fullName;

  /// Returns the compact abbreviation for this Bible book.
  ///
  /// This is the same as [abbreviation] and is provided for API consistency
  /// with the original Python implementation.
  ///
  /// Example:
  /// ```dart
  /// final john = BibleBookEnum.john;
  /// print(john.asStr()); // "jo"
  /// ```
  String asStr() => abbreviation;

  /// Creates a BibleBookEnum instance from its abbreviation string.
  ///
  /// The parsing is case-insensitive. Common abbreviations include:
  /// - "gn" → Genesis
  /// - "mt" → Matthew
  /// - "jo" → John
  /// - "rm" → Romans
  /// - "re" → Revelation
  ///
  /// Parameters:
  /// - [s]: The abbreviation string to parse
  ///
  /// Returns: The corresponding [BibleBookEnum] value
  ///
  /// Throws: [ParseBibleBookError] if the abbreviation is not recognized
  ///
  /// Example:
  /// ```dart
  /// final genesis = BibleBookEnum.fromStr("gn");
  /// final matthew = BibleBookEnum.fromStr("MT"); // case insensitive
  /// ```
  static BibleBookEnum fromStr(String s) {
    if (s.isEmpty) {
      throw ParseBibleBookError();
    }
    final key = s.toLowerCase();
    final book = _abbrToBook[key];
    if (book == null) {
      throw ParseBibleBookError();
    }
    return book;
  }

  @override
  String toString() => abbreviation;
}

// Build a fast lookup (once) after the Enum is defined
final Map<String, BibleBookEnum> _abbrToBook = {
  for (final book in BibleBookEnum.values) book.abbreviation: book,
};

/// Error raised when parsing an unknown or unsupported Bible book abbreviation.
///
/// This error is thrown by [BibleBookEnum.fromStr] when the provided abbreviation
/// string does not correspond to any known Bible book.
///
/// Example:
/// ```dart
/// try {
///   final book = BibleBookEnum.fromStr("xyz");
/// } on ParseBibleBookError {
///   print("Unknown book abbreviation");
/// }
/// ```
class ParseBibleBookError extends Error {
  @override
  String toString() => 'invalid Bible book abbreviation';
}