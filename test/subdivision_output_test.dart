import 'package:bible_io_references/bible_book_enum.dart';
import 'package:bible_io_references/bible_language_enum.dart';
import 'package:bible_io_references/reference_formatter.dart';
import 'package:bible_io_references/reference_identifiers.dart';
import 'package:bible_io_references/references.dart';
import 'package:test/test.dart';

void main() {
  const verse = VerseRef(
    book: BibleBookEnum.john,
    chapter: 1,
    verse: 5,
    subdivision: 'a',
  );
  const sameVerseRange = VerseRangeRef(
    start: verse,
    end: VerseRef(
      book: BibleBookEnum.john,
      chapter: 1,
      verse: 5,
      subdivision: 'b',
    ),
  );
  const crossChapterRange = VerseRangeRef(
    start: verse,
    end: VerseRef(
      book: BibleBookEnum.john,
      chapter: 2,
      verse: 1,
      subdivision: 'b',
    ),
  );
  const crossBookRange = VerseRangeRef(
    start: VerseRef(
      book: BibleBookEnum.john,
      chapter: 21,
      verse: 25,
      subdivision: 'b',
    ),
    end: VerseRef(
      book: BibleBookEnum.acts,
      chapter: 1,
      verse: 2,
      subdivision: 'a',
    ),
  );

  group('subdivision formatting', () {
    test('retains subdivisions with localized long and short book names', () {
      expect(verse.format(), 'John 1:5a');
      expect(
        verse.format(language: BibleLanguageEnum.spanish),
        'Juan 1:5a',
      );
      expect(
        verse.format(
          language: BibleLanguageEnum.spanish,
          bookNameStyle: ReferenceBookNameStyle.short,
        ),
        'Jn 1:5a',
      );
    });

    test('retains both subdivisions in every range shape', () {
      expect(sameVerseRange.format(), 'John 1:5a-5b');
      expect(
        sameVerseRange.format(compactRanges: false),
        'John 1:5a-John 1:5b',
      );
      expect(crossChapterRange.format(), 'John 1:5a-2:1b');
      expect(crossBookRange.format(), 'John 21:25b-Acts 1:2a');
    });

    test('retains subdivisions in compact passage selections', () {
      final passage = VersePassage([
        verse,
        verse.copyWith(subdivision: 'b'),
        sameVerseRange,
        verse.copyWith(chapter: 2),
        crossChapterRange,
        crossBookRange,
      ]);

      expect(
        passage.format(),
        'John 1:5a,5b,5a-5b,2:5a,5a-2:1b,John 21:25b-Acts 1:2a',
      );
      expect(
        passage.format(compactRanges: false),
        'John 1:5a,John 1:5b,John 1:5a-John 1:5b,John 2:5a,'
        'John 1:5a-John 2:1b,John 21:25b-Acts 1:2a',
      );
    });

    test('retains subdivisions in ranges relative to another chapter', () {
      final passage = VersePassage([
        verse,
        VerseRangeRef(
          start: verse.copyWith(chapter: 2),
          end: verse.copyWith(chapter: 2, subdivision: 'b'),
        ),
      ]);
      expect(passage.format(), 'John 1:5a,2:5a-5b');
    });
  });

  group('subdivision machine identifiers', () {
    test('serialize subdivisions using each format\'s syntax', () {
      expect(verse.osisIdentifier, 'John.1.5!a');
      expect(verse.usfmIdentifier, 'JHN 1:5a');
      expect(sameVerseRange.osisIdentifier, 'John.1.5!a-John.1.5!b');
      expect(sameVerseRange.usfmIdentifier, 'JHN 1:5a-5b');
      expect(crossChapterRange.osisIdentifier, 'John.1.5!a-John.2.1!b');
      expect(crossChapterRange.usfmIdentifier, 'JHN 1:5a-2:1b');
      expect(crossBookRange.osisIdentifier, 'John.21.25!b-Acts.1.2!a');
      expect(crossBookRange.usfmIdentifier, 'JHN-ACT 21:25b-1:2a');
    });

    test('round-trip every supported subdivision in every book', () {
      for (final book in BibleBookEnum.values) {
        for (var letter = 97; letter <= 122; letter++) {
          final reference = VerseRef.checked(
            book: book,
            chapter: 1,
            verse: 1,
            subdivision: String.fromCharCode(letter),
          );
          expect(
            referenceFromOsisIdentifier(reference.osisIdentifier),
            reference,
          );
          expect(
            referenceFromUsfmIdentifier(reference.usfmIdentifier),
            reference,
          );
        }
      }
    });

    test('round-trip ranges with subdivided or whole verse endpoints', () {
      final ranges = [
        sameVerseRange,
        crossChapterRange,
        crossBookRange,
        VerseRangeRef(
          start: verse,
          end: const VerseRef(book: BibleBookEnum.john, chapter: 1, verse: 6),
        ),
        VerseRangeRef(
          start: const VerseRef(book: BibleBookEnum.john, chapter: 1, verse: 4),
          end: verse,
        ),
      ];
      for (final range in ranges) {
        expect(referenceFromOsisIdentifier(range.osisIdentifier), range);
        expect(referenceFromUsfmIdentifier(range.usfmIdentifier), range);
      }
    });

    test('retains subdivisions in all passage identifier selections', () {
      final passage = VersePassage([
        verse,
        verse.copyWith(subdivision: 'b'),
        sameVerseRange,
        crossChapterRange,
        crossBookRange,
      ]);
      expect(
        passage.osisIdentifier,
        'John.1.5!a John.1.5!b John.1.5!a-John.1.5!b '
        'John.1.5!a-John.2.1!b John.21.25!b-Acts.1.2!a',
      );
      expect(
        passage.usfmIdentifier,
        'JHN 1:5a,5b,5a-5b,JHN 1:5a-2:1b,JHN-ACT 21:25b-1:2a',
      );

      final sequence = PassageSequence([
        const BookPassage(BibleBookEnum.john),
        passage,
      ]);
      expect(sequence.osisIdentifier, 'John ${passage.osisIdentifier}');
      expect(sequence.usfmIdentifier, 'JHN; ${passage.usfmIdentifier}');
    });

    test('rejects malformed and unsupported OSIS subdivisions', () {
      for (final identifier in [
        'John.1.5a',
        'John.1.5!',
        'John.1.5!A',
        'John.1.5!ab',
        'John.1.5!1',
        'John.1.5!a.b',
        'John.1.5!a!b',
        'John.1a.5',
        'John.1.5!a-5!b',
        'John.1.5!b-John.1.5!a',
        'John.1.5!a-John.1.5!a',
        'John.1.5!a ',
        'John.1.5!a\n',
      ]) {
        expect(
          () => referenceFromOsisIdentifier(identifier),
          throwsFormatException,
          reason: identifier,
        );
      }
    });

    test('rejects malformed and unsupported USFM subdivisions', () {
      for (final identifier in [
        'JHN 1:5!a',
        'JHN 1:5A',
        'JHN 1:5ab',
        'JHN 1:5 a',
        'JHN 1a:5',
        'JHN 1:5a-b',
        'JHN 1:5a-2b:1',
        'JHN 1:5b-5a',
        'JHN 1:5a-5a',
        'JHN-ACT 21:25a-1b:2',
        'JHN-ACT 21:25a-1:2ab',
        'JHN 1:5a ',
        'JHN 1:5a\n',
      ]) {
        expect(
          () => referenceFromUsfmIdentifier(identifier),
          throwsFormatException,
          reason: identifier,
        );
      }
    });
  });
}
