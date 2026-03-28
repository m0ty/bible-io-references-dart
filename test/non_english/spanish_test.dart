import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Spanish parsing', () {
    test('parse Spanish verse reference', () {
      final ref = verseRefFromStr('Juan 3:16', language: BibleLanguageEnum.spanish);
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse Spanish verse range', () {
      final ref = verseRangeRefFromStr('Juan 3:16-17', language: BibleLanguageEnum.spanish);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    test('parse Spanish cross-chapter range', () {
      final ref = verseRangeRefFromStr('Juan 3:16-4:1', language: BibleLanguageEnum.spanish);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 4);
      expect(ref.end.verse, 1);
    });

    test('parse Spanish with dot separators', () {
      final ref = verseRangeRefFromStr('Juan 3.16-4.1', language: BibleLanguageEnum.spanish);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 4);
      expect(ref.end.verse, 1);
    });

    test('parse Spanish with en dash', () {
      final ref = verseRangeRefFromStr('Juan 3:16–17', language: BibleLanguageEnum.spanish);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    // Test all Spanish book names
    for (final book in BibleBookEnum.values) {
      test('parse Spanish book name: ${book.name}', () {
        final names = bookNamesByLanguage['es']![book]!;
        expect(names, isNotEmpty, reason: 'Missing Spanish book names for ${book.name}');

        final ref = verseRefFromStr('${names[0]} 1:1', language: BibleLanguageEnum.spanish);
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });
    }

    // Test all Spanish book abbreviations
    for (final book in BibleBookEnum.values) {
      test('parse Spanish book abbreviations: ${book.name}', () {
        final abbreviations = bookAbbreviationsByLanguage['es']![book]!;
        expect(abbreviations, isNotEmpty, reason: 'Missing Spanish book abbreviations for ${book.name}');

        for (final abbreviation in abbreviations) {
          final ref = verseRefFromStr('$abbreviation 1:1', language: BibleLanguageEnum.spanish);
          expect(ref.book, book, reason: 'Failed to parse abbreviation: $abbreviation');
          expect(ref.chapter, 1);
          expect(ref.verse, 1);
        }
      });
    }
  });
}