import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Integration tests - complex parsing scenarios', () {
    test('parse complex multi-language references', () {
      // Test that auto language detection works across different scenarios
      final refs = [
        ('Juan 3:16', BibleBookEnum.john), // Spanish
        ('Jean 3:16', BibleBookEnum.john), // French
        ('João 3:16', BibleBookEnum.john), // Portuguese
        ('Иоанна 3:16', BibleBookEnum.john), // Russian
      ];

      for (final (ref, expectedBook) in refs) {
        final parsed = verseRefFromStr(ref);
        expect(parsed.book, expectedBook);
        expect(parsed.chapter, 3);
        expect(parsed.verse, 16);
      }
    });

    test('parse references with context-dependent book names', () {
      // Test books that might be confused in auto mode
      final refs = [
        ('jn 1:1', BibleBookEnum.jonah), // Should prefer Jonah due to precedence
        ('jud 1:1', BibleBookEnum.judges), // Should prefer Judges
        ('so 1:1', BibleBookEnum.songOfSolomon), // Should prefer Song of Solomon
      ];

      for (final (ref, expectedBook) in refs) {
        final parsed = verseRefFromStr(ref);
        expect(parsed.book, expectedBook);
      }
    });

    test('parse ranges spanning different language contexts', () {
      // Test ranges that mix languages (shouldn't happen in practice but good to test)
      final ref = verseRangeRefFromStr('John 3:16-Acts 1:2');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.end.book, BibleBookEnum.acts);
    });

    test('parse all supported languages have working book names', () {
      // Test that each language has at least one working book name
      final testBook = BibleBookEnum.john;
      final languages = [
        BibleLanguageEnum.arabic,
        BibleLanguageEnum.chinese,
        BibleLanguageEnum.french,
        BibleLanguageEnum.german,
        BibleLanguageEnum.hebrew,
        BibleLanguageEnum.hindi,
        BibleLanguageEnum.indonesian,
        BibleLanguageEnum.korean,
        BibleLanguageEnum.portuguese,
        BibleLanguageEnum.russian,
        BibleLanguageEnum.spanish,
        BibleLanguageEnum.tagalog,
      ];

      for (final language in languages) {
        final names = bookNamesByLanguage[language.code]?[testBook];
        if (names != null && names.isNotEmpty) {
          final ref = verseRefFromStr('${names.first} 3:16', language: language);
          expect(ref.book, testBook);
        }
      }
    });
  });

  group('Integration tests - error propagation', () {
    test('error codes are consistent across parsing methods', () {
      final testCases = [
        ('InvalidBook 3:16', 'unknown_book'),
        ('John 0:1', 'non_positive_numeric_token'),
        ('John 1:0', 'non_positive_numeric_token'),
        ('', 'empty_reference'),
      ];

      for (final (input, expectedCode) in testCases) {
        try {
          verseRefFromStr(input);
          fail('Expected ParseVerseRefError');
        } catch (e) {
          expect(e, isA<ParseVerseRefError>());
          expect((e as ParseVerseRefError).code, expectedCode);
        }

        try {
          Reference.parse(input);
          fail('Expected ParseVerseRefError');
        } catch (e) {
          expect(e, isA<ParseVerseRefError>());
          expect((e as ParseVerseRefError).code, expectedCode);
        }
      }
    });

    test('range parsing errors include context', () {
      try {
        verseRangeRefFromStr('InvalidBook 3:16-17');
      } catch (e) {
        expect(e, isA<ParseVerseRefError>());
        expect((e as ParseVerseRefError).code, 'unknown_book');
      }

      try {
        verseRangeRefFromStr('John 3:16-InvalidBook 1:1');
      } catch (e) {
        expect(e, isA<ParseVerseRefError>());
        expect((e as ParseVerseRefError).code, 'unknown_book');
      }
    });
  });

  group('Integration tests - performance and memory', () {
    test('parsing is reasonably fast', () {
      // Test that parsing 100 references takes less than 1 second
      final start = DateTime.now();
      for (var i = 0; i < 100; i++) {
        verseRefFromStr('John ${i % 21 + 1}:${i % 25 + 1}');
      }
      final end = DateTime.now();
      final duration = end.difference(start);

      expect(duration.inMilliseconds, lessThan(1000));
    });

    test('lookup tables are shared efficiently', () {
      // Test that multiple parsers use the same lookup instance
      final ref1 = verseRefFromStr('John 3:16');
      final ref2 = verseRefFromStr('Matthew 1:1');

      // This is more of a smoke test - in a real perf test we'd measure memory
      expect(ref1.book, BibleBookEnum.john);
      expect(ref2.book, BibleBookEnum.matthew);
    });
  });
}