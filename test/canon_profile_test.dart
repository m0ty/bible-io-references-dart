import 'package:bible_io_references/bible_book_enum.dart';
import 'package:bible_io_references/canon_profile.dart';
import 'package:test/test.dart';

void main() {
  group('built-in canon profiles', () {
    test('Protestant profile contains 66 books in conventional order', () {
      final profile = CanonProfile.protestant;

      expect(profile.id, 'protestant');
      expect(profile.length, 66);
      expect(profile.firstBook, BibleBookEnum.genesis);
      expect(profile.lastBook, BibleBookEnum.revelation);
      expect(profile.first, profile.firstBook);
      expect(profile.last, profile.lastBook);
      expect(profile.contains(BibleBookEnum.malachi), isTrue);
      expect(profile.contains(BibleBookEnum.tobit), isFalse);
      expect(
        profile.compare(BibleBookEnum.malachi, BibleBookEnum.matthew),
        isNegative,
      );
    });

    test('Catholic profile contains 73 canonical books in USCCB order', () {
      final profile = CanonProfile.catholic;

      expect(profile.length, 73);
      expect(profile.firstBook, BibleBookEnum.genesis);
      expect(profile.lastBook, BibleBookEnum.revelation);
      expect(profile.contains(BibleBookEnum.tobit), isTrue);
      expect(profile.contains(BibleBookEnum.wisdom), isTrue);
      expect(profile.contains(BibleBookEnum.baruch), isTrue);
      expect(
        profile.compare(BibleBookEnum.nehemiah, BibleBookEnum.tobit),
        isNegative,
      );
      expect(
        profile.compare(BibleBookEnum.secondMaccabees, BibleBookEnum.job),
        isNegative,
      );
      expect(
        profile.compare(BibleBookEnum.songOfSolomon, BibleBookEnum.wisdom),
        isNegative,
      );
    });

    test('Catholic additions are represented within Esther and Daniel', () {
      final profile = CanonProfile.catholic;

      expect(profile.contains(BibleBookEnum.esther), isTrue);
      expect(profile.contains(BibleBookEnum.daniel), isTrue);
      expect(profile.contains(BibleBookEnum.estherAdditions), isFalse);
      expect(profile.contains(BibleBookEnum.danielSongOfThree), isFalse);
      expect(profile.contains(BibleBookEnum.danielSusanna), isFalse);
      expect(profile.contains(BibleBookEnum.danielBelAndTheDragon), isFalse);
    });

    test('broad Orthodox profile includes every supported book token once', () {
      final profile = CanonProfile.broadEasternOrthodox;

      expect(profile, same(CanonProfile.easternOrthodox));
      expect(profile.length, BibleBookEnum.values.length);
      expect(profile.books.toSet(), BibleBookEnum.values.toSet());
      expect(profile.contains(BibleBookEnum.prayerOfManasseh), isTrue);
      expect(profile.contains(BibleBookEnum.psalm151), isTrue);
      expect(profile.contains(BibleBookEnum.fourthMaccabees), isTrue);
      expect(
        profile.compare(BibleBookEnum.psalms, BibleBookEnum.psalm151),
        isNegative,
      );
      expect(
        profile.compare(
          BibleBookEnum.daniel,
          BibleBookEnum.danielSongOfThree,
        ),
        isNegative,
      );
    });
  });

  group('membership and ordering', () {
    test('indexOf uses -1 for absence and requireIndexOf rejects it', () {
      final profile = CanonProfile.protestant;

      expect(profile.indexOf(BibleBookEnum.genesis), 0);
      expect(profile.requireIndexOf(BibleBookEnum.genesis), 0);
      expect(profile.indexOf(BibleBookEnum.tobit), -1);
      expect(
        () => profile.requireIndexOf(BibleBookEnum.tobit),
        throwsArgumentError,
      );
    });

    test('compare rejects a book outside the profile on either side', () {
      final profile = CanonProfile.protestant;

      expect(
        () => profile.compare(BibleBookEnum.tobit, BibleBookEnum.genesis),
        throwsArgumentError,
      );
      expect(
        () => profile.compare(BibleBookEnum.genesis, BibleBookEnum.tobit),
        throwsArgumentError,
      );
      expect(
        profile.compare(BibleBookEnum.john, BibleBookEnum.john),
        0,
      );
    });
  });

  group('custom canon profiles', () {
    test('copy their input and expose an unmodifiable ordered list', () {
      final source = [BibleBookEnum.luke, BibleBookEnum.acts];
      final profile = CanonProfile(
        id: 'luke-acts',
        displayName: 'Luke–Acts',
        books: source,
      );

      source
        ..clear()
        ..add(BibleBookEnum.genesis);

      expect(
        profile.books,
        [BibleBookEnum.luke, BibleBookEnum.acts],
      );
      expect(
        () => profile.books.add(BibleBookEnum.romans),
        throwsUnsupportedError,
      );
      expect(profile.name, 'Luke–Acts');
    });

    test('have value equality and order-sensitive hash codes', () {
      final first = CanonProfile(
        id: 'sample',
        displayName: 'Sample',
        books: const [BibleBookEnum.john, BibleBookEnum.acts],
      );
      final sameValue = CanonProfile(
        id: 'sample',
        displayName: 'Sample',
        books: const [BibleBookEnum.john, BibleBookEnum.acts],
      );
      final reversed = CanonProfile(
        id: 'sample',
        displayName: 'Sample',
        books: const [BibleBookEnum.acts, BibleBookEnum.john],
      );

      expect(first, sameValue);
      expect(first.hashCode, sameValue.hashCode);
      expect(first, isNot(reversed));
    });

    test('reject empty identifiers, names, and book collections', () {
      expect(
        () => CanonProfile(
          id: '',
          displayName: 'Empty id',
          books: const [BibleBookEnum.genesis],
        ),
        throwsArgumentError,
      );
      expect(
        () => CanonProfile(
          id: 'blank-name',
          displayName: '   ',
          books: const [BibleBookEnum.genesis],
        ),
        throwsArgumentError,
      );
      expect(
        () => CanonProfile(
          id: 'empty-books',
          displayName: 'Empty books',
          books: const [],
        ),
        throwsArgumentError,
      );
    });

    test('reject surrounding whitespace and duplicate books', () {
      expect(
        () => CanonProfile(
          id: ' padded ',
          displayName: 'Padded',
          books: const [BibleBookEnum.genesis],
        ),
        throwsArgumentError,
      );
      expect(
        () => CanonProfile(
          id: 'duplicates',
          displayName: 'Duplicates',
          books: const [BibleBookEnum.genesis, BibleBookEnum.genesis],
        ),
        throwsArgumentError,
      );
    });
  });
}
