import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Hindi parsing', () {
    test('parse Hindi verse reference', () {
      // Using a common book name that should exist in most languages
      final names = bookNamesByLanguage['hi']![BibleBookEnum.john]!;
      final ref = verseRefFromStr('${names[0]} 3:16', language: BibleLanguageEnum.hindi);
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse Hindi verse range', () {
      final names = bookNamesByLanguage['hi']![BibleBookEnum.john]!;
      final ref = verseRangeRefFromStr('${names[0]} 3:16-17', language: BibleLanguageEnum.hindi);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    // Test all Hindi book names
    for (final book in BibleBookEnum.values) {
      test('parse Hindi book name: ${book.name}', () {
        final names = bookNamesByLanguage['hi']![book]!;
        expect(names, isNotEmpty, reason: 'Missing Hindi book names for ${book.name}');

        final ref = verseRefFromStr('${names[0]} 1:1', language: BibleLanguageEnum.hindi);
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });
    }

    // Test all Hindi book abbreviations
    for (final book in BibleBookEnum.values) {
      test('parse Hindi book abbreviations: ${book.name}', () {
        final abbreviations = bookAbbreviationsByLanguage['hi']![book]!;
        expect(abbreviations, isNotEmpty, reason: 'Missing Hindi book abbreviations for ${book.name}');

        for (final abbreviation in abbreviations) {
          final ref = verseRefFromStr('$abbreviation 1:1', language: BibleLanguageEnum.hindi);
          expect(ref.book, book, reason: 'Failed to parse abbreviation: $abbreviation');
          expect(ref.chapter, 1);
          expect(ref.verse, 1);
        }
      });
    }
  });
}
