import 'package:bible_io_references/bible_book_enum.dart';
import 'package:bible_io_references/reference_identifiers.dart';
import 'package:bible_io_references/references.dart';
import 'package:test/test.dart';

void main() {
  group('book identifiers', () {
    test('cover every supported book with unique valid identifiers', () {
      expect(bibleBookIdentifiers.keys.toSet(), BibleBookEnum.values.toSet());
      expect(bibleBookIdentifiers, hasLength(BibleBookEnum.values.length));

      final osisIdentifiers = <String>{};
      final usfmIdentifiers = <String>{};
      for (final book in BibleBookEnum.values) {
        expect(book.osisIdentifier, matches(RegExp(r'^[A-Za-z0-9]+$')));
        expect(book.usfmIdentifier, matches(RegExp(r'^[A-Z1-4]{3}$')));
        expect(osisIdentifiers.add(book.osisIdentifier), isTrue);
        expect(usfmIdentifiers.add(book.usfmIdentifier), isTrue);
      }
    });

    test('round-trip every OSIS and USFM book identifier', () {
      for (final book in BibleBookEnum.values) {
        expect(bibleBookFromOsisIdentifier(book.osisIdentifier), book);
        expect(bibleBookFromUsfmIdentifier(book.usfmIdentifier), book);
      }
    });

    test('use explicit identifiers for separately modeled additions', () {
      expect(BibleBookEnum.estherAdditions.osisIdentifier, 'AddEsth');
      expect(BibleBookEnum.estherAdditions.usfmIdentifier, 'ADE');
      expect(BibleBookEnum.danielSongOfThree.osisIdentifier, 'PrAzar');
      expect(BibleBookEnum.danielSongOfThree.usfmIdentifier, 'S3Y');
      expect(BibleBookEnum.danielSusanna.osisIdentifier, 'Sus');
      expect(BibleBookEnum.danielSusanna.usfmIdentifier, 'SUS');
      expect(BibleBookEnum.danielBelAndTheDragon.osisIdentifier, 'Bel');
      expect(BibleBookEnum.danielBelAndTheDragon.usfmIdentifier, 'BEL');
      expect(BibleBookEnum.psalm151.osisIdentifier, 'AddPs');
      expect(BibleBookEnum.psalm151.usfmIdentifier, 'PS2');
    });

    test('reject unknown, non-canonical, or wrong-case book identifiers', () {
      for (final invalid in ['', 'John ', 'john', 'Ps151', 'Unknown']) {
        expect(
          () => bibleBookFromOsisIdentifier(invalid),
          throwsArgumentError,
          reason: invalid,
        );
      }
      for (final invalid in ['', 'JHN ', 'jhn', 'JOH', 'ESG', 'XXX']) {
        expect(
          () => bibleBookFromUsfmIdentifier(invalid),
          throwsArgumentError,
          reason: invalid,
        );
      }
    });
  });

  group('OSIS reference identifiers', () {
    test('serialize verses and ranges with full endpoints', () {
      const verse = VerseRef(
        book: BibleBookEnum.john,
        chapter: 3,
        verse: 16,
      );
      const sameBookRange = VerseRangeRef(
        start: VerseRef(
          book: BibleBookEnum.secondCorinthians,
          chapter: 6,
          verse: 14,
        ),
        end: VerseRef(
          book: BibleBookEnum.secondCorinthians,
          chapter: 7,
          verse: 1,
        ),
      );
      const crossBookRange = VerseRangeRef(
        start: VerseRef(
          book: BibleBookEnum.john,
          chapter: 21,
          verse: 25,
        ),
        end: VerseRef(
          book: BibleBookEnum.acts,
          chapter: 1,
          verse: 2,
        ),
      );

      expect(verse.osisIdentifier, 'John.3.16');
      expect(
        sameBookRange.osisIdentifier,
        '2Cor.6.14-2Cor.7.1',
      );
      expect(
        crossBookRange.osisIdentifier,
        'John.21.25-Acts.1.2',
      );
    });

    test('parse and round-trip verses for every supported book', () {
      for (final book in BibleBookEnum.values) {
        final verse = VerseRef.checked(book: book, chapter: 1, verse: 1);
        expect(referenceFromOsisIdentifier(verse.osisIdentifier), verse);
      }
    });

    test('parse same-chapter, cross-chapter, and cross-book ranges', () {
      final identifiers = [
        'John.3.16-John.3.17',
        'John.3.16-John.4.1',
        'John.21.25-Acts.1.2',
      ];

      for (final identifier in identifiers) {
        final reference = referenceFromOsisIdentifier(identifier);
        expect(reference, isA<VerseRangeRef>());
        expect(reference.osisIdentifier, identifier);
      }
    });

    test('reject malformed, unknown, invalid, and descending identifiers', () {
      final invalidIdentifiers = [
        '',
        'John',
        'John.3',
        'John.3.16-17',
        'john.3.16',
        'Unknown.3.16',
        'John.0.16',
        'John.3.0',
        'John.1000.1',
        'John.1.1000',
        'John.4.1-John.3.16',
        'Acts.1.2-John.21.25',
        'John.3.16-John.3.16',
        ' John.3.16',
      ];

      for (final identifier in invalidIdentifiers) {
        expect(
          () => referenceFromOsisIdentifier(identifier),
          throwsFormatException,
          reason: identifier,
        );
      }
    });
  });

  group('USFM reference identifiers', () {
    test('serialize standard compact shapes and cross-book extension', () {
      const verse = VerseRef(
        book: BibleBookEnum.john,
        chapter: 3,
        verse: 16,
      );
      const sameChapterRange = VerseRangeRef(
        start: VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
        ),
        end: VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 17,
        ),
      );
      const crossChapterRange = VerseRangeRef(
        start: VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
        ),
        end: VerseRef(
          book: BibleBookEnum.john,
          chapter: 4,
          verse: 1,
        ),
      );
      const crossBookRange = VerseRangeRef(
        start: VerseRef(
          book: BibleBookEnum.john,
          chapter: 21,
          verse: 25,
        ),
        end: VerseRef(
          book: BibleBookEnum.acts,
          chapter: 1,
          verse: 2,
        ),
      );

      expect(verse.usfmIdentifier, 'JHN 3:16');
      expect(sameChapterRange.usfmIdentifier, 'JHN 3:16-17');
      expect(crossChapterRange.usfmIdentifier, 'JHN 3:16-4:1');
      expect(crossBookRange.usfmIdentifier, 'JHN-ACT 21:25-1:2');
    });

    test('parse and round-trip verses for every supported book', () {
      for (final book in BibleBookEnum.values) {
        final verse = VerseRef.checked(book: book, chapter: 1, verse: 1);
        expect(referenceFromUsfmIdentifier(verse.usfmIdentifier), verse);
      }
    });

    test('parse same-chapter, cross-chapter, and cross-book ranges', () {
      final identifiers = [
        'JHN 3:16-17',
        'JHN 3:16-4:1',
        'JHN-ACT 21:25-1:2',
      ];

      for (final identifier in identifiers) {
        final reference = referenceFromUsfmIdentifier(identifier);
        expect(reference, isA<VerseRangeRef>());
        expect(reference.usfmIdentifier, identifier);
      }
    });

    test('reject malformed, unknown, invalid, and descending identifiers', () {
      final invalidIdentifiers = [
        '',
        'JHN',
        'JHN 3',
        'JHN.3.16',
        'jhn 3:16',
        'XXX 3:16',
        'JHN 0:16',
        'JHN 3:0',
        'JHN 1000:1',
        'JHN 1:1000',
        'JHN 4:1-3:16',
        'ACT-JHN 1:2-21:25',
        'JHN 3:16-16',
        ' JHN 3:16',
      ];

      for (final identifier in invalidIdentifiers) {
        expect(
          () => referenceFromUsfmIdentifier(identifier),
          throwsFormatException,
          reason: identifier,
        );
      }
    });
  });
}
