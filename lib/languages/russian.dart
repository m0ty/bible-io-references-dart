import '../bible_book_enum.dart';

const Map<BibleBookEnum, List<String>> russianBookNames = {
  // Torah / Pentateuch
  BibleBookEnum.genesis: ["Бытие", "Книга Бытия"],
  BibleBookEnum.exodus: ["Исход", "Книга Исход"],
  BibleBookEnum.leviticus: ["Левит", "Книга Левит"],
  BibleBookEnum.numbers: ["Числа", "Книга Чисел"],
  BibleBookEnum.deuteronomy: ["Второзаконие"],

  // Historical
  BibleBookEnum.joshua: ["Иисус Навин", "Книга Иисуса Навина"],
  BibleBookEnum.judges: ["Судьи", "Книга Судей", "Книга Судей Израилевых"],
  BibleBookEnum.ruth: ["Руфь", "Книга Руфи"],

  // Russian/Synodal practice also uses 1–4 Царств for Samuel+Kings
  BibleBookEnum.firstSamuel: ["1 Самуила", "1-я книга Самуила", "1 Царств", "Первая книга Царств"],
  BibleBookEnum.secondSamuel: ["2 Самуила", "2-я книга Самуила", "2 Царств", "Вторая книга Царств"],
  BibleBookEnum.firstKings: ["1 Царей", "3 Царств", "Третья книга Царств"],
  BibleBookEnum.secondKings: ["2 Царей", "4 Царств", "Четвертая книга Царств", "Четвёртая книга Царств"],

  BibleBookEnum.firstChronicles: [
    "1 Паралипоменон", "Первая книга Паралипоменон",
    "1 Хроник", "Первая книга Хроник"
  ],
  BibleBookEnum.secondChronicles: [
    "2 Паралипоменон", "Вторая книга Паралипоменон",
    "2 Хроник", "Вторая книга Хроник"
  ],

  // Ezra/Nehemiah/Esdras numbering in Russian Orthodox/Synodal tables:
  // canonical Ezra = 1 Ездры; apocryphal = 2 Ездры, 3 Ездры.
  BibleBookEnum.ezra: ["Ездра", "Книга Ездры", "1 Ездры", "Первая книга Ездры"],
  BibleBookEnum.nehemiah: ["Неемия", "Книга Неемии"],
  BibleBookEnum.esther: ["Есфирь", "Эсфирь", "Книга Есфири"],
  BibleBookEnum.job: ["Иов", "Книга Иова"],

  // Wisdom/Poetry
  BibleBookEnum.psalms: ["Псалтирь", "Псалмы"],
  BibleBookEnum.proverbs: ["Притчи", "Притчи Соломона", "Книга Притчей"],
  BibleBookEnum.ecclesiastes: ["Екклесиаст", "Проповедник"],
  BibleBookEnum.songOfSolomon: ["Песнь Песней", "Песнь песней", "Песня песней"],

  // Prophets
  BibleBookEnum.isaiah: ["Исаия", "Книга пророка Исаии"],
  BibleBookEnum.jeremiah: ["Иеремия", "Книга пророка Иеремии"],
  BibleBookEnum.lamentations: ["Плач Иеремии", "Плач"],
  BibleBookEnum.ezekiel: ["Иезекииль", "Книга пророка Иезекииля"],
  BibleBookEnum.daniel: ["Даниил", "Книга пророка Даниила"],

  BibleBookEnum.hosea: ["Осия", "Книга пророка Осии"],
  BibleBookEnum.joel: ["Иоиль", "Книга пророка Иоиля"],
  BibleBookEnum.amos: ["Амос", "Книга пророка Амоса"],
  BibleBookEnum.obadiah: ["Авдий", "Книга пророка Авдия"],
  BibleBookEnum.jonah: ["Иона", "Книга пророка Ионы"],
  BibleBookEnum.micah: ["Михей", "Книга пророка Михея"],
  BibleBookEnum.nahum: ["Наум", "Книга пророка Наума"],
  BibleBookEnum.habakkuk: ["Аввакум", "Книга пророка Аввакума"],
  BibleBookEnum.zephaniah: ["Софония", "Книга пророка Софонии"],
  BibleBookEnum.haggai: ["Аггей", "Книга пророка Аггея"],
  BibleBookEnum.zechariah: ["Захария", "Книга пророка Захарии"],
  BibleBookEnum.malachi: ["Малахия", "Книга пророка Малахии"],

  // Gospels & Acts
  BibleBookEnum.matthew: ["Матфея", "Евангелие от Матфея", "От Матфея"],
  BibleBookEnum.mark: ["Марка", "Евангелие от Марка", "От Марка"],
  BibleBookEnum.luke: ["Луки", "Евангелие от Луки", "От Луки"],
  BibleBookEnum.john: ["Иоанна", "Евангелие от Иоанна", "От Иоанна"],
  BibleBookEnum.acts: ["Деяния", "Деяния Апостолов", "Деяния святых Апостолов"],

  // Epistles
  BibleBookEnum.romans: ["Римлянам", "Послание к Римлянам"],
  BibleBookEnum.firstCorinthians: ["1 Коринфянам", "Первое послание к Коринфянам"],
  BibleBookEnum.secondCorinthians: ["2 Коринфянам", "Второе послание к Коринфянам"],
  BibleBookEnum.galatians: ["Галатам", "Послание к Галатам"],
  BibleBookEnum.ephesians: ["Ефесянам", "Послание к Ефесянам"],
  BibleBookEnum.philippians: ["Филиппийцам", "Послание к Филиппийцам"],
  BibleBookEnum.colossians: ["Колоссянам", "Послание к Колоссянам"],
  BibleBookEnum.firstThessalonians: ["1 Фессалоникийцам", "1 Солунянам"],
  BibleBookEnum.secondThessalonians: ["2 Фессалоникийцам", "2 Солунянам"],
  BibleBookEnum.firstTimothy: ["1 Тимофею", "Первое послание к Тимофею"],
  BibleBookEnum.secondTimothy: ["2 Тимофею", "Второе послание к Тимофею"],
  BibleBookEnum.titus: ["Титу", "Послание к Титу"],
  BibleBookEnum.philemon: ["Филимону", "Послание к Филимону"],
  BibleBookEnum.hebrews: ["Евреям", "Послание к Евреям"],

  BibleBookEnum.james: ["Иакова", "Послание Иакова"],
  BibleBookEnum.firstPeter: ["1 Петра", "Первое послание Петра"],
  BibleBookEnum.secondPeter: ["2 Петра", "Второе послание Петра"],
  BibleBookEnum.firstJohn: ["1 Иоанна", "Первое послание Иоанна"],
  BibleBookEnum.secondJohn: ["2 Иоанна", "Второе послание Иоанна"],
  BibleBookEnum.thirdJohn: ["3 Иоанна", "Третье послание Иоанна"],
  BibleBookEnum.jude: ["Иуды", "Послание Иуды"],

  BibleBookEnum.revelation: ["Откровение", "Откровение Иоанна Богослова", "Апокалипсис"],

  // Deuterocanon / Apocrypha (common Russian names)
  BibleBookEnum.tobit: ["Товит", "Книга Товита"],
  BibleBookEnum.judith: ["Иудифь", "Книга Иудифи"],
  BibleBookEnum.wisdom: ["Премудрость Соломона", "Книга Премудрости Соломона"],
  BibleBookEnum.sirach: ["Премудрость Иисуса, сына Сирахова", "Сирах", "Книга Сираха"],
  BibleBookEnum.baruch: ["Варух", "Книга Варуха"],
  BibleBookEnum.firstMaccabees: ["1 Маккавейская", "Первая книга Маккавейская"],
  BibleBookEnum.secondMaccabees: ["2 Маккавейская", "Вторая книга Маккавейская"],
  BibleBookEnum.thirdMaccabees: ["3 Маккавейская", "Третья книга Маккавейская"],
  BibleBookEnum.fourthMaccabees: ["4 Маккавейская", "Четвертая книга Маккавейская", "Четвёртая книга Маккавейская"],

  // Additions / extras (highly variant; keep explicit Russian titles)
  BibleBookEnum.estherAdditions: ["Есфирь (греческая)", "Есфирь (добавления)", "Есфирь (LXX)"],
  BibleBookEnum.danielSongOfThree: ["Песнь трёх отроков", "Песнь трех отроков", "Молитва Азарии и песнь трёх отроков"],
  BibleBookEnum.danielSusanna: ["Сусанна", "Даниил (Сусанна)"],
  BibleBookEnum.danielBelAndTheDragon: ["Вил и дракон", "Бел и дракон", "Даниил (Вил и дракон)"],

  // Apocryphal Esdras in Russian Orthodox/Synodal naming
  BibleBookEnum.firstEsdras: ["2 Ездры", "Вторая книга Ездры"],
  BibleBookEnum.secondEsdras: ["3 Ездры", "Третья книга Ездры"],

  BibleBookEnum.prayerOfManasseh: ["Молитва Манассии", "Молитва Манассии, царя Иудейского"],
  BibleBookEnum.psalm151: ["Псалом 151", "Псалтирь (Псалом 151)"],
};

const Map<BibleBookEnum, List<String>> russianBookAbbreviations = {
  // Pentateuch (Russian)
  BibleBookEnum.genesis: ["быт", "бт"],
  BibleBookEnum.exodus: ["исх", "ид"],
  BibleBookEnum.leviticus: ["лев", "лв"],
  BibleBookEnum.numbers: ["чис", "чс", "числ"],
  BibleBookEnum.deuteronomy: ["вт", "втор"],

  // History
  BibleBookEnum.joshua: ["нв", "нав", "иснав", "иош"],
  BibleBookEnum.judges: ["сд", "суд", "судей"],
  BibleBookEnum.ruth: ["рф", "руф", "руфь"],

  // Samuel + Kings: support both "Сам" and "Цар/Царств" citation systems
  BibleBookEnum.firstSamuel: ["1цар", "1ц", "1сам", "iсам"],
  BibleBookEnum.secondSamuel: ["2цар", "2ц", "2сам", "iiсам"],
  BibleBookEnum.firstKings: ["3цар", "3ц", "1царей", "1цр"],
  BibleBookEnum.secondKings: ["4цар", "4ц", "2царей", "2цр"],

  BibleBookEnum.firstChronicles: ["1пар", "1пар.", "1par"],
  BibleBookEnum.secondChronicles: ["2пар", "2пар.", "2par"],

  // Ezra/Nehemiah/Esther
  BibleBookEnum.ezra: ["1езд", "езд"],
  BibleBookEnum.nehemiah: ["неем", "нм"],
  BibleBookEnum.esther: ["есф", "ес"],

  BibleBookEnum.job: ["иов"],

  // Wisdom/Poetry
  BibleBookEnum.psalms: ["пс", "псал"],
  BibleBookEnum.proverbs: ["пр", "прит", "притч"],
  BibleBookEnum.ecclesiastes: ["ек", "еккл"],
  BibleBookEnum.songOfSolomon: ["пес", "песн"],

  // Major prophets
  BibleBookEnum.isaiah: ["ис", "исаи"],
  BibleBookEnum.jeremiah: ["иер"],
  BibleBookEnum.lamentations: ["пл", "плач"],
  BibleBookEnum.ezekiel: ["иез"],
  BibleBookEnum.daniel: ["дан"],

  // Minor prophets
  BibleBookEnum.hosea: ["ос"],
  BibleBookEnum.joel: ["иол", "иоил"],
  BibleBookEnum.amos: ["ам"],
  BibleBookEnum.obadiah: ["авд"],
  BibleBookEnum.jonah: ["ион"],
  BibleBookEnum.micah: ["мих"],
  BibleBookEnum.nahum: ["наум"],
  BibleBookEnum.habakkuk: ["авв"],
  BibleBookEnum.zephaniah: ["соф"],
  BibleBookEnum.haggai: ["агг", "аг"],
  BibleBookEnum.zechariah: ["зах"],
  BibleBookEnum.malachi: ["мал"],

  // Gospels & Acts
  BibleBookEnum.matthew: ["мф", "мат", "матф"],
  BibleBookEnum.mark: ["мк", "мр"],
  BibleBookEnum.luke: ["лк", "лук"],
  BibleBookEnum.john: ["ин", "иоан", "инн"],
  BibleBookEnum.acts: ["де", "деян"],

  // Epistles
  BibleBookEnum.romans: ["рим"],
  BibleBookEnum.firstCorinthians: ["1кор", "1кор.", "1 кор"],
  BibleBookEnum.secondCorinthians: ["2кор", "2кор.", "2 кор"],
  BibleBookEnum.galatians: ["гал", "галл"],
  BibleBookEnum.ephesians: ["еф"],
  BibleBookEnum.philippians: ["флп"],
  BibleBookEnum.colossians: ["кол"],
  BibleBookEnum.firstThessalonians: ["1фес", "1сол"],
  BibleBookEnum.secondThessalonians: ["2фес", "2сол"],
  BibleBookEnum.firstTimothy: ["1тим"],
  BibleBookEnum.secondTimothy: ["2тим"],
  BibleBookEnum.titus: ["тит"],
  BibleBookEnum.philemon: ["флм"],
  BibleBookEnum.hebrews: ["евр"],
  BibleBookEnum.james: ["иак", "ик"],
  BibleBookEnum.firstPeter: ["1пет"],
  BibleBookEnum.secondPeter: ["2пет"],
  BibleBookEnum.firstJohn: ["1ин"],
  BibleBookEnum.secondJohn: ["2ин"],
  BibleBookEnum.thirdJohn: ["3ин"],
  BibleBookEnum.jude: ["иуд"],

  BibleBookEnum.revelation: ["от", "откр", "апок"],

  // Deuterocanon / Apocrypha (Russian)
  BibleBookEnum.tobit: ["тов"],
  BibleBookEnum.judith: ["иудиф"],
  BibleBookEnum.wisdom: ["прем"],
  BibleBookEnum.sirach: ["сир"],
  BibleBookEnum.baruch: ["вар"],

  BibleBookEnum.firstMaccabees: ["1мак"],
  BibleBookEnum.secondMaccabees: ["2мак"],
  BibleBookEnum.thirdMaccabees: ["3мак"],
  BibleBookEnum.fourthMaccabees: ["4мак"],

  // Additions / extras
  // Russian short forms are not as standardized; prefer explicit tokens + stable IDs in your parser.
  BibleBookEnum.estherAdditions: ["есф(гр)", "ESG", "EsthGr"],
  BibleBookEnum.danielSongOfThree: ["песньтрехотроков", "S3Y", "PrAzar"],
  BibleBookEnum.danielSusanna: ["сусанна", "SUS", "Sus"],
  BibleBookEnum.danielBelAndTheDragon: ["вил", "бел", "BEL", "Bel"],

  // Apocryphal Esdras numbering (Russian Orthodox/Synodal)
  BibleBookEnum.firstEsdras: ["2езд", "2 ез", "1ES", "1Esd"],
  BibleBookEnum.secondEsdras: ["3езд", "3 ез", "2ES", "2Esd"],

  BibleBookEnum.prayerOfManasseh: ["молитваман", "MAN", "PrMan"],
  BibleBookEnum.psalm151: ["пс151", "PS2", "AddPs"],
};