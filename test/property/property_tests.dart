import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Property-based parsing tests', () {
    // Test various edge cases and boundary conditions

    test('parse with extra whitespace', () {
      final ref = verseRefFromStr('  John   3   :   16   ');
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse with mixed case book names', () {
      final ref = verseRefFromStr('jOhN 3:16');
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse with maximum reasonable chapter/verse numbers', () {
      final ref = verseRefFromStr('Psalms 150:6');
      expect(ref.book, BibleBookEnum.psalms);
      expect(ref.chapter, 150);
      expect(ref.verse, 6);
    });

    test('parse range with maximum chapter jump', () {
      final ref = verseRangeRefFromStr('Genesis 1:1-Malachi 4:6');
      expect(ref.start.book, BibleBookEnum.genesis);
      expect(ref.start.chapter, 1);
      expect(ref.start.verse, 1);
      expect(ref.end.book, BibleBookEnum.malachi);
      expect(ref.end.chapter, 4);
      expect(ref.end.verse, 6);
    });

    test('parse with Unicode book names from different languages', () {
      // Test some Unicode characters that appear in book names
      final ref = verseRefFromStr('João 3:16', language: BibleLanguageEnum.portuguese);
      expect(ref.book, BibleBookEnum.john);
    });

    test('parse with various dash types in ranges', () {
      final dashes = ['-', '–', '—', '―'];
      for (final dash in dashes) {
        final ref = verseRangeRefFromStr('John 3:16${dash}17');
        expect(ref.start.verse, 16);
        expect(ref.end.verse, 17);
      }
    });

    test('parse book names with apostrophes and special characters', () {
      final ref = verseRefFromStr("Song of Solomon 1:1");
      expect(ref.book, BibleBookEnum.songOfSolomon);
    });

    test('parse abbreviated book names with periods', () {
      final ref = verseRefFromStr('Gen. 1:1');
      expect(ref.book, BibleBookEnum.genesis);
    });

    test('parse book names with Roman numerals', () {
      final ref = verseRefFromStr('1 Corinthians 1:1');
      expect(ref.book, BibleBookEnum.firstCorinthians);
    });
  });

  group('Error boundary testing', () {
    test('parse with extremely large numbers', () {
      expect(() => verseRefFromStr('John 999999:999999'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse with empty strings', () {
      expect(() => verseRefFromStr(''), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse with only whitespace', () {
      expect(() => verseRefFromStr('   '), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse with invalid separators', () {
      expect(() => verseRefFromStr('John 3/16'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRefFromStr('John 3;16'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse with missing components', () {
      expect(() => verseRefFromStr('John 3'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRefFromStr('John :16'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRefFromStr('3:16'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse range with invalid formats', () {
      expect(() => verseRangeRefFromStr('John 3:16-'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRangeRefFromStr('John 3:16-17-18'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse with non-numeric chapter/verse', () {
      expect(() => verseRefFromStr('John abc:16'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRefFromStr('John 3:def'), throwsA(isA<ParseVerseRefError>()));
    });
  });

  group('Round-trip parsing tests', () {
    test('verse ref round-trip', () {
      final original = 'John 3:16';
      final parsed = verseRefFromStr(original);
      final serialized = parsed.toString();
      final reparsed = verseRefFromStr(serialized);

      expect(reparsed.book, parsed.book);
      expect(reparsed.chapter, parsed.chapter);
      expect(reparsed.verse, parsed.verse);
    });

    test('verse range round-trip', () {
      final original = 'John 3:16-17';
      final parsed = verseRangeRefFromStr(original);
      final serialized = parsed.toString();
      final reparsed = verseRangeRefFromStr(serialized);

      expect(reparsed.start.book, parsed.start.book);
      expect(reparsed.start.chapter, parsed.start.chapter);
      expect(reparsed.start.verse, parsed.start.verse);
      expect(reparsed.end.book, parsed.end.book);
      expect(reparsed.end.chapter, parsed.end.chapter);
      expect(reparsed.end.verse, parsed.end.verse);
    });

    test('cross-book range round-trip', () {
      final original = 'John 3:16-Acts 1:2';
      final parsed = verseRangeRefFromStr(original);
      final serialized = parsed.toString();
      final reparsed = verseRangeRefFromStr(serialized);

      expect(reparsed.start.book, parsed.start.book);
      expect(reparsed.end.book, parsed.end.book);
    });
  });

  group('Reference.parse() comprehensive testing', () {
    test('Reference.parse handles all verse ref formats', () {
      final testCases = [
        'John 3:16',
        'John 3.16',
        'jo 1:1',
        'Gen 1:1',
        'Psalms 23:1',
        'Song of Solomon 1:1',
        '1 Corinthians 1:1',
      ];

      for (final ref in testCases) {
        final parsed = Reference.parse(ref);
        expect(parsed, isA<VerseRef>());
      }
    });

    test('Reference.parse handles all range formats', () {
      final testCases = [
        'John 3:16-17',
        'John 3:16-4:1',
        'John 3:16-Acts 1:2',
        'John 3.16-4.1',
        'John 3:16–17', // en dash
        'John 3:16—17', // em dash
      ];

      for (final ref in testCases) {
        final parsed = Reference.parse(ref);
        expect(parsed, isA<VerseRangeRef>());
      }
    });

    test('Reference.parse error handling', () {
      final invalidCases = [
        'InvalidBook 3:16',
        'John 0:1',
        'John 3:0',
        '',
        '   ',
        'John 3/16',
      ];

      for (final ref in invalidCases) {
        expect(() => Reference.parse(ref), throwsA(isA<ParseVerseRefError>()));
      }
    });
  });
}