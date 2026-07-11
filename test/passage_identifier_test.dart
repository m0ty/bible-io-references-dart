import 'package:bible_io_references/reference_identifiers.dart';
import 'package:bible_io_references/references.dart';
import 'package:bible_io_references/bible_book_enum.dart';
import 'package:test/test.dart';

void main() {
  group('passage OSIS identifiers', () {
    test('serializes books and chapters', () {
      expect(
        const BookPassage(BibleBookEnum.john).osisIdentifier,
        'John',
      );
      expect(
        ChapterPassage(BibleBookEnum.john, 3).osisIdentifier,
        'John.3',
      );
      expect(
        ChapterPassage(BibleBookEnum.john, 3, 4).osisIdentifier,
        'John.3-John.4',
      );
    });

    test('joins complete verse-selection identifiers with spaces', () {
      final passage = Passage.parse('John 3:16,18-20');

      expect(
        passage.osisIdentifier,
        'John.3.16 John.3.18-John.3.20',
      );
    });

    test('joins sequence expressions unambiguously', () {
      final passage = Passage.parse('John; John 3; Acts 2:1-4');

      expect(
        passage.osisIdentifier,
        'John John.3 Acts.2.1-Acts.2.4',
      );
    });
  });

  group('passage USFM identifiers', () {
    test('serializes books and chapters', () {
      expect(
        const BookPassage(BibleBookEnum.john).usfmIdentifier,
        'JHN',
      );
      expect(
        ChapterPassage(BibleBookEnum.john, 3).usfmIdentifier,
        'JHN 3',
      );
      expect(
        ChapterPassage(BibleBookEnum.john, 3, 4).usfmIdentifier,
        'JHN 3-4',
      );
    });

    test('compacts same-book and same-chapter verse selections', () {
      final passage = Passage.parse('John 3:16,18-20');

      expect(
        passage.usfmIdentifier,
        'JHN 3:16,18-20',
      );
    });

    test('uses complete identifiers when selection context changes', () {
      final passage = Passage.parse('John 3:16,4:1-2');

      expect(
        passage.usfmIdentifier,
        'JHN 3:16,JHN 4:1-2',
      );
    });

    test('joins sequence expressions unambiguously', () {
      final passage = Passage.parse('John; John 3; Acts 2:1-4');

      expect(
        passage.usfmIdentifier,
        'JHN; JHN 3; ACT 2:1-4',
      );
    });
  });

  test('does not change existing Reference identifiers', () {
    const reference = VerseRef(
      book: BibleBookEnum.john,
      chapter: 3,
      verse: 16,
    );
    final singletonPassage = VersePassage([reference]);

    expect(reference.osisIdentifier, 'John.3.16');
    expect(reference.usfmIdentifier, 'JHN 3:16');
    expect(singletonPassage.osisIdentifier, reference.osisIdentifier);
    expect(singletonPassage.usfmIdentifier, reference.usfmIdentifier);
  });
}
