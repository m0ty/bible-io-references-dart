import 'bible_book_enum.dart';

/// An immutable, ordered set of books recognized by a biblical canon.
///
/// A profile defines both membership and ordering. It deliberately does not
/// define chapter or verse counts; those belong to a versification profile.
///
/// Custom profiles must have a non-empty [id], [displayName], and [books]
/// collection. A book may occur only once. The supplied iterable is copied,
/// so later changes to its source cannot mutate the profile.
final class CanonProfile {
  /// Creates a validated custom canon profile.
  factory CanonProfile({
    required String id,
    required String displayName,
    required Iterable<BibleBookEnum> books,
  }) {
    _validateText(id, 'id');
    _validateText(displayName, 'displayName');

    final orderedBooks = List<BibleBookEnum>.of(books);
    if (orderedBooks.isEmpty) {
      throw ArgumentError.value(
        orderedBooks,
        'books',
        'must contain at least one book',
      );
    }

    final indexes = <BibleBookEnum, int>{};
    for (var index = 0; index < orderedBooks.length; index++) {
      final book = orderedBooks[index];
      if (indexes.containsKey(book)) {
        throw ArgumentError.value(
          book,
          'books',
          'must not contain duplicate books',
        );
      }
      indexes[book] = index;
    }

    return CanonProfile._(
      id: id,
      displayName: displayName,
      books: List<BibleBookEnum>.unmodifiable(orderedBooks),
      indexes: Map<BibleBookEnum, int>.unmodifiable(indexes),
    );
  }

  const CanonProfile._({
    required this.id,
    required this.displayName,
    required this.books,
    required Map<BibleBookEnum, int> indexes,
  }) : _indexes = indexes;

  /// The conventional 66-book Protestant canon and ordering.
  ///
  /// Membership and order follow the list in chapter 1, section 2 of the
  /// Westminster Confession as published by the Orthodox Presbyterian Church:
  /// https://opc.org/WCF-WIP.html
  static final CanonProfile protestant = CanonProfile(
    id: 'protestant',
    displayName: 'Protestant',
    books: _protestantBooks,
  );

  /// The 73-book Catholic canon in canonical order.
  ///
  /// Membership and order follow the United States Conference of Catholic
  /// Bishops' canonical book list:
  /// https://www.usccb.org/offices/new-american-bible/books-bible
  ///
  /// [BibleBookEnum.estherAdditions], [BibleBookEnum.danielSongOfThree],
  /// [BibleBookEnum.danielSusanna], and
  /// [BibleBookEnum.danielBelAndTheDragon] are not separate books in this
  /// profile. Their material is represented within Esther and Daniel in the
  /// Catholic canon.
  static final CanonProfile catholic = CanonProfile(
    id: 'catholic',
    displayName: 'Catholic',
    books: _catholicBooks,
  );

  /// Explicit family name for the conventional Roman Catholic canon.
  ///
  /// This aliases [catholic] and does not imply a particular versification.
  static CanonProfile get romanCatholic => catholic;

  /// A broad Eastern Orthodox interoperability profile.
  ///
  /// Orthodox Old Testament contents and ordering vary by jurisdiction and
  /// edition. This profile is therefore intentionally a permissive superset,
  /// not a claim that one 83-book order is normative throughout Orthodoxy. It
  /// contains every [BibleBookEnum] token supported by this package, including
  /// separately modeled Esther and Daniel portions, 2 Esdras, and 4 Maccabees.
  /// Parent works and separately modeled portions are kept near one another to
  /// provide a predictable software ordering.
  ///
  /// The longer Orthodox canon is described by the Orthodox Church in America:
  /// https://www.oca.org/questions/scripture/canon-of-scripture
  /// The Greek Orthodox Archdiocese of America also documents its use of the
  /// Septuagint and its canonical and anagignoskomena books:
  /// https://www.goarch.org/-/the-bible-its-original-languages-and-english-translations
  static final CanonProfile broadEasternOrthodox = CanonProfile(
    id: 'eastern-orthodox-broad',
    displayName: 'Eastern Orthodox (broad)',
    books: _broadEasternOrthodoxBooks,
  );

  /// Alias for [broadEasternOrthodox].
  ///
  /// The shorter name is convenient when an API already establishes that its
  /// built-in Orthodox option is the broad interoperability profile.
  static CanonProfile get easternOrthodox => broadEasternOrthodox;

  /// Alias that makes the broad, non-normative nature explicit in call sites.
  static CanonProfile get easternOrthodoxBroad => broadEasternOrthodox;

  /// A stable machine-readable identifier for this profile.
  final String id;

  /// A human-readable profile name.
  final String displayName;

  /// The books in this profile's canonical order.
  ///
  /// This list is unmodifiable.
  final List<BibleBookEnum> books;

  final Map<BibleBookEnum, int> _indexes;

  /// Alias for [displayName].
  String get name => displayName;

  /// The number of books in the profile.
  int get length => books.length;

  /// The first book in this profile's order.
  BibleBookEnum get firstBook => books.first;

  /// Alias for [firstBook], matching collection terminology.
  BibleBookEnum get first => firstBook;

  /// The last book in this profile's order.
  BibleBookEnum get lastBook => books.last;

  /// Alias for [lastBook], matching collection terminology.
  BibleBookEnum get last => lastBook;

  /// Whether [book] belongs to this profile.
  bool contains(BibleBookEnum book) => _indexes.containsKey(book);

  /// Returns the zero-based canonical index of [book], or `-1` when absent.
  int indexOf(BibleBookEnum book) => _indexes[book] ?? -1;

  /// Returns the zero-based canonical index of [book].
  ///
  /// Throws [ArgumentError] when [book] does not belong to this profile.
  int requireIndexOf(BibleBookEnum book) {
    final index = _indexes[book];
    if (index == null) {
      throw ArgumentError.value(
        book,
        'book',
        'is not part of the $displayName canon profile',
      );
    }
    return index;
  }

  /// Compares [left] and [right] using this profile's canonical order.
  ///
  /// The result is negative when [left] precedes [right], zero when they are
  /// identical, and positive when [left] follows [right]. Throws
  /// [ArgumentError] if either book does not belong to this profile.
  int compare(BibleBookEnum left, BibleBookEnum right) {
    final leftIndex = requireIndexOf(left);
    final rightIndex = requireIndexOf(right);
    return leftIndex.compareTo(rightIndex);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CanonProfile ||
        id != other.id ||
        displayName != other.displayName ||
        books.length != other.books.length) {
      return false;
    }
    for (var index = 0; index < books.length; index++) {
      if (books[index] != other.books[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, displayName, Object.hashAll(books));

  @override
  String toString() =>
      'CanonProfile(id: $id, displayName: $displayName, books: $length)';

  static void _validateText(String value, String parameterName) {
    if (value.isEmpty || value.trim().isEmpty) {
      throw ArgumentError.value(value, parameterName, 'must not be empty');
    }
    if (value != value.trim()) {
      throw ArgumentError.value(
        value,
        parameterName,
        'must not have surrounding whitespace',
      );
    }
  }
}

const List<BibleBookEnum> _protestantOldTestament = [
  BibleBookEnum.genesis,
  BibleBookEnum.exodus,
  BibleBookEnum.leviticus,
  BibleBookEnum.numbers,
  BibleBookEnum.deuteronomy,
  BibleBookEnum.joshua,
  BibleBookEnum.judges,
  BibleBookEnum.ruth,
  BibleBookEnum.firstSamuel,
  BibleBookEnum.secondSamuel,
  BibleBookEnum.firstKings,
  BibleBookEnum.secondKings,
  BibleBookEnum.firstChronicles,
  BibleBookEnum.secondChronicles,
  BibleBookEnum.ezra,
  BibleBookEnum.nehemiah,
  BibleBookEnum.esther,
  BibleBookEnum.job,
  BibleBookEnum.psalms,
  BibleBookEnum.proverbs,
  BibleBookEnum.ecclesiastes,
  BibleBookEnum.songOfSolomon,
  BibleBookEnum.isaiah,
  BibleBookEnum.jeremiah,
  BibleBookEnum.lamentations,
  BibleBookEnum.ezekiel,
  BibleBookEnum.daniel,
  BibleBookEnum.hosea,
  BibleBookEnum.joel,
  BibleBookEnum.amos,
  BibleBookEnum.obadiah,
  BibleBookEnum.jonah,
  BibleBookEnum.micah,
  BibleBookEnum.nahum,
  BibleBookEnum.habakkuk,
  BibleBookEnum.zephaniah,
  BibleBookEnum.haggai,
  BibleBookEnum.zechariah,
  BibleBookEnum.malachi,
];

const List<BibleBookEnum> _newTestament = [
  BibleBookEnum.matthew,
  BibleBookEnum.mark,
  BibleBookEnum.luke,
  BibleBookEnum.john,
  BibleBookEnum.acts,
  BibleBookEnum.romans,
  BibleBookEnum.firstCorinthians,
  BibleBookEnum.secondCorinthians,
  BibleBookEnum.galatians,
  BibleBookEnum.ephesians,
  BibleBookEnum.philippians,
  BibleBookEnum.colossians,
  BibleBookEnum.firstThessalonians,
  BibleBookEnum.secondThessalonians,
  BibleBookEnum.firstTimothy,
  BibleBookEnum.secondTimothy,
  BibleBookEnum.titus,
  BibleBookEnum.philemon,
  BibleBookEnum.hebrews,
  BibleBookEnum.james,
  BibleBookEnum.firstPeter,
  BibleBookEnum.secondPeter,
  BibleBookEnum.firstJohn,
  BibleBookEnum.secondJohn,
  BibleBookEnum.thirdJohn,
  BibleBookEnum.jude,
  BibleBookEnum.revelation,
];

const List<BibleBookEnum> _protestantBooks = [
  ..._protestantOldTestament,
  ..._newTestament,
];

const List<BibleBookEnum> _catholicBooks = [
  BibleBookEnum.genesis,
  BibleBookEnum.exodus,
  BibleBookEnum.leviticus,
  BibleBookEnum.numbers,
  BibleBookEnum.deuteronomy,
  BibleBookEnum.joshua,
  BibleBookEnum.judges,
  BibleBookEnum.ruth,
  BibleBookEnum.firstSamuel,
  BibleBookEnum.secondSamuel,
  BibleBookEnum.firstKings,
  BibleBookEnum.secondKings,
  BibleBookEnum.firstChronicles,
  BibleBookEnum.secondChronicles,
  BibleBookEnum.ezra,
  BibleBookEnum.nehemiah,
  BibleBookEnum.tobit,
  BibleBookEnum.judith,
  BibleBookEnum.esther,
  BibleBookEnum.firstMaccabees,
  BibleBookEnum.secondMaccabees,
  BibleBookEnum.job,
  BibleBookEnum.psalms,
  BibleBookEnum.proverbs,
  BibleBookEnum.ecclesiastes,
  BibleBookEnum.songOfSolomon,
  BibleBookEnum.wisdom,
  BibleBookEnum.sirach,
  BibleBookEnum.isaiah,
  BibleBookEnum.jeremiah,
  BibleBookEnum.lamentations,
  BibleBookEnum.baruch,
  BibleBookEnum.ezekiel,
  BibleBookEnum.daniel,
  BibleBookEnum.hosea,
  BibleBookEnum.joel,
  BibleBookEnum.amos,
  BibleBookEnum.obadiah,
  BibleBookEnum.jonah,
  BibleBookEnum.micah,
  BibleBookEnum.nahum,
  BibleBookEnum.habakkuk,
  BibleBookEnum.zephaniah,
  BibleBookEnum.haggai,
  BibleBookEnum.zechariah,
  BibleBookEnum.malachi,
  ..._newTestament,
];

const List<BibleBookEnum> _broadEasternOrthodoxBooks = [
  BibleBookEnum.genesis,
  BibleBookEnum.exodus,
  BibleBookEnum.leviticus,
  BibleBookEnum.numbers,
  BibleBookEnum.deuteronomy,
  BibleBookEnum.joshua,
  BibleBookEnum.judges,
  BibleBookEnum.ruth,
  BibleBookEnum.firstSamuel,
  BibleBookEnum.secondSamuel,
  BibleBookEnum.firstKings,
  BibleBookEnum.secondKings,
  BibleBookEnum.firstChronicles,
  BibleBookEnum.secondChronicles,
  BibleBookEnum.prayerOfManasseh,
  BibleBookEnum.firstEsdras,
  BibleBookEnum.secondEsdras,
  BibleBookEnum.ezra,
  BibleBookEnum.nehemiah,
  BibleBookEnum.tobit,
  BibleBookEnum.judith,
  BibleBookEnum.esther,
  BibleBookEnum.estherAdditions,
  BibleBookEnum.firstMaccabees,
  BibleBookEnum.secondMaccabees,
  BibleBookEnum.thirdMaccabees,
  BibleBookEnum.fourthMaccabees,
  BibleBookEnum.job,
  BibleBookEnum.psalms,
  BibleBookEnum.psalm151,
  BibleBookEnum.proverbs,
  BibleBookEnum.ecclesiastes,
  BibleBookEnum.songOfSolomon,
  BibleBookEnum.wisdom,
  BibleBookEnum.sirach,
  BibleBookEnum.isaiah,
  BibleBookEnum.jeremiah,
  BibleBookEnum.lamentations,
  BibleBookEnum.baruch,
  BibleBookEnum.ezekiel,
  BibleBookEnum.daniel,
  BibleBookEnum.danielSongOfThree,
  BibleBookEnum.danielSusanna,
  BibleBookEnum.danielBelAndTheDragon,
  BibleBookEnum.hosea,
  BibleBookEnum.joel,
  BibleBookEnum.amos,
  BibleBookEnum.obadiah,
  BibleBookEnum.jonah,
  BibleBookEnum.micah,
  BibleBookEnum.nahum,
  BibleBookEnum.habakkuk,
  BibleBookEnum.zephaniah,
  BibleBookEnum.haggai,
  BibleBookEnum.zechariah,
  BibleBookEnum.malachi,
  ..._newTestament,
];
