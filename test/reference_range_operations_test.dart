import 'package:bible_io_references/bible_book_enum.dart';
import 'package:bible_io_references/canon_profile.dart';
import 'package:bible_io_references/reference_range_operations.dart';
import 'package:bible_io_references/references.dart';
import 'package:bible_io_references/versification_profile.dart';
import 'package:test/test.dart';

void main() {
  final profile = VersificationProfile.kingJames;

  VerseRef verse(
    BibleBookEnum book,
    int chapter,
    int verseNumber,
  ) =>
      VerseRef.checked(book: book, chapter: chapter, verse: verseNumber);

  VerseRangeRef range(
    BibleBookEnum book,
    int startChapter,
    int startVerse,
    int endChapter,
    int endVerse,
  ) =>
      VerseRangeRef.checked(
        start: verse(book, startChapter, startVerse),
        end: verse(book, endChapter, endVerse),
      );

  group('endpoints and containment', () {
    test('treats a single verse as a one-verse inclusive span', () {
      final john316 = verse(BibleBookEnum.john, 3, 16);

      expect(john316.firstVerse, same(john316));
      expect(john316.lastVerse, same(john316));
      expect(john316.contains(john316, profile: profile), isTrue);
      expect(john316.intersects(john316, profile: profile), isTrue);
      expect(john316.verseCount(profile: profile), 1);
      expect(john316.verses(profile: profile), [john316]);
    });

    test('contains endpoints and complete subranges', () {
      final span = range(BibleBookEnum.john, 3, 16, 3, 20);
      final subrange = range(BibleBookEnum.john, 3, 17, 3, 19);

      expect(span.firstVerse, verse(BibleBookEnum.john, 3, 16));
      expect(span.lastVerse, verse(BibleBookEnum.john, 3, 20));
      expect(
        span.contains(verse(BibleBookEnum.john, 3, 16), profile: profile),
        isTrue,
      );
      expect(
        span.contains(verse(BibleBookEnum.john, 3, 20), profile: profile),
        isTrue,
      );
      expect(span.contains(subrange, profile: profile), isTrue);
      expect(subrange.contains(span, profile: profile), isFalse);
      expect(
        span.contains(verse(BibleBookEnum.john, 3, 15), profile: profile),
        isFalse,
      );
      expect(
        span.contains(verse(BibleBookEnum.john, 3, 21), profile: profile),
        isFalse,
      );
    });

    test('intersection is inclusive, symmetric, and excludes adjacency', () {
      final left = range(BibleBookEnum.john, 3, 16, 3, 20);
      final sharingEndpoint = range(BibleBookEnum.john, 3, 20, 3, 24);
      final adjacent = range(BibleBookEnum.john, 3, 21, 3, 24);

      expect(left.intersects(sharingEndpoint, profile: profile), isTrue);
      expect(sharingEndpoint.intersects(left, profile: profile), isTrue);
      expect(left.intersects(adjacent, profile: profile), isFalse);
      expect(adjacent.intersects(left, profile: profile), isFalse);
    });
  });

  group('merge', () {
    test('merges overlap and containment symmetrically', () {
      final left = range(BibleBookEnum.john, 3, 16, 3, 20);
      final right = range(BibleBookEnum.john, 3, 18, 3, 24);
      final expected = range(BibleBookEnum.john, 3, 16, 3, 24);

      expect(left.merge(right, profile: profile), expected);
      expect(right.merge(left, profile: profile), expected);
      expect(
        expected.merge(left, profile: profile),
        expected,
      );
    });

    test('merges adjacent references unless adjacency is disabled', () {
      final left = range(BibleBookEnum.john, 3, 16, 3, 20);
      final right = verse(BibleBookEnum.john, 3, 21);
      final expected = range(BibleBookEnum.john, 3, 16, 3, 21);

      expect(left.merge(right, profile: profile), expected);
      expect(right.merge(left, profile: profile), expected);
      expect(
        left.merge(
          right,
          profile: profile,
          includeAdjacent: false,
        ),
        isNull,
      );
    });

    test('does not fill a hole', () {
      final john316 = verse(BibleBookEnum.john, 3, 16);
      final john318 = verse(BibleBookEnum.john, 3, 18);

      expect(john316.merge(john318, profile: profile), isNull);
      expect(john318.merge(john316, profile: profile), isNull);
    });

    test('keeps an identical one-verse union as a VerseRef', () {
      final john316 = verse(BibleBookEnum.john, 3, 16);
      final merged = john316.merge(john316, profile: profile);

      expect(merged, john316);
      expect(merged, isA<VerseRef>());
    });
  });

  group('iteration and length', () {
    test('iterates inclusively within one chapter', () {
      final span = range(BibleBookEnum.john, 3, 16, 3, 18);

      expect(
        span.verses(profile: profile),
        [
          verse(BibleBookEnum.john, 3, 16),
          verse(BibleBookEnum.john, 3, 17),
          verse(BibleBookEnum.john, 3, 18),
        ],
      );
      expect(span.verseCount(profile: profile), 3);
    });

    test('crosses a chapter boundary using real verse counts', () {
      final span = range(BibleBookEnum.john, 3, 35, 4, 2);
      final expanded = span.verses(profile: profile).toList();

      expect(
        expanded,
        [
          verse(BibleBookEnum.john, 3, 35),
          verse(BibleBookEnum.john, 3, 36),
          verse(BibleBookEnum.john, 4, 1),
          verse(BibleBookEnum.john, 4, 2),
        ],
      );
      expect(span.verseCount(profile: profile), expanded.length);
    });

    test('crosses a book boundary in canonical order', () {
      final span = VerseRangeRef(
        start: verse(BibleBookEnum.malachi, 4, 6),
        end: verse(BibleBookEnum.matthew, 1, 2),
      );

      expect(
        span.verses(profile: profile),
        [
          verse(BibleBookEnum.malachi, 4, 6),
          verse(BibleBookEnum.matthew, 1, 1),
          verse(BibleBookEnum.matthew, 1, 2),
        ],
      );
      expect(span.verseCount(profile: profile), 3);
    });

    test('merges adjacent references across a book boundary', () {
      final malachiEnd = verse(BibleBookEnum.malachi, 4, 6);
      final matthewStart = verse(BibleBookEnum.matthew, 1, 1);

      expect(
        malachiEnd.merge(matthewStart, profile: profile),
        VerseRangeRef(start: malachiEnd, end: matthewStart),
      );
      expect(
        malachiEnd.intersects(matthewStart, profile: profile),
        isFalse,
      );
    });

    test('uses profile order instead of BibleBookEnum.index', () {
      final customCanon = CanonProfile(
        id: 'test-order',
        displayName: 'Test order',
        books: [BibleBookEnum.tobit, BibleBookEnum.matthew],
      );
      final customProfile = VersificationProfile(
        id: 'test-order',
        displayName: 'Test order',
        canon: customCanon,
        verseCountsByBook: {
          BibleBookEnum.tobit: [1],
          BibleBookEnum.matthew: [1],
        },
      );
      final span = VerseRangeRef(
        start: verse(BibleBookEnum.tobit, 1, 1),
        end: verse(BibleBookEnum.matthew, 1, 1),
      );

      expect(span.verseCount(profile: customProfile), 2);
      expect(
        span.verses(profile: customProfile),
        [
          verse(BibleBookEnum.tobit, 1, 1),
          verse(BibleBookEnum.matthew, 1, 1),
        ],
      );
    });
  });

  group('validation', () {
    test('propagates typed invalid-verse errors', () {
      final invalid = verse(BibleBookEnum.john, 3, 99);

      expect(
        () => invalid.verseCount(profile: profile),
        throwsA(
          isA<ReferenceValidationException>().having(
            (error) => error.code,
            'code',
            ReferenceValidationErrorCode.verseOutOfRange,
          ),
        ),
      );
      expect(
        () => invalid.verses(profile: profile),
        throwsA(isA<ReferenceValidationException>()),
      );
      expect(
        () => invalid.contains(
          verse(BibleBookEnum.john, 3, 16),
          profile: profile,
        ),
        throwsA(isA<ReferenceValidationException>()),
      );
    });

    test('propagates typed canon-membership errors', () {
      final tobit = verse(BibleBookEnum.tobit, 1, 1);

      expect(
        () => tobit.verseCount(profile: profile),
        throwsA(
          isA<ReferenceValidationException>().having(
            (error) => error.code,
            'code',
            ReferenceValidationErrorCode.bookNotInCanon,
          ),
        ),
      );
    });

    test('rejects raw ranges that descend in profile order', () {
      final reversed = VerseRangeRef(
        start: verse(BibleBookEnum.john, 4, 1),
        end: verse(BibleBookEnum.john, 3, 36),
      );

      expect(
        () => reversed.verseCount(profile: profile),
        throwsArgumentError,
      );
      expect(
        () => reversed.verses(profile: profile),
        throwsArgumentError,
      );
      expect(
        () => reversed.intersects(
          verse(BibleBookEnum.john, 4, 1),
          profile: profile,
        ),
        throwsArgumentError,
      );
      expect(
        () => reversed.merge(
          verse(BibleBookEnum.john, 4, 1),
          profile: profile,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a raw range with identical endpoints', () {
      final endpoint = verse(BibleBookEnum.john, 3, 16);
      final degenerate = VerseRangeRef(start: endpoint, end: endpoint);

      expect(
        () => degenerate.verseCount(profile: profile),
        throwsArgumentError,
      );
    });
  });
}
