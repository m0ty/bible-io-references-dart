import 'package:bible_io_references/bible_book_enum.dart';
import 'package:bible_io_references/canon_profile.dart';
import 'package:bible_io_references/reference_limits.dart';
import 'package:bible_io_references/versification_profile.dart';
import 'package:test/test.dart';

void main() {
  group('King James versification', () {
    final profile = VersificationProfile.kingJames;

    test('contains complete Protestant bounds and expected total', () {
      expect(profile.id, 'kjv');
      expect(profile.canon, same(CanonProfile.protestant));
      expect(profile.verseCountsByBook.length, 66);
      expect(profile.totalVerseCount, 31102);
      expect(VersificationProfile.protestant, same(profile));

      expect(profile.chapterCount(BibleBookEnum.genesis), 50);
      expect(profile.verseCount(BibleBookEnum.genesis, 1), 31);
      expect(profile.chapterCount(BibleBookEnum.psalms), 150);
      expect(profile.verseCount(BibleBookEnum.psalms, 119), 176);
      expect(profile.verseCount(BibleBookEnum.john, 3), 36);
      expect(profile.verseCount(BibleBookEnum.thirdJohn, 1), 14);
      expect(profile.verseCount(BibleBookEnum.revelation, 12), 17);
      expect(profile.verseCount(BibleBookEnum.revelation, 22), 21);
    });

    test('maps canonical coordinates to zero-based ordinals and back', () {
      expect(
        profile.ordinalOf(
          book: BibleBookEnum.genesis,
          chapter: 1,
          verse: 1,
        ),
        0,
      );
      expect(
        profile.ordinalOf(
          book: BibleBookEnum.genesis,
          chapter: 1,
          verse: 31,
        ),
        30,
      );
      expect(
        profile.ordinalOf(
          book: BibleBookEnum.genesis,
          chapter: 2,
          verse: 1,
        ),
        31,
      );
      expect(
        profile.ordinalOf(
          book: BibleBookEnum.exodus,
          chapter: 1,
          verse: 1,
        ),
        1533,
      );

      expect(
        profile.coordinateAt(0),
        const VersificationCoordinate(
          book: BibleBookEnum.genesis,
          chapter: 1,
          verse: 1,
        ),
      );
      expect(
        profile.coordinateAt(profile.totalVerseCount - 1),
        const VersificationCoordinate(
          book: BibleBookEnum.revelation,
          chapter: 22,
          verse: 21,
        ),
      );

      final john316 = profile.ordinalOf(
        book: BibleBookEnum.john,
        chapter: 3,
        verse: 16,
      );
      expect(
        profile.coordinateAt(john316),
        const VersificationCoordinate(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
        ),
      );
    });

    test('validates invalid books, chapters, verses, and ordinals', () {
      expect(
        () => profile.chapterCount(BibleBookEnum.tobit),
        _throwsCode(ReferenceValidationErrorCode.bookNotInCanon),
      );
      expect(
        () => profile.verseCount(BibleBookEnum.john, 22),
        _throwsCode(ReferenceValidationErrorCode.chapterOutOfRange),
      );
      expect(
        () => profile.validateCoordinate(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 37,
        ),
        _throwsCode(ReferenceValidationErrorCode.verseOutOfRange),
      );
      expect(
        () => profile.coordinateAt(-1),
        _throwsCode(ReferenceValidationErrorCode.ordinalOutOfRange),
      );
      expect(
        () => profile.coordinateAt(profile.totalVerseCount),
        _throwsCode(ReferenceValidationErrorCode.ordinalOutOfRange),
      );
    });

    test('compares coordinates in canonical order', () {
      const earlier = VersificationCoordinate(
        book: BibleBookEnum.malachi,
        chapter: 4,
        verse: 6,
      );
      const later = VersificationCoordinate(
        book: BibleBookEnum.matthew,
        chapter: 1,
        verse: 1,
      );

      expect(profile.compareCoordinates(earlier, later), lessThan(0));
      expect(profile.compareCoordinates(later, earlier), greaterThan(0));
      expect(profile.compareCoordinates(earlier, earlier), 0);
    });
  });

  group('custom versification profiles', () {
    final canon = CanonProfile(
      id: 'two-books',
      displayName: 'Two Books',
      books: const [BibleBookEnum.genesis, BibleBookEnum.exodus],
    );

    test('defensively copies data and provides value equality', () {
      final genesisCounts = <int>[2, 3];
      final source = <BibleBookEnum, Iterable<int>>{
        BibleBookEnum.genesis: genesisCounts,
        BibleBookEnum.exodus: <int>[1],
      };
      final profile = VersificationProfile(
        id: 'tiny',
        displayName: 'Tiny',
        canon: canon,
        verseCountsByBook: source,
      );
      final equalProfile = VersificationProfile(
        id: 'tiny',
        displayName: 'Tiny',
        canon: canon,
        verseCountsByBook: const {
          BibleBookEnum.genesis: [2, 3],
          BibleBookEnum.exodus: [1],
        },
      );

      genesisCounts[0] = 99;
      source[BibleBookEnum.genesis] = const [8];

      expect(profile.verseCount(BibleBookEnum.genesis, 1), 2);
      expect(profile.totalVerseCount, 6);
      expect(profile, equalProfile);
      expect(profile.hashCode, equalProfile.hashCode);
      expect(
        () => profile.verseCountsByBook[BibleBookEnum.genesis] = const [4],
        throwsUnsupportedError,
      );
      expect(
        () => profile.verseCountsByBook[BibleBookEnum.genesis]!.add(4),
        throwsUnsupportedError,
      );
    });

    test('rejects incomplete, extra, empty, and non-positive data', () {
      expect(
        () => VersificationProfile(
          id: 'missing',
          displayName: 'Missing',
          canon: canon,
          verseCountsByBook: const {
            BibleBookEnum.genesis: [1]
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => VersificationProfile(
          id: 'extra',
          displayName: 'Extra',
          canon: canon,
          verseCountsByBook: const {
            BibleBookEnum.genesis: [1],
            BibleBookEnum.exodus: [1],
            BibleBookEnum.leviticus: [1],
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => VersificationProfile(
          id: 'empty',
          displayName: 'Empty',
          canon: canon,
          verseCountsByBook: const {
            BibleBookEnum.genesis: <int>[],
            BibleBookEnum.exodus: [1],
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => VersificationProfile(
          id: 'zero',
          displayName: 'Zero',
          canon: canon,
          verseCountsByBook: const {
            BibleBookEnum.genesis: [0],
            BibleBookEnum.exodus: [1],
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects coordinates outside the Reference model limits', () {
      expect(
        () => VersificationProfile(
          id: 'too-many-chapters',
          displayName: 'Too Many Chapters',
          canon: CanonProfile(
            id: 'one-book',
            displayName: 'One Book',
            books: const [BibleBookEnum.genesis],
          ),
          verseCountsByBook: {
            BibleBookEnum.genesis: List.filled(
              maxReferenceChapterNumber + 1,
              1,
            ),
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => VersificationProfile(
          id: 'too-many-verses',
          displayName: 'Too Many Verses',
          canon: CanonProfile(
            id: 'one-book',
            displayName: 'One Book',
            books: const [BibleBookEnum.genesis],
          ),
          verseCountsByBook: const {
            BibleBookEnum.genesis: [maxReferenceVerseNumber + 1],
          },
        ),
        throwsArgumentError,
      );
    });
  });
}

Matcher _throwsCode(ReferenceValidationErrorCode code) => throwsA(
      isA<ReferenceValidationException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );
