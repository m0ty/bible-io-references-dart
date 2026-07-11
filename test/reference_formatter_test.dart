import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('parsing language support', () {
    test('is derived from registered language data', () {
      expect(BibleLanguageEnum.auto.isParsingSupported, isTrue);
      expect(BibleLanguageEnum.english.isParsingSupported, isTrue);
      expect(BibleLanguageEnum.spanish.isParsingSupported, isTrue);
      expect(BibleLanguageEnum.greek.isParsingSupported, isFalse);

      for (final code in {
        ...bookNamesByLanguage.keys,
        ...bookAbbreviationsByLanguage.keys,
      }) {
        expect(
          supportedParsingLanguages.any((language) => language.code == code),
          isTrue,
          reason: '$code is registered but not reported as supported',
        );
      }
    });

    test('supported language view is immutable', () {
      expect(
        () => supportedParsingLanguages.add(BibleLanguageEnum.greek),
        throwsUnsupportedError,
      );
      expect(
        () => bookNamesByLanguage['xx'] = const {},
        throwsUnsupportedError,
      );
      expect(
        () => bookAbbreviationsByLanguage['xx'] = const {},
        throwsUnsupportedError,
      );
    });
  });

  group('ReferenceFormatter', () {
    const verse = VerseRef(
      book: BibleBookEnum.john,
      chapter: 3,
      verse: 16,
    );

    test('formats localized long and short book names', () {
      expect(
        verse.format(language: BibleLanguageEnum.spanish),
        'Juan 3:16',
      );

      const genesis = VerseRef(
        book: BibleBookEnum.genesis,
        chapter: 1,
        verse: 1,
      );
      expect(
        genesis.format(
          language: BibleLanguageEnum.arabic,
          bookNameStyle: ReferenceBookNameStyle.short,
        ),
        'تك 1:1',
      );
      expect(
        verse.format(
          language: BibleLanguageEnum.spanish,
          bookNameStyle: ReferenceBookNameStyle.short,
        ),
        'Jn 3:16',
      );
    });

    test('compacts same-chapter and cross-chapter ranges', () {
      const sameChapter = VerseRangeRef(
        start: verse,
        end: VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 18,
        ),
      );
      const crossChapter = VerseRangeRef(
        start: verse,
        end: VerseRef(
          book: BibleBookEnum.john,
          chapter: 4,
          verse: 1,
        ),
      );

      expect(
        sameChapter.format(language: BibleLanguageEnum.spanish),
        'Juan 3:16-18',
      );
      expect(
        crossChapter.format(language: BibleLanguageEnum.spanish),
        'Juan 3:16-4:1',
      );
      expect(
        sameChapter.format(
          language: BibleLanguageEnum.spanish,
          compactRanges: false,
        ),
        'Juan 3:16-Juan 3:18',
      );
    });

    test('localizes both endpoints of a cross-book range', () {
      const range = VerseRangeRef(
        start: verse,
        end: VerseRef(
          book: BibleBookEnum.acts,
          chapter: 1,
          verse: 2,
        ),
      );

      expect(
        range.format(language: BibleLanguageEnum.spanish),
        'Juan 3:16-Hechos 1:2',
      );
    });

    test('falls back deterministically to English', () {
      expect(
        verse.format(language: BibleLanguageEnum.greek),
        'John 3:16',
      );
      expect(
        verse.format(
          language: BibleLanguageEnum.auto,
          bookNameStyle: ReferenceBookNameStyle.short,
        ),
        'jo 3:16',
      );
    });
  });
}
