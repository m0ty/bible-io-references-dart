import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Chinese parsing', () {
    test('parse Chinese verse reference', () {
      // Using a common book name that should exist in most languages
      final names = bookNamesByLanguage['zh']![BibleBookEnum.john]!;
      final ref = verseRefFromStr('${names[0]} 3:16', language: BibleLanguageEnum.chinese);
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse Chinese verse range', () {
      final names = bookNamesByLanguage['zh']![BibleBookEnum.john]!;
      final ref = verseRangeRefFromStr('${names[0]} 3:16-17', language: BibleLanguageEnum.chinese);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    // Test all Chinese book names
    for (final book in BibleBookEnum.values) {
      test('parse Chinese book name: ${book.name}', () {
        final names = bookNamesByLanguage['zh']![book]!;
        expect(names, isNotEmpty, reason: 'Missing Chinese book names for ${book.name}');

        final ref = verseRefFromStr('${names[0]} 1:1', language: BibleLanguageEnum.chinese);
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });
    }

    // Test all Chinese book abbreviations
    for (final book in BibleBookEnum.values) {
      test('parse Chinese book abbreviations: ${book.name}', () {
        final abbreviations = bookAbbreviationsByLanguage['zh']![book]!;
        expect(abbreviations, isNotEmpty, reason: 'Missing Chinese book abbreviations for ${book.name}');

        for (final abbreviation in abbreviations) {
          final ref = verseRefFromStr('$abbreviation 1:1', language: BibleLanguageEnum.chinese);
          expect(ref.book, book, reason: 'Failed to parse abbreviation: $abbreviation');
          expect(ref.chapter, 1);
          expect(ref.verse, 1);
        }
      });
    }
  });
}
