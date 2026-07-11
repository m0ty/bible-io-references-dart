import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceParser aliases', () {
    test('language-neutral custom aliases override bundled aliases', () {
      final parser = ReferenceParser(
        aliases: {'jn': BibleBookEnum.john},
      );
      final result = parser.parseResult('jn 3:16');

      expect(result.valueOrNull, VerseRef.parse('John 3:16'));
      expect(
          result.metadataOrNull?.bookMatches.single.selected.isCustom, isTrue);
      expect(
          result.metadataOrNull?.bookMatches.single.alternatives, isNotEmpty);
      expect(result.metadataOrNull?.detectedLanguage, isNull);
    });

    test('normalizes custom aliases and adjacent coordinates consistently', () {
      final parser = ReferenceParser(
        aliases: {'\uff26\uff41\uff56': BibleBookEnum.john},
      );

      expect(
        parser.parse('fav\u0663\uff1a\u0661\u0666'),
        VerseRef.parse('John 3:16'),
      );
    });

    test('language-specific aliases respect explicit language selection', () {
      final parser = ReferenceParser(
        aliasesByLanguage: {
          BibleLanguageEnum.greek: {'ιω': BibleBookEnum.john},
        },
      );

      expect(
        parser
            .parseVerse(
              'ιω 3:16',
              language: BibleLanguageEnum.greek,
            )
            .book,
        BibleBookEnum.john,
      );
      expect(
        parser
            .parseResult(
              'ιω 3:16',
              language: BibleLanguageEnum.greek,
            )
            .metadataOrNull
            ?.detectedLanguage,
        BibleLanguageEnum.greek,
      );
      expect(
        () => parser.parseVerse(
          'ιω 3:16',
          language: BibleLanguageEnum.spanish,
        ),
        throwsA(isA<ParseVerseRefError>()),
      );
    });

    test('configuration views are immutable defensive copies', () {
      final aliases = {'fav': BibleBookEnum.john};
      final spanishAliases = {'favorito': BibleBookEnum.john};
      final parser = ReferenceParser(
        aliases: aliases,
        aliasesByLanguage: {BibleLanguageEnum.spanish: spanishAliases},
      );
      aliases['fav'] = BibleBookEnum.jonah;
      spanishAliases['favorito'] = BibleBookEnum.jonah;

      expect(parser.parseVerse('fav 1:1').book, BibleBookEnum.john);
      expect(
        parser
            .parseVerse(
              'favorito 1:1',
              language: BibleLanguageEnum.spanish,
            )
            .book,
        BibleBookEnum.john,
      );
      expect(
        () => parser.aliases['other'] = BibleBookEnum.acts,
        throwsUnsupportedError,
      );
      expect(
        () => parser.aliasesByLanguage[BibleLanguageEnum.spanish]!['other'] =
            BibleBookEnum.acts,
        throwsUnsupportedError,
      );
    });
  });

  group('ReferenceParser ambiguity handling', () {
    test('preferred languages alter deterministic auto selection', () {
      final parser = ReferenceParser(
        aliasesByLanguage: {
          BibleLanguageEnum.spanish: {'shared': BibleBookEnum.john},
          BibleLanguageEnum.french: {'shared': BibleBookEnum.jonah},
        },
        preferredLanguages: [BibleLanguageEnum.french],
      );
      final result = parser.parseResult('shared 1:1');

      expect((result.valueOrNull as VerseRef).book, BibleBookEnum.jonah);
      expect(result.metadataOrNull?.detectedLanguage, BibleLanguageEnum.french);
      expect(result.metadataOrNull?.hasAmbiguity, isTrue);
      expect(result.metadataOrNull?.alternateMatches, isNotEmpty);
    });

    test('reject mode reports distinct matching books', () {
      final parser = ReferenceParser(
        aliasesByLanguage: {
          BibleLanguageEnum.spanish: {'shared': BibleBookEnum.john},
          BibleLanguageEnum.french: {'shared': BibleBookEnum.jonah},
        },
        ambiguityPolicy: ReferenceAmbiguityPolicy.reject,
      );
      final result = parser.parseResult('shared 1:1');

      expect(result, isA<ParseFailure<Reference>>());
      expect(
        result.errorOrNull?.errorCode,
        ReferenceParseErrorCode.ambiguousBook,
      );
    });

    test('reject mode exposes bundled cross-language collisions', () {
      final parser = ReferenceParser(
        ambiguityPolicy: ReferenceAmbiguityPolicy.reject,
      );
      final autoResult = parser.parseResult('jn 1:1');
      final englishResult = parser.parseResult(
        'jn 1:1',
        language: BibleLanguageEnum.english,
      );

      expect(
        autoResult.errorOrNull?.errorCode,
        ReferenceParseErrorCode.ambiguousBook,
      );
      expect((englishResult.valueOrNull as VerseRef).book, BibleBookEnum.jonah);
    });

    test('reject mode still permits an intentional custom override', () {
      final parser = ReferenceParser(
        aliases: {'jn': BibleBookEnum.john},
        ambiguityPolicy: ReferenceAmbiguityPolicy.reject,
      );

      expect(parser.parseVerse('jn 3:16').book, BibleBookEnum.john);
    });
  });

  group('ReferenceParser metadata', () {
    test('reports detected language and alternate matches', () {
      final result = Reference.parseResult('Juan 3:16');
      final metadata = result.metadataOrNull!;

      expect(metadata.normalizedInput, 'Juan 3:16');
      expect(metadata.detectedLanguage, BibleLanguageEnum.spanish);
      expect(metadata.bookMatches.single.selected.book, BibleBookEnum.john);
      expect(metadata.bookMatches.single.selected.isCustom, isFalse);
    });

    test('records both explicit book tokens in cross-book ranges', () {
      final parser = ReferenceParser();
      final result = parser.parseResult('Juan 3:16-Hechos 1:2');
      final metadata = result.metadataOrNull!;

      expect(result.valueOrNull, isA<VerseRangeRef>());
      expect(metadata.bookMatches, hasLength(2));
      expect(metadata.detectedLanguages, {BibleLanguageEnum.spanish});
      expect(
        metadata.bookMatches.map((match) => match.selected.book),
        [BibleBookEnum.john, BibleBookEnum.acts],
      );
      expect(
        () => metadata.bookMatches.add(metadata.bookMatches.first),
        throwsUnsupportedError,
      );
    });

    test('explicit language filters otherwise matching candidates', () {
      final parser = ReferenceParser(
        aliasesByLanguage: {
          BibleLanguageEnum.spanish: {'shared': BibleBookEnum.john},
          BibleLanguageEnum.french: {'shared': BibleBookEnum.jonah},
        },
        ambiguityPolicy: ReferenceAmbiguityPolicy.reject,
      );

      final result = parser.parseResult(
        'shared 1:1',
        language: BibleLanguageEnum.spanish,
      );
      expect((result.valueOrNull as VerseRef).book, BibleBookEnum.john);
      expect(
          result.metadataOrNull?.detectedLanguage, BibleLanguageEnum.spanish);
    });
  });
}
