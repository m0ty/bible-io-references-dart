import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Arabic parsing', () {
    test('parse Arabic verse reference', () {
      final ref = verseRefFromStr('يوحنا 3:16', language: BibleLanguageEnum.arabic);
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse Arabic verse range', () {
      final ref = verseRangeRefFromStr('يوحنا 3:16-17', language: BibleLanguageEnum.arabic);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    // Test all Arabic book names (these should be unambiguous)
    for (final book in BibleBookEnum.values) {
      test('parse Arabic book name: ${book.name}', () {
        final names = bookNamesByLanguage['ar']![book]!;
        expect(names, isNotEmpty, reason: 'Missing Arabic book names for ${book.name}');

        final ref = verseRefFromStr('${names[0]} 1:1', language: BibleLanguageEnum.arabic);
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });
    }

    // Test Arabic book abbreviations that should be unambiguous
    // Skip books that have known collisions
    final skipCollisions = {
      BibleBookEnum.lamentations, // "مر" collides with Mark
      BibleBookEnum.mark, // "مر" collides with Lamentations
      BibleBookEnum.joel, // "يو" collides with John
      BibleBookEnum.john, // "يو" collides with Joel
    };

    for (final book in BibleBookEnum.values.where((b) => !skipCollisions.contains(b))) {
      test('parse Arabic book abbreviations: ${book.name}', () {
        final abbreviations = bookAbbreviationsByLanguage['ar']![book]!;
        expect(abbreviations, isNotEmpty, reason: 'Missing Arabic book abbreviations for ${book.name}');

        for (final abbreviation in abbreviations) {
          final ref = verseRefFromStr('$abbreviation 1:1', language: BibleLanguageEnum.arabic);
          expect(ref.book, book, reason: 'Failed to parse abbreviation: $abbreviation');
          expect(ref.chapter, 1);
          expect(ref.verse, 1);
        }
      });
    }

    test('Arabic collision handling - Mark vs Lamentations', () {
      // Both "مر" abbreviation exists for both books, but parser should choose one consistently
      final ref1 = verseRefFromStr('مر 1:1', language: BibleLanguageEnum.arabic);
      expect([BibleBookEnum.mark, BibleBookEnum.lamentations].contains(ref1.book), isTrue);
    });

    test('Arabic collision handling - John vs Joel', () {
      // Both "يو" abbreviation exists for both books, but parser should choose one consistently
      final ref1 = verseRefFromStr('يو 1:1', language: BibleLanguageEnum.arabic);
      expect([BibleBookEnum.john, BibleBookEnum.joel].contains(ref1.book), isTrue);
    });
  });
}