import 'dart:async';
import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Concurrent parsing tests', () {
    test('concurrent verse reference parsing', () async {
      final testRefs = [
        'John 3:16',
        'Matthew 1:1',
        'Psalms 23:1',
        'Genesis 1:1',
        'Revelation 22:21',
        'Romans 8:28',
        'Proverbs 3:5',
        'Isaiah 40:31',
        'Jeremiah 29:11',
        'Ephesians 2:8',
      ];

      // Run parsing concurrently
      final futures = <Future<VerseRef>>[];
      for (var i = 0; i < 100; i++) {
        for (final ref in testRefs) {
          futures.add(Future(() => verseRefFromStr(ref)));
        }
      }

      final results = await Future.wait(futures);

      expect(results.length, 100 * testRefs.length);
      for (final result in results) {
        expect(result, isA<VerseRef>());
        expect(result.book, isNotNull);
        expect(result.chapter, greaterThan(0));
        expect(result.verse, greaterThan(0));
      }
    });

    test('concurrent range parsing', () async {
      final testRanges = [
        'John 3:16-17',
        'Matthew 1:1-5',
        'Psalms 23:1-6',
        'Genesis 1:1-2:3',
        'Romans 8:28-30',
      ];

      final futures = <Future<VerseRangeRef>>[];
      for (var i = 0; i < 50; i++) {
        for (final range in testRanges) {
          futures.add(Future(() => verseRangeRefFromStr(range)));
        }
      }

      final results = await Future.wait(futures);

      expect(results.length, 50 * testRanges.length);
      for (final result in results) {
        expect(result, isA<VerseRangeRef>());
        expect(result.start.book, isNotNull);
        expect(result.end.book, isNotNull);
      }
    });

    test('concurrent Reference.parse calls', () async {
      final testRefs = [
        'John 3:16',
        'John 3:16-17',
        'Matthew 1:1',
        'Psalms 23:1-6',
        'Genesis 1:1',
      ];

      final futures = <Future<Reference>>[];
      for (var i = 0; i < 50; i++) {
        for (final ref in testRefs) {
          futures.add(Future(() => Reference.parse(ref)));
        }
      }

      final results = await Future.wait(futures);

      expect(results.length, 50 * testRefs.length);
      for (final result in results) {
        expect(result, isA<Reference>());
      }
    });

    test('concurrent auto language parsing', () async {
      final testRefs = [
        'Juan 3:16', // Spanish
        'Jean 3:16', // French
        'João 3:16', // Portuguese
        'John 3:16', // English
        'jn 1:1', // Collision case
      ];

      final futures = <Future<VerseRef>>[];
      for (var i = 0; i < 30; i++) {
        for (final ref in testRefs) {
          futures.add(Future(() => verseRefFromStr(ref)));
        }
      }

      final results = await Future.wait(futures);

      expect(results.length, 30 * testRefs.length);
      for (final result in results) {
        expect(result.book, BibleBookEnum.john);
        expect(result.chapter, anyOf(3, 1));
        expect(result.verse, anyOf(16, 1));
      }
    });

    test('stress test - many concurrent operations', () async {
      final operations = 1000;
      final futures = <Future>[];

      for (var i = 0; i < operations; i++) {
        futures.add(Future(() async {
          // Mix of different operations
          verseRefFromStr('John ${i % 20 + 1}:${i % 25 + 1}');
          if (i % 3 == 0) {
            verseRangeRefFromStr('Matthew ${i % 28 + 1}:${i % 30 + 1}-${i % 28 + 1}:${i % 30 + 2}');
          }
          if (i % 5 == 0) {
            Reference.parse('Psalms ${i % 150 + 1}:${i % 10 + 1}');
          }
        }));
      }

      await Future.wait(futures);
      // If we get here without exceptions, the concurrent operations worked
      expect(true, isTrue);
    });
  });
}