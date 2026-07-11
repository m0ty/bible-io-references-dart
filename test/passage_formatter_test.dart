import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('localized passage formatting', () {
    test('formats whole books and chapter ranges', () {
      expect(
        const BookPassage(BibleBookEnum.john).format(
          language: BibleLanguageEnum.spanish,
        ),
        'Juan',
      );
      expect(
        ChapterPassage(BibleBookEnum.john, 3, 4).format(
          language: BibleLanguageEnum.spanish,
        ),
        'Juan 3-4',
      );
      expect(
        ChapterPassage(BibleBookEnum.john, 3).format(
          language: BibleLanguageEnum.spanish,
          bookNameStyle: ReferenceBookNameStyle.short,
        ),
        'Jn 3',
      );
    });

    test('preserves compact verse-list notation while localizing its book', () {
      final passage = Passage.parse('John 3:16,18-20,4:1');

      expect(
        passage.format(language: BibleLanguageEnum.spanish),
        'Juan 3:16,18-20,4:1',
      );
      expect(
        passage.format(
          language: BibleLanguageEnum.spanish,
          compactRanges: false,
        ),
        'Juan 3:16,Juan 3:18-Juan 3:20,Juan 4:1',
      );
    });

    test('localizes every expression in a sequence', () {
      final passage = Passage.parse(
        'John; John 3-4; John 3:16,18-20; Acts 2:1-4',
      );

      expect(
        passage.format(language: BibleLanguageEnum.spanish),
        'Juan; Juan 3-4; Juan 3:16,18-20; Hechos 2:1-4',
      );
    });

    test('does not change existing Reference formatting', () {
      const reference = VerseRangeRef(
        start: VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
        ),
        end: VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 18,
        ),
      );

      expect(
        reference.format(language: BibleLanguageEnum.spanish),
        'Juan 3:16-18',
      );
    });
  });
}
