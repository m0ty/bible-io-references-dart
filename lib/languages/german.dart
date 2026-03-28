import '../bible_book_enum.dart';

const Map<BibleBookEnum, List<String>> germanBookNames = {
  // Pentateuch
  BibleBookEnum.genesis: ["1. Mose", "Genesis", "1 Mose"],
  BibleBookEnum.exodus: ["2. Mose", "Exodus", "2 Mose"],
  BibleBookEnum.leviticus: ["3. Mose", "Levitikus", "3 Mose"],
  BibleBookEnum.numbers: ["4. Mose", "Numeri", "4 Mose"],
  BibleBookEnum.deuteronomy: ["5. Mose", "Deuteronomium", "5 Mose"],

  BibleBookEnum.joshua: ["Josua"],
  BibleBookEnum.judges: ["Richter"],
  BibleBookEnum.ruth: ["Ruth"],

  BibleBookEnum.firstSamuel: ["1. Samuel", "1 Samuel"],
  BibleBookEnum.secondSamuel: ["2. Samuel", "2 Samuel"],

  BibleBookEnum.firstKings: ["1. Könige", "1 Könige"],
  BibleBookEnum.secondKings: ["2. Könige", "2 Könige"],

  BibleBookEnum.firstChronicles: ["1. Chronik", "1 Chronik"],
  BibleBookEnum.secondChronicles: ["2. Chronik", "2 Chronik"],

  BibleBookEnum.ezra: ["Esra"],
  BibleBookEnum.nehemiah: ["Nehemia"],
  BibleBookEnum.esther: ["Esther"],

  BibleBookEnum.job: ["Hiob", "Ijob"],
  BibleBookEnum.psalms: ["Psalmen", "Psalm"],
  BibleBookEnum.proverbs: ["Sprüche", "Sprüche Salomos"],
  BibleBookEnum.ecclesiastes: ["Prediger", "Kohelet"],
  BibleBookEnum.songOfSolomon: ["Hohelied", "Hoheslied", "Hohelied Salomos"],

  BibleBookEnum.isaiah: ["Jesaja"],
  BibleBookEnum.jeremiah: ["Jeremia"],
  BibleBookEnum.lamentations: ["Klagelieder"],
  BibleBookEnum.ezekiel: ["Hesekiel", "Ezechiel"],
  BibleBookEnum.daniel: ["Daniel"],

  BibleBookEnum.hosea: ["Hosea"],
  BibleBookEnum.joel: ["Joel", "Joël"],
  BibleBookEnum.amos: ["Amos"],
  BibleBookEnum.obadiah: ["Obadja"],
  BibleBookEnum.jonah: ["Jona"],
  BibleBookEnum.micah: ["Micha"],
  BibleBookEnum.nahum: ["Nahum"],
  BibleBookEnum.habakkuk: ["Habakuk"],
  BibleBookEnum.zephaniah: ["Zefanja"],
  BibleBookEnum.haggai: ["Haggai"],
  BibleBookEnum.zechariah: ["Sacharja"],
  BibleBookEnum.malachi: ["Maleachi"],

  // NT
  BibleBookEnum.matthew: ["Matthäus"],
  BibleBookEnum.mark: ["Markus"],
  BibleBookEnum.luke: ["Lukas"],
  BibleBookEnum.john: ["Johannes"],

  BibleBookEnum.acts: ["Apostelgeschichte"],
  BibleBookEnum.romans: ["Römer", "Römerbrief"],

  BibleBookEnum.firstCorinthians: ["1. Korinther", "1 Korinther"],
  BibleBookEnum.secondCorinthians: ["2. Korinther", "2 Korinther"],
  BibleBookEnum.galatians: ["Galater", "Galaterbrief"],
  BibleBookEnum.ephesians: ["Epheser", "Epheserbrief"],
  BibleBookEnum.philippians: ["Philipper", "Philipperbrief"],
  BibleBookEnum.colossians: ["Kolosser", "Kolosserbrief"],

  BibleBookEnum.firstThessalonians: ["1. Thessalonicher", "1 Thessalonicher"],
  BibleBookEnum.secondThessalonians: ["2. Thessalonicher", "2 Thessalonicher"],
  BibleBookEnum.firstTimothy: ["1. Timotheus", "1 Timotheus"],
  BibleBookEnum.secondTimothy: ["2. Timotheus", "2 Timotheus"],
  BibleBookEnum.titus: ["Titus"],
  BibleBookEnum.philemon: ["Philemon"],
  BibleBookEnum.hebrews: ["Hebräer", "Hebräerbrief"],
  BibleBookEnum.james: ["Jakobus"],
  BibleBookEnum.firstPeter: ["1. Petrus", "1 Petrus"],
  BibleBookEnum.secondPeter: ["2. Petrus", "2 Petrus"],
  BibleBookEnum.firstJohn: ["1. Johannes", "1 Johannes"],
  BibleBookEnum.secondJohn: ["2. Johannes", "2 Johannes"],
  BibleBookEnum.thirdJohn: ["3. Johannes", "3 Johannes"],
  BibleBookEnum.jude: ["Judas"],
  BibleBookEnum.revelation: ["Offenbarung", "Offenbarung des Johannes"],

  // Deuterocanon / Additions
  BibleBookEnum.tobit: ["Tobias", "Tobit"],
  BibleBookEnum.judith: ["Judith"],
  BibleBookEnum.wisdom: ["Weisheit", "Weisheit Salomos"],
  BibleBookEnum.sirach: ["Jesus Sirach", "Sirach"],
  BibleBookEnum.baruch: ["Baruch"],
  BibleBookEnum.firstMaccabees: ["1. Makkabäer", "1 Makkabäer"],
  BibleBookEnum.secondMaccabees: ["2. Makkabäer", "2 Makkabäer"],
  BibleBookEnum.thirdMaccabees: ["3. Makkabäer", "3 Makkabäer"],
  BibleBookEnum.fourthMaccabees: ["4. Makkabäer", "4 Makkabäer"],

  BibleBookEnum.estherAdditions: ["Zusätze zu Esther", "Esther (Zusätze)"],
  BibleBookEnum.danielSongOfThree: ["Gebet Asarjas", "Gesang der drei Männer"],
  BibleBookEnum.danielSusanna: ["Susanna", "Susanna und Daniel", "Geschichte von Susanna und Daniel"],
  BibleBookEnum.danielBelAndTheDragon: ["Bel und Drache", "Bel und der Drache"],

  // Names vary strongly in German traditions; include both neutral + explanatory variants
  BibleBookEnum.firstEsdras: ["1 Esdras", "1. Esdras", "Esra (griechische Ergänzung)", "3. Esra", "3 Esra"],
  BibleBookEnum.secondEsdras: ["2 Esdras", "2. Esdras", "Esra (lateinische Ergänzung)", "4. Esra", "4 Esra"],

  BibleBookEnum.prayerOfManasseh: ["Gebet des Manasse", "Gebet Manasses", "Gebet Manesses"],
  BibleBookEnum.psalm151: ["Psalm 151"],
};

const Map<BibleBookEnum, List<String>> germanBookAbbreviations = {
  // Pentateuch (German practice: Gen/Ex/Lev/Num/Dtn; also common 1Mo/2Mo… forms)
  BibleBookEnum.genesis: ["Gen", "gen", "GEN", "1Mo", "1 Mo", "1.Mo", "1 Mose", "1. Mose"],
  BibleBookEnum.exodus: ["Ex", "ex", "EXO", "2Mo", "2 Mo", "2.Mo", "2 Mose", "2. Mose"],
  BibleBookEnum.leviticus: ["Lev", "lev", "LEV", "3Mo", "3 Mo", "3.Mo", "3 Mose", "3. Mose"],
  BibleBookEnum.numbers: ["Num", "num", "NUM", "4Mo", "4 Mo", "4.Mo", "4 Mose", "4. Mose"],
  BibleBookEnum.deuteronomy: ["Dtn", "dtn", "DEU", "5Mo", "5 Mo", "5.Mo", "5 Mose", "5. Mose"],

  BibleBookEnum.joshua: ["Jos", "jos", "JOS"],
  BibleBookEnum.judges: ["Ri", "ri", "JDG"],
  BibleBookEnum.ruth: ["Rut", "rut", "RUT", "Rt", "rt"],

  BibleBookEnum.firstSamuel: ["1Sam", "1 Sam", "1. Sam", "1SA"],
  BibleBookEnum.secondSamuel: ["2Sam", "2 Sam", "2. Sam", "2SA"],

  BibleBookEnum.firstKings: ["1Kön", "1 Kön", "1Koen", "1 Koen", "1KI"],
  BibleBookEnum.secondKings: ["2Kön", "2 Kön", "2Koen", "2 Koen", "2KI"],

  BibleBookEnum.firstChronicles: ["1Chr", "1 Chr", "1CH"],
  BibleBookEnum.secondChronicles: ["2Chr", "2 Chr", "2CH"],

  BibleBookEnum.ezra: ["Esra", "esra", "EZR", "Esr", "esr"],
  BibleBookEnum.nehemiah: ["Neh", "neh", "NEH"],
  BibleBookEnum.esther: ["Est", "est", "EST"],

  BibleBookEnum.job: ["Hi", "hi", "Hiob", "Ijob", "JOB"],
  BibleBookEnum.psalms: ["Ps", "ps", "PSA"],
  BibleBookEnum.proverbs: ["Spr", "spr", "PRO"],
  BibleBookEnum.ecclesiastes: ["Pred", "pred", "Koh", "koh", "ECC"],
  BibleBookEnum.songOfSolomon: ["Hld", "hld", "SNG", "Hhld", "hhld"],

  BibleBookEnum.isaiah: ["Jes", "jes", "ISA"],
  BibleBookEnum.jeremiah: ["Jer", "jer", "JER"],
  BibleBookEnum.lamentations: ["Klgl", "klgl", "LAM", "Klg", "klg"],
  BibleBookEnum.ezekiel: ["Hes", "hes", "Ez", "ez", "EZK"],
  BibleBookEnum.daniel: ["Dan", "dan", "DAN"],

  BibleBookEnum.hosea: ["Hos", "hos", "HOS"],
  BibleBookEnum.joel: ["Joel", "joel", "Joël", "joël", "JOL"],
  BibleBookEnum.amos: ["Am", "am", "AMO"],
  BibleBookEnum.obadiah: ["Obd", "obd", "OBA"],
  BibleBookEnum.jonah: ["Jona", "jona", "Jon", "jon", "JON"],
  BibleBookEnum.micah: ["Mi", "mi", "MIC"],
  BibleBookEnum.nahum: ["Nah", "nah", "NAM"],
  BibleBookEnum.habakkuk: ["Hab", "hab", "HAB"],
  BibleBookEnum.zephaniah: ["Zef", "zef", "ZEP"],
  BibleBookEnum.haggai: ["Hag", "hag", "HAG"],
  BibleBookEnum.zechariah: ["Sach", "sach", "ZEC"],
  BibleBookEnum.malachi: ["Mal", "mal", "MAL"],

  // NT
  BibleBookEnum.matthew: ["Mt", "mt", "MAT"],
  BibleBookEnum.mark: ["Mk", "mk", "MRK"],
  BibleBookEnum.luke: ["Lk", "lk", "LUK"],
  BibleBookEnum.john: ["Joh", "joh", "JHN"],

  BibleBookEnum.acts: ["Apg", "apg", "ACT"],
  BibleBookEnum.romans: ["Röm", "röm", "Roem", "roem", "ROM"],

  BibleBookEnum.firstCorinthians: ["1Kor", "1 Kor", "1. Kor", "1CO"],
  BibleBookEnum.secondCorinthians: ["2Kor", "2 Kor", "2. Kor", "2CO"],
  BibleBookEnum.galatians: ["Gal", "gal", "GAL"],
  BibleBookEnum.ephesians: ["Eph", "eph", "EPH"],
  BibleBookEnum.philippians: ["Phil", "phil", "PHP", "Php", "php"],
  BibleBookEnum.colossians: ["Kol", "kol", "COL"],

  BibleBookEnum.firstThessalonians: ["1Thess", "1 Thess", "1. Thess", "1TH"],
  BibleBookEnum.secondThessalonians: ["2Thess", "2 Thess", "2. Thess", "2TH"],
  BibleBookEnum.firstTimothy: ["1Tim", "1 Tim", "1. Tim", "1TI"],
  BibleBookEnum.secondTimothy: ["2Tim", "2 Tim", "2. Tim", "2TI"],
  BibleBookEnum.titus: ["Tit", "tit", "TIT"],
  BibleBookEnum.philemon: ["Phlm", "phlm", "PHM"],
  BibleBookEnum.hebrews: ["Hebr", "hebr", "HEB"],
  BibleBookEnum.james: ["Jak", "jak", "JAS"],
  BibleBookEnum.firstPeter: ["1Petr", "1 Petr", "1. Petr", "1PE"],
  BibleBookEnum.secondPeter: ["2Petr", "2 Petr", "2. Petr", "2PE"],
  BibleBookEnum.firstJohn: ["1Joh", "1 Joh", "1. Joh", "1JN"],
  BibleBookEnum.secondJohn: ["2Joh", "2 Joh", "2. Joh", "2JN"],
  BibleBookEnum.thirdJohn: ["3Joh", "3 Joh", "3. Joh", "3JN"],
  BibleBookEnum.jude: ["Jud", "jud", "JUD"],
  BibleBookEnum.revelation: ["Offb", "offb", "REV"],

  // Deuterocanon / Additions (German: Tb/Jdt/Weish/Sir/Bar; plus USFM/OSIS IDs)
  BibleBookEnum.tobit: ["Tob", "tob", "TOB", "Tobit", "Tobias"],
  BibleBookEnum.judith: ["Jdt", "jdt", "JDT"],
  BibleBookEnum.wisdom: ["Weish", "weish", "WIS", "Weis", "weis"],
  BibleBookEnum.sirach: ["Sir", "sir", "SIR"],
  BibleBookEnum.baruch: ["Bar", "bar", "BAR"],
  BibleBookEnum.firstMaccabees: ["1Makk", "1 Makk", "1. Makk", "1MA"],
  BibleBookEnum.secondMaccabees: ["2Makk", "2 Makk", "2. Makk", "2MA"],
  BibleBookEnum.thirdMaccabees: ["3Makk", "3 Makk", "3. Makk", "3MA", "3Macc", "3macc"],
  BibleBookEnum.fourthMaccabees: ["4Makk", "4 Makk", "4. Makk", "4MA", "4Macc", "4macc"],

  BibleBookEnum.estherAdditions: ["St zu Est", "StzuEst", "EstZ", "estz", "ESG", "EsthGr", "esthgr"],
  BibleBookEnum.danielSongOfThree: ["S3Y", "PrAzar", "prazar", "Gesang der drei Männer", "Gebet Asarjas"],
  BibleBookEnum.danielSusanna: ["Sus", "sus", "SUS", "Susanna"],
  BibleBookEnum.danielBelAndTheDragon: ["Bel", "bel", "BEL", "Bel und Drache"],

  BibleBookEnum.firstEsdras: ["1ES", "1Esd", "1esd", "1 Esd", "3Esra", "3 Esra"],
  BibleBookEnum.secondEsdras: ["2ES", "2Esd", "2esd", "2 Esd", "4Esra", "4 Esra"],

  BibleBookEnum.prayerOfManasseh: ["Geb.Man", "GebMan", "MAN", "PrMan", "prman"],
  BibleBookEnum.psalm151: ["Ps151", "ps151", "PS2", "AddPs", "addps"],
};