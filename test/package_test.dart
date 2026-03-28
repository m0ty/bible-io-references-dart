import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Basic parsing', () {
    test('parse verse ref', () {
      final ref = verseRefFromStr('John 3:16');
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
      expect(ref.toString(), 'John 3:16');
    });

    test('parse verse ref with dot separator', () {
      final ref = verseRefFromStr('John 3.16');
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse verse ref with abbreviation', () {
      final ref = verseRefFromStr('jo 1:1');
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 1);
      expect(ref.verse, 1);
    });

    test('parse verse range ref', () {
      final ref = verseRangeRefFromStr('John 3:16-17');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
      expect(ref.toString(), 'John 3:16-17');
    });

    test('parse verse range ref with en dash', () {
      final ref = verseRangeRefFromStr('John 3:16–17');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    test('parse verse range ref with em dash', () {
      final ref = verseRangeRefFromStr('John 3:16—17');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });

    test('parse cross-chapter range', () {
      final ref = verseRangeRefFromStr('John 3:16-4:1');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 4);
      expect(ref.end.verse, 1);
      expect(ref.toString(), 'John 3:16-4:1');
    });

    test('parse cross-book range', () {
      final ref = verseRangeRefFromStr('John 3:16-Acts 1:2');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.acts);
      expect(ref.end.chapter, 1);
      expect(ref.end.verse, 2);
      expect(ref.toString(), 'John 3:16-Acts 1:2');
    });

    test('parse range with dot separators', () {
      final ref = verseRangeRefFromStr('John 3.16-4.1');
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 4);
      expect(ref.end.verse, 1);
    });
  });

  group('Auto language functionality', () {
    test('auto language prefers English abbreviations on collisions', () {
      final ref = verseRefFromStr('jud 1:1');
      expect(ref.book, BibleBookEnum.judges);
    });

    test('auto language prefers English for Song of Solomon', () {
      final ref = verseRefFromStr('so 1:1');
      expect(ref.book, BibleBookEnum.songOfSolomon);
    });

    test('auto language prefers English for Jonah', () {
      final ref = verseRefFromStr('jn 1:1');
      expect(ref.book, BibleBookEnum.jonah);
    });

    test('auto language falls back to non-English terms', () {
      final ref = verseRefFromStr('Juan 1:1');
      expect(ref.book, BibleBookEnum.john);
    });

    test('auto language precedence order', () {
      expect(autoLanguagePrecedence, [
        'ar', 'zh', 'fr', 'de', 'he', 'hi', 'id', 'ko', 'pt', 'ru', 'es', 'tl'
      ]);
    });

    test('auto language collision metadata', () {
      expect(autoLanguageCollisions.containsKey('jn'), isTrue);
      expect(autoLanguageCollisions.containsKey('jud'), isTrue);
      expect(autoLanguageCollisions['jn']!.contains(BibleBookEnum.john), isTrue);
      expect(autoLanguageCollisions['jn']!.contains(BibleBookEnum.jonah), isTrue);
    });
  });

  group('Error handling', () {
    test('parse invalid reference raises error', () {
      expect(() => verseRefFromStr('NotABook 3:16'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse non-positive chapter raises error', () {
      expect(() => verseRefFromStr('John 0:1'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRefFromStr('John -1:1'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse non-positive verse raises error', () {
      expect(() => verseRefFromStr('John 1:0'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRefFromStr('John 1:-1'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse range with invalid start raises error', () {
      expect(() => verseRangeRefFromStr('NotABook 3:16-17'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse range with invalid end raises error', () {
      expect(() => verseRangeRefFromStr('John 3:16-NotABook 1:1'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse range with non-positive numbers raises error', () {
      expect(() => verseRangeRefFromStr('John 0:1-2'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRangeRefFromStr('John 1:0-2'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRangeRefFromStr('John 1:1-0'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse range end before start raises error', () {
      expect(() => verseRangeRefFromStr('John 3:17-16'), throwsA(isA<ParseVerseRefError>()));
      expect(() => verseRangeRefFromStr('John 3:16-3:16'), throwsA(isA<ParseVerseRefError>()));
    });

    test('parse error includes diagnostics', () {
      try {
        verseRefFromStr('NotABook 3:16');
      } catch (e) {
        expect(e, isA<ParseVerseRefError>());
        final error = e as ParseVerseRefError;
        expect(error.code, 'unknown_book');
        expect(error.details, isNotNull);
      }
    });
  });

  group('Reference function', () {
    test('parse reference function returns VerseRef', () {
      final parsed = Reference.parse('John 3:16');
      expect(parsed, isA<VerseRef>());
      final ref = parsed as VerseRef;
      expect(ref.book, BibleBookEnum.john);
    });

    test('parse reference function returns VerseRangeRef', () {
      final parsed = Reference.parse('John 3:16-17');
      expect(parsed, isA<VerseRangeRef>());
      final ref = parsed as VerseRangeRef;
      expect(ref.start.book, BibleBookEnum.john);
    });
  });

  group('Language-specific parsing', () {
    test('parse Spanish reference', () {
      final ref = verseRefFromStr('Juan 3:16', language: BibleLanguageEnum.spanish);
      expect(ref.book, BibleBookEnum.john);
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
    });

    test('parse Spanish range', () {
      final ref = verseRangeRefFromStr('Juan 3:16-17', language: BibleLanguageEnum.spanish);
      expect(ref.start.book, BibleBookEnum.john);
      expect(ref.start.chapter, 3);
      expect(ref.start.verse, 16);
      expect(ref.end.book, BibleBookEnum.john);
      expect(ref.end.chapter, 3);
      expect(ref.end.verse, 17);
    });
  });

  group('All books parsing', () {
    for (final book in BibleBookEnum.values) {
      test('parse ${book.fullName} with colon separator', () {
        final ref = verseRefFromStr('${book.fullName} 1:1');
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });

      test('parse ${book.fullName} with dot separator', () {
        final ref = verseRefFromStr('${book.fullName} 1.1');
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });

      test('parse ${book.asStr()} with colon separator', () {
        final ref = verseRefFromStr('${book.asStr()} 1:1');
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });

      test('parse ${book.asStr()} with dot separator', () {
        final ref = verseRefFromStr('${book.asStr()} 1.1');
        expect(ref.book, book);
        expect(ref.chapter, 1);
        expect(ref.verse, 1);
      });
    }
  });

  group('Immutability', () {
    test('VerseRef is immutable', () {
      final ref = verseRefFromStr('John 3:16');
      expect(() => (ref as dynamic).book = BibleBookEnum.matthew, throwsA(anything));
      expect(() => (ref as dynamic).chapter = 4, throwsA(anything));
      expect(() => (ref as dynamic).verse = 17, throwsA(anything));
    });

    test('VerseRangeRef is immutable', () {
      final ref = verseRangeRefFromStr('John 3:16-17');
      expect(() => (ref as dynamic).start = verseRefFromStr('Matt 1:1'), throwsA(anything));
      expect(() => (ref as dynamic).end = verseRefFromStr('Matt 1:2'), throwsA(anything));
    });
  });
}
