import '../bible_book_enum.dart';

const Map<BibleBookEnum, List<String>> portugueseBookNames = {
  BibleBookEnum.genesis: ["Gênesis", "Génesis", "Genesis"],
  BibleBookEnum.exodus: ["Êxodo", "Exodo"],
  BibleBookEnum.leviticus: ["Levítico", "Levitico"],
  BibleBookEnum.numbers: ["Números", "Numeros"],
  BibleBookEnum.deuteronomy: ["Deuteronômio", "Deuteronómio", "Deuteronomio"],

  BibleBookEnum.joshua: ["Josué", "Josue"],
  BibleBookEnum.judges: ["Juízes", "Juizes"],
  BibleBookEnum.ruth: ["Rute"],

  BibleBookEnum.firstSamuel: ["1 Samuel", "1º Samuel", "I Samuel", "Primeiro Samuel"],
  BibleBookEnum.secondSamuel: ["2 Samuel", "2º Samuel", "II Samuel", "Segundo Samuel"],

  BibleBookEnum.firstKings: ["1 Reis", "1º Reis", "I Reis", "Primeiro Reis"],
  BibleBookEnum.secondKings: ["2 Reis", "2º Reis", "II Reis", "Segundo Reis"],

  BibleBookEnum.firstChronicles: ["1 Crônicas", "1 Cronicas", "1º Crônicas", "I Crônicas"],
  BibleBookEnum.secondChronicles: ["2 Crônicas", "2 Cronicas", "2º Crônicas", "II Crônicas"],

  // Portuguese standard is Esdras; keep Ezra as permissive alias
  BibleBookEnum.ezra: ["Esdras", "Ezra"],
  BibleBookEnum.nehemiah: ["Neemias"],
  BibleBookEnum.esther: ["Ester", "Esther"],
  BibleBookEnum.job: ["Jó", "Job"],
  BibleBookEnum.psalms: ["Salmos"],
  BibleBookEnum.proverbs: ["Provérbios", "Proverbios"],
  BibleBookEnum.ecclesiastes: ["Eclesiastes", "Coélet", "Coelet"],
  BibleBookEnum.songOfSolomon: [
    "Cânticos", "Canticos",
    "Cântico dos Cânticos", "Cantico dos Canticos",
    "Cantares", "Cantares de Salomão", "Cantares de Salomao"
  ],

  BibleBookEnum.isaiah: ["Isaías", "Isaias"],
  BibleBookEnum.jeremiah: ["Jeremias"],
  BibleBookEnum.lamentations: ["Lamentações", "Lamentacoes"],
  BibleBookEnum.ezekiel: ["Ezequiel"],
  BibleBookEnum.daniel: ["Daniel"],

  // Portuguese standard is Oséias/Oseias
  BibleBookEnum.hosea: ["Oséias", "Oseias", "Oséias", "Oseias"],
  BibleBookEnum.joel: ["Joel"],
  BibleBookEnum.amos: ["Amós", "Amos"],
  BibleBookEnum.obadiah: ["Obadias", "Abdias"],
  BibleBookEnum.jonah: ["Jonas"],
  BibleBookEnum.micah: ["Miquéias", "Miqueias"],
  BibleBookEnum.nahum: ["Naum"],
  BibleBookEnum.habakkuk: ["Habacuque", "Habacuc"],
  BibleBookEnum.zephaniah: ["Sofonias"],
  BibleBookEnum.haggai: ["Ageu"],
  BibleBookEnum.zechariah: ["Zacarias"],
  BibleBookEnum.malachi: ["Malaquias"],

  BibleBookEnum.matthew: ["Mateus"],
  BibleBookEnum.mark: ["Marcos"],
  BibleBookEnum.luke: ["Lucas"],
  BibleBookEnum.john: ["João", "Joao"],
  BibleBookEnum.acts: ["Atos", "Atos dos Apóstolos", "Atos dos Apostolos"],
  BibleBookEnum.romans: ["Romanos"],
  BibleBookEnum.firstCorinthians: ["1 Coríntios", "1 Corintios"],
  BibleBookEnum.secondCorinthians: ["2 Coríntios", "2 Corintios"],
  BibleBookEnum.galatians: ["Gálatas", "Galatas"],
  BibleBookEnum.ephesians: ["Efésios", "Efesios"],
  BibleBookEnum.philippians: ["Filipenses"],
  BibleBookEnum.colossians: ["Colossenses"],
  BibleBookEnum.firstThessalonians: ["1 Tessalonicenses", "1º Tessalonicenses"],
  BibleBookEnum.secondThessalonians: ["2 Tessalonicenses", "2º Tessalonicenses"],
  BibleBookEnum.firstTimothy: ["1 Timóteo", "1 Timoteo"],
  BibleBookEnum.secondTimothy: ["2 Timóteo", "2 Timoteo"],
  BibleBookEnum.titus: ["Tito"],
  BibleBookEnum.philemon: ["Filemom", "Filemon", "Filêmon", "Filemón"],
  BibleBookEnum.hebrews: ["Hebreus"],
  BibleBookEnum.james: ["Tiago"],
  BibleBookEnum.firstPeter: ["1 Pedro", "1º Pedro"],
  BibleBookEnum.secondPeter: ["2 Pedro", "2º Pedro"],
  BibleBookEnum.firstJohn: ["1 João", "1 Joao", "1º João", "1º Joao"],
  BibleBookEnum.secondJohn: ["2 João", "2 Joao", "2º João", "2º Joao"],
  BibleBookEnum.thirdJohn: ["3 João", "3 Joao", "3º João", "3º Joao"],
  BibleBookEnum.jude: ["Judas"],
  BibleBookEnum.revelation: ["Apocalipse", "Apocalipse de João", "Apocalipse de Joao"],

  // Deuterocanon / Apocrypha (Portuguese Catholic usage)
  BibleBookEnum.tobit: ["Tobias"],
  BibleBookEnum.judith: ["Judite"],
  BibleBookEnum.wisdom: ["Sabedoria", "Sabedoria de Salomão", "Sabedoria de Salomao"],
  BibleBookEnum.sirach: ["Eclesiástico", "Eclesiastico", "Sirácida", "Siracida", "Ben Sira"],
  BibleBookEnum.baruch: ["Baruc", "Baruque"],
  BibleBookEnum.firstMaccabees: ["1 Macabeus", "1º Macabeus"],
  BibleBookEnum.secondMaccabees: ["2 Macabeus", "2º Macabeus"],

  // Additions / extras (more variable; keep explicit Portuguese labels + common descriptors)
  BibleBookEnum.estherAdditions: ["Ester (grego)", "Ester Grego", "Ester Gr"],
  BibleBookEnum.danielSongOfThree: ["Oração de Azarias", "Oracao de Azarias", "Cântico dos Três Jovens", "Cantico dos Tres Jovens"],
  BibleBookEnum.danielSusanna: ["Susana", "Suzana"],
  BibleBookEnum.danielBelAndTheDragon: ["Bel e o Dragão", "Bel e o Dragao"],
  BibleBookEnum.firstEsdras: ["1 Esdras", "Primeiro Esdras"],
  BibleBookEnum.secondEsdras: ["2 Esdras", "Segundo Esdras"],
  BibleBookEnum.prayerOfManasseh: ["Oração de Manassés", "Oracao de Manasses"],
  BibleBookEnum.psalm151: ["Salmo 151", "Salmos Adicionais"],
  BibleBookEnum.thirdMaccabees: ["3 Macabeus", "Terceiro Macabeus"],
  BibleBookEnum.fourthMaccabees: ["4 Macabeus", "Quarto Macabeus"],
};

const Map<BibleBookEnum, List<String>> portugueseBookAbbreviations = {
  // Pentateuch
  BibleBookEnum.genesis: ["Gn", "GN", "Gen", "GEN"],
  BibleBookEnum.exodus: ["Ex", "Êx", "EX", "EXO", "Exod"],
  BibleBookEnum.leviticus: ["Lv", "LV", "LEV", "Lev"],
  BibleBookEnum.numbers: ["Nm", "NM", "NUM", "Num"],
  BibleBookEnum.deuteronomy: ["Dt", "DT", "DEU", "Deut"],

  // OT history
  BibleBookEnum.joshua: ["Js", "JS", "JOS", "Jos"],
  BibleBookEnum.judges: ["Jz", "JZ", "JDG", "Jz"],
  BibleBookEnum.ruth: ["Rt", "RT", "RUT", "Rute"],

  BibleBookEnum.firstSamuel: ["1Sm", "1 Sm", "1SM", "1SA", "1Sam"],
  BibleBookEnum.secondSamuel: ["2Sm", "2 Sm", "2SM", "2SA", "2Sam"],
  BibleBookEnum.firstKings: ["1Rs", "1 Rs", "1RS", "1KI", "1Kgs"],
  BibleBookEnum.secondKings: ["2Rs", "2 Rs", "2RS", "2KI", "2Kgs"],
  BibleBookEnum.firstChronicles: ["1Cr", "1 Cr", "1CR", "1CH", "1Chr"],
  BibleBookEnum.secondChronicles: ["2Cr", "2 Cr", "2CR", "2CH", "2Chr"],

  // Ezra/Esther/Job: common Portuguese abbreviations are Esd/Est/Jó; also allow Jb for Job (pt-PT Catholic)
  BibleBookEnum.ezra: ["Esd", "Ed", "EZR", "Ezr"],
  BibleBookEnum.nehemiah: ["Ne", "NE", "NEH", "Neh"],
  BibleBookEnum.esther: ["Est", "Et", "EST", "Esth"],
  BibleBookEnum.job: ["Jó", "Jb", "JOB", "Job"],

  // Wisdom
  BibleBookEnum.psalms: ["Sl", "SL", "Ps", "PSA", "Psa"],
  BibleBookEnum.proverbs: ["Pr", "Pv", "PR", "PRO", "Prov"],
  BibleBookEnum.ecclesiastes: ["Ecl", "Ec", "Co", "ECC", "Eccl"],
  BibleBookEnum.songOfSolomon: ["Ct", "CT", "Cant", "SNG", "Song"],

  // Prophets
  BibleBookEnum.isaiah: ["Is", "IS", "ISA", "Isa"],
  BibleBookEnum.jeremiah: ["Jr", "JR", "JER", "Jer"],
  BibleBookEnum.lamentations: ["Lm", "LM", "LAM", "Lam"],
  BibleBookEnum.ezekiel: ["Ez", "EZ", "EZK", "Ezek"],
  BibleBookEnum.daniel: ["Dn", "DN", "DAN", "Dan"],
  BibleBookEnum.hosea: ["Os", "OS", "HOS", "Hos"],
  BibleBookEnum.joel: ["Jl", "JL", "JOL", "Joel"],
  BibleBookEnum.amos: ["Am", "AM", "AMO", "Amos"],
  BibleBookEnum.obadiah: ["Ab", "Abd", "OB", "OBA", "Obad"],
  BibleBookEnum.jonah: ["Jn", "JON", "Jon"],
  BibleBookEnum.micah: ["Mq", "MQ", "MIC", "Mic"],
  BibleBookEnum.nahum: ["Na", "NA", "NAM", "Nah"],
  BibleBookEnum.habakkuk: ["Hab", "Hc", "HAB", "Hab"],
  BibleBookEnum.zephaniah: ["Sf", "SF", "ZEP", "Zeph"],
  BibleBookEnum.haggai: ["Ag", "AG", "HAG", "Hag"],
  BibleBookEnum.zechariah: ["Zc", "ZC", "ZEC", "Zech"],
  BibleBookEnum.malachi: ["Ml", "ML", "MAL", "Mal"],

  // Gospels & Acts
  BibleBookEnum.matthew: ["Mt", "MT", "MAT", "Matt"],
  BibleBookEnum.mark: ["Mc", "MC", "MRK", "Mark"],
  BibleBookEnum.luke: ["Lc", "LC", "LUK", "Luke"],
  BibleBookEnum.john: ["Jo", "JO", "JHN", "John"],

  BibleBookEnum.acts: ["At", "AT", "ACT", "Acts"],
  BibleBookEnum.romans: ["Rm", "RM", "ROM", "Rom"],
  BibleBookEnum.firstCorinthians: ["1Cor", "1 Cor", "1Co", "1CO", "1Cor"],
  BibleBookEnum.secondCorinthians: ["2Cor", "2 Cor", "2Co", "2CO", "2Cor"],
  BibleBookEnum.galatians: ["Gl", "GL", "GAL", "Gal"],
  BibleBookEnum.ephesians: ["Ef", "EF", "EPH", "Eph"],
  BibleBookEnum.philippians: ["Fl", "Flp", "FL", "PHP", "Phil"],
  BibleBookEnum.colossians: ["Cl", "CL", "COL", "Col"],
  BibleBookEnum.firstThessalonians: ["1Ts", "1 Ts", "1TH", "1Thess"],
  BibleBookEnum.secondThessalonians: ["2Ts", "2 Ts", "2TH", "2Thess"],
  BibleBookEnum.firstTimothy: ["1Tm", "1 Tm", "1TI", "1Tim"],
  BibleBookEnum.secondTimothy: ["2Tm", "2 Tm", "2TI", "2Tim"],
  BibleBookEnum.titus: ["Tt", "TT", "TIT", "Tit"],
  BibleBookEnum.philemon: ["Fm", "Flm", "PHM", "Phlm"],
  BibleBookEnum.hebrews: ["Hb", "Heb", "HEB", "Heb"],
  BibleBookEnum.james: ["Tg", "TG", "JAS", "Jas"],
  BibleBookEnum.firstPeter: ["1Pd", "1 Pd", "1PE", "1Pet"],
  BibleBookEnum.secondPeter: ["2Pd", "2 Pd", "2PE", "2Pet"],
  BibleBookEnum.firstJohn: ["1Jo", "1 Jo", "1JN", "1John"],
  BibleBookEnum.secondJohn: ["2Jo", "2 Jo", "2JN", "2John"],
  BibleBookEnum.thirdJohn: ["3Jo", "3 Jo", "3JN", "3John"],
  BibleBookEnum.jude: ["Jd", "JD", "JUD", "Jude"],
  BibleBookEnum.revelation: ["Ap", "Apo", "Apoc", "REV", "Rev"],

  // Deuterocanon (Portuguese Catholic conventions + tooling)
  BibleBookEnum.tobit: ["Tb", "TB", "TOB", "Tob"],
  BibleBookEnum.judith: ["Jt", "Jdt", "JDT", "Jdt"],
  BibleBookEnum.wisdom: ["Sb", "SB", "WIS", "Wis"],
  BibleBookEnum.sirach: ["Eclo", "Sir", "SIR", "Sir"],
  BibleBookEnum.baruch: ["Br", "BR", "BAR", "Bar"],
  BibleBookEnum.firstMaccabees: ["1Mc", "1Mac", "1 Mac", "1MA", "1Macc"],
  BibleBookEnum.secondMaccabees: ["2Mc", "2Mac", "2 Mac", "2MA", "2Macc"],

  // Additions / extras (prefer stable IDs + attested Portuguese labels)
  BibleBookEnum.estherAdditions: ["Est Gr", "Ester Gr", "ESG", "EsthGr"],
  BibleBookEnum.danielSongOfThree: ["PrAzar", "S3Y"],
  BibleBookEnum.danielSusanna: ["Sus", "SUS"],
  BibleBookEnum.danielBelAndTheDragon: ["Bel", "BEL"],

  BibleBookEnum.firstEsdras: ["1Esd", "1ES"],
  BibleBookEnum.secondEsdras: ["2Esd", "2ES"],
  BibleBookEnum.prayerOfManasseh: ["PrMan", "MAN"],
  BibleBookEnum.psalm151: ["Sl Adc", "AddPs", "PS2", "Ps151"],
  BibleBookEnum.thirdMaccabees: ["3Mac", "3Macc", "3MA"],
  BibleBookEnum.fourthMaccabees: ["4Mac", "4Macc", "4MA"],
};