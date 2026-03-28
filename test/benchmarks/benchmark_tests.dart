import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

void main() {
  group('Performance benchmarks', () {
    test('parsing performance - single verses', () {
      final testRefs = [
        'John 3:16',
        'Genesis 1:1',
        'Psalms 23:1',
        'Revelation 22:21',
        'Matthew 1:1',
        'Romans 8:28',
        'Proverbs 3:5',
        'Isaiah 40:31',
        'Jeremiah 29:11',
        'Ephesians 2:8',
      ];

      final iterations = 1000;

      final start = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        for (final ref in testRefs) {
          verseRefFromStr(ref);
        }
      }
      final end = DateTime.now();
      final duration = end.difference(start);

      final totalParses = iterations * testRefs.length;
      final avgTimePerParse = duration.inMicroseconds / totalParses;

      print('Parsed $totalParses references in ${duration.inMilliseconds}ms');
      print('Average time per parse: ${avgTimePerParse.toStringAsFixed(2)}μs');

      // Performance should be reasonable (less than 1ms per parse on average)
      expect(avgTimePerParse, lessThan(1000),
          reason: 'Parsing should be faster than 1ms per reference');
    });

    test('parsing performance - ranges', () {
      final testRefs = [
        'John 3:16-17',
        'Genesis 1:1-2:3',
        'Psalms 23:1-6',
        'Matthew 1:1-16',
        'Romans 8:28-30',
      ];

      final iterations = 1000;

      final start = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        for (final ref in testRefs) {
          verseRangeRefFromStr(ref);
        }
      }
      final end = DateTime.now();
      final duration = end.difference(start);

      final totalParses = iterations * testRefs.length;
      final avgTimePerParse = duration.inMicroseconds / totalParses;

      print('Parsed $totalParses ranges in ${duration.inMilliseconds}ms');
      print('Average time per range parse: ${avgTimePerParse.toStringAsFixed(2)}μs');

      expect(avgTimePerParse, lessThan(2000),
          reason: 'Range parsing should be faster than 2ms per reference');
    });

    test('parsing performance - auto language detection', () {
      final testRefs = [
        'Juan 3:16', // Spanish
        'Jean 3:16', // French
        'João 3:16', // Portuguese
        'Иоанна 3:16', // Russian
        'John 3:16', // English
        'jn 1:1', // Abbreviation collision
        'jud 1:1', // Another collision
      ];

      final iterations = 500;

      final start = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        for (final ref in testRefs) {
          verseRefFromStr(ref); // Auto language
        }
      }
      final end = DateTime.now();
      final duration = end.difference(start);

      final totalParses = iterations * testRefs.length;
      final avgTimePerParse = duration.inMicroseconds / totalParses;

      print('Parsed $totalParses auto-language references in ${duration.inMilliseconds}ms');
      print('Average time per auto-language parse: ${avgTimePerParse.toStringAsFixed(2)}μs');

      expect(avgTimePerParse, lessThan(2000),
          reason: 'Auto language parsing should be reasonable');
    });

    test('memory efficiency - repeated parsing', () {
      // Test that repeated parsing doesn't cause memory leaks
      // This is a basic smoke test - in a real benchmark you'd use a memory profiler
      final refs = <VerseRef>[];

      for (var i = 0; i < 1000; i++) {
        refs.add(verseRefFromStr('John ${i % 21 + 1}:${i % 25 + 1}'));
      }

      expect(refs.length, 1000);
      expect(refs.first.book, BibleBookEnum.john);
      expect(refs.last.book, BibleBookEnum.john);
    });

    test('lookup table initialization performance', () {
      // Test that the global lookup tables are initialized efficiently
      final start = DateTime.now();

      // Access the global instances (should already be initialized)
      final precedence = autoLanguagePrecedence;
      final collisions = autoLanguageCollisions;

      final end = DateTime.now();
      final duration = end.difference(start);

      expect(duration.inMicroseconds, lessThan(1000),
          reason: 'Global lookup table access should be fast');

      expect(precedence, isNotEmpty);
      expect(collisions, isNotEmpty);
    });

    test('enum parsing performance', () {
      final testBooks = BibleBookEnum.values.take(10).toList();
      final iterations = 10000;

      final start = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        for (final book in testBooks) {
          final parsed = BibleBookEnum.fromStr(book.asStr());
          assert(parsed == book);
        }
      }
      final end = DateTime.now();
      final duration = end.difference(start);

      final totalParses = iterations * testBooks.length;
      final avgTimePerParse = duration.inMicroseconds / totalParses;

      print('Parsed $totalParses book abbreviations in ${duration.inMilliseconds}ms');
      print('Average time per book parse: ${avgTimePerParse.toStringAsFixed(2)}μs');

      expect(avgTimePerParse, lessThan(100),
          reason: 'Book abbreviation parsing should be very fast');
    });
  });
}