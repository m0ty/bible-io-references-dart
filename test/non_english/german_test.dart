import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('German parsing', () {
    test('parse German verse reference', () {
      // Using a common book name that should exist in most languages
      final names = bookNamesByLanguage['de']![BibleBookEnum.john]!;
      final ref = verseRefFromStr('${names[0]} 3:16', language: BibleLanguageEnum.german);
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse German verse range', () {
      final names = bookNamesByLanguage['de']![BibleBookEnum.john]!;
      final ref = verseRangeRefFromStr('${names[0]} 3:16-17', language: BibleLanguageEnum.german);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    // Test all German book names
    for (final book in BibleBookEnum.values) {
      test('parse German book name: ${book.name}', () {
        final names = bookNamesByLanguage['de']![book]!;
        expect(names, isNotEmpty, reason: 'Missing German book names for ${book.name}');

        final ref = verseRefFromStr('${names[0]} 1:1', language: BibleLanguageEnum.german);
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });
    }

    // Test all German book abbreviations
    for (final book in BibleBookEnum.values) {
      test('parse German book abbreviations: ${book.name}', () {
        final abbreviations = bookAbbreviationsByLanguage['de']![book]!;
        expect(abbreviations, isNotEmpty, reason: 'Missing German book abbreviations for ${book.name}');

        for (final abbreviation in abbreviations) {
          final ref = verseRefFromStr('$abbreviation 1:1', language: BibleLanguageEnum.german);
          expect(ref.book, book, reason: 'Failed to parse abbreviation: $abbreviation');
          expect(ref.chapter, 1);
          expect(ref.verse, 1);
        }
      });
    }
  });
}
