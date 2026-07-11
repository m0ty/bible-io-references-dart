import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('passage value objects', () {
    test('book passages have value semantics and JSON round trips', () {
      const first = BookPassage(BibleBookEnum.john);
      const second = BookPassage(BibleBookEnum.john);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.displayString, 'John');
      expect(Passage.fromJson(first.toJson()), first);
      expect(BookPassage.fromJson(first.toJson()), first);
    });

    test('chapter passages validate bounds and ordering', () {
      final chapter = ChapterPassage(BibleBookEnum.john, 3);
      final range = ChapterPassage(BibleBookEnum.john, 3, 4);

      expect(chapter.displayString, 'John 3');
      expect(range.displayString, 'John 3-4');
      expect(ChapterPassage.fromJson(range.toJson()), range);
      expect(() => ChapterPassage(BibleBookEnum.john, 0), throwsRangeError);
      expect(
        () => ChapterPassage(BibleBookEnum.john, 4, 3),
        throwsArgumentError,
      );
      expect(
        () => ChapterPassage(BibleBookEnum.john, 3, 3),
        throwsArgumentError,
      );
    });

    test('verse passages are non-empty immutable values', () {
      final source = <Reference>[Reference.parse('John 3:16')];
      final passage = VersePassage(source);
      source.add(Reference.parse('John 3:17'));
      final same = VersePassage([Reference.parse('John 3:16')]);

      expect(passage, same);
      expect(passage.hashCode, same.hashCode);
      expect(passage.selections, hasLength(1));
      expect(() => passage.selections.add(source.last), throwsUnsupportedError);
      expect(VersePassage.fromJson(passage.toJson()), passage);
      expect(() => VersePassage(const []), throwsArgumentError);
    });

    test('passage sequences are non-empty immutable values', () {
      final source = <Passage>[
        const BookPassage(BibleBookEnum.john),
        ChapterPassage(BibleBookEnum.acts, 2),
      ];
      final sequence = PassageSequence(source);
      source.clear();
      final same = PassageSequence([
        const BookPassage(BibleBookEnum.john),
        ChapterPassage(BibleBookEnum.acts, 2),
      ]);

      expect(sequence, same);
      expect(sequence.hashCode, same.hashCode);
      expect(sequence.displayString, 'John; Acts 2');
      expect(() => sequence.passages.clear(), throwsUnsupportedError);
      expect(PassageSequence.fromJson(sequence.toJson()), sequence);
      expect(Passage.fromJson(sequence.toJson()), sequence);
      expect(() => PassageSequence(const []), throwsArgumentError);
    });

    test('malformed JSON is rejected', () {
      expect(
        () => Passage.fromJson({'type': 'other'}),
        throwsFormatException,
      );
      expect(
        () => VersePassage.fromJson({'type': 'verses', 'selections': 1}),
        throwsFormatException,
      );
      expect(
        () => ChapterPassage.fromJson({
          'type': 'chapter',
          'book': 'jo',
          'startChapter': 1,
          'endChapter': 'two',
        }),
        throwsFormatException,
      );
    });
  });

  group('passage grammar', () {
    test('parses whole books and chapters without changing Reference.parse',
        () {
      expect(
        Passage.parse('John'),
        const BookPassage(BibleBookEnum.john),
      );
      expect(
        Passage.parse('John 3'),
        ChapterPassage(BibleBookEnum.john, 3),
      );
      expect(
        Passage.parse('John 3-4'),
        ChapterPassage(BibleBookEnum.john, 3, 4),
      );
      expect(
          () => Reference.parse('John 3'), throwsA(isA<ParseVerseRefError>()));
    });

    test('wraps existing verses and ranges in a verse passage', () {
      expect(
        Passage.parse('John 3:16'),
        VersePassage([Reference.parse('John 3:16')]),
      );
      expect(
        Passage.parse('John 3:16-4:1'),
        VersePassage([Reference.parse('John 3:16-4:1')]),
      );
      expect(
        Passage.parse('John 3:16-Acts 1:2'),
        VersePassage([Reference.parse('John 3:16-Acts 1:2')]),
      );
    });

    test('parses compact verse lists into discrete references', () {
      final passage = Passage.parse('John 3:16,18-20') as VersePassage;

      expect(passage.selections, [
        Reference.parse('John 3:16'),
        Reference.parse('John 3:18-20'),
      ]);
      expect(passage.displayString, 'John 3:16,18-20');
      expect(Passage.fromJson(passage.toJson()), passage);
    });

    test('verse lists can select explicit later chapters', () {
      final passage = Passage.parse('John 3:16,4:1-5:2') as VersePassage;

      expect(passage.selections, [
        Reference.parse('John 3:16'),
        Reference.parse('John 4:1-5:2'),
      ]);
      expect(passage.displayString, 'John 3:16,4:1-5:2');
    });

    test('parses semicolon-separated passage sequences', () {
      final passage = Passage.parse(
        'John 3:16; Acts 2:1-4; Romans 8',
      ) as PassageSequence;

      expect(passage.passages, [
        VersePassage([Reference.parse('John 3:16')]),
        VersePassage([Reference.parse('Acts 2:1-4')]),
        ChapterPassage(BibleBookEnum.romans, 8),
      ]);
      expect(passage.displayString, 'John 3:16; Acts 2:1-4; Romans 8');
    });

    test('uses verse shorthand for standard single-chapter books', () {
      expect(
        Passage.parse('Jude 3'),
        VersePassage([Reference.parse('Jude 1:3')]),
      );
      expect(
        Passage.parse('Jude 3-5'),
        VersePassage([Reference.parse('Jude 1:3-5')]),
      );
    });

    test('supports configurable single-chapter book semantics', () {
      final parser = PassageParser(
        singleChapterBooks: {BibleBookEnum.john},
      );

      expect(
        parser.parse('John 3'),
        VersePassage([Reference.parse('John 1:3')]),
      );
      expect(
        parser.parse('Jude 3'),
        ChapterPassage(BibleBookEnum.jude, 3),
      );
      expect(
        () => parser.singleChapterBooks.add(BibleBookEnum.jude),
        throwsUnsupportedError,
      );
    });

    test('accepts book and chapter adjacency for CJK aliases', () {
      final passage = Passage.parse(
        '约翰福音3:16',
        language: BibleLanguageEnum.chinese,
      );

      expect(
        passage,
        VersePassage([Reference.parse('John 3:16')]),
      );
    });

    test('normalizes Arabic-Indic digits and RTL punctuation', () {
      final result = Passage.parseResult(
        '\u200fيوحنا\u200f ٣：١٦،١٨-٢٠؛ أعمال الرسل ٢',
        language: BibleLanguageEnum.arabic,
      );

      expect(result.errorOrNull, isNull, reason: '${result.errorOrNull}');
      expect(
        result.valueOrNull,
        PassageSequence([
          VersePassage([
            Reference.parse('John 3:16'),
            Reference.parse('John 3:18-20'),
          ]),
          ChapterPassage(BibleBookEnum.acts, 2),
        ]),
      );
      expect(
        result.metadataOrNull?.normalizedInput,
        'يوحنا 3:16,18-20; أعمال الرسل 2',
      );
    });

    test('normalizes fullwidth text, digits, and punctuation', () {
      final passage = Passage.parse(
        'Ｊｏｈｎ３：１６，１８－２０；Ａｃｔｓ２',
      );

      expect(
        passage,
        PassageSequence([
          VersePassage([
            Reference.parse('John 3:16'),
            Reference.parse('John 3:18-20'),
          ]),
          ChapterPassage(BibleBookEnum.acts, 2),
        ]),
      );
    });
  });

  group('PassageParser configuration and metadata', () {
    test('reuses custom aliases from a ReferenceParser', () {
      final parser = PassageParser(
        referenceParser: ReferenceParser(
          aliases: {'favorite': BibleBookEnum.john},
        ),
      );
      final result = parser.parseResult('favorite 3:16,18');

      expect(result.valueOrNull, isA<VersePassage>());
      expect(
        result.metadataOrNull?.bookMatches.single.selected.isCustom,
        isTrue,
      );
      expect(
        result.metadataOrNull?.bookMatches.single.selected.book,
        BibleBookEnum.john,
      );
    });

    test('respects localized aliases and explicit languages', () {
      final parser = PassageParser(
        referenceParser: ReferenceParser(
          aliasesByLanguage: {
            BibleLanguageEnum.greek: {'ιω': BibleBookEnum.john},
          },
        ),
      );

      expect(
        parser.parse('ιω3', language: BibleLanguageEnum.greek),
        ChapterPassage(BibleBookEnum.john, 3),
      );
      expect(
        () => parser.parse('ιω3', language: BibleLanguageEnum.spanish),
        throwsA(isA<ParseVerseRefError>()),
      );
    });

    test('aggregates detection metadata in sequence order', () {
      final result = Passage.parseResult('Juan 3:16; Hechos 2; Juan 4');
      final metadata = result.metadataOrNull!;

      expect(metadata.normalizedInput, 'Juan 3:16; Hechos 2; Juan 4');
      expect(metadata.detectedLanguage, BibleLanguageEnum.spanish);
      expect(
        metadata.bookMatches.map((match) => match.selected.book),
        [BibleBookEnum.john, BibleBookEnum.acts, BibleBookEnum.john],
      );
      expect(
        () => metadata.bookMatches.add(metadata.bookMatches.first),
        throwsUnsupportedError,
      );
    });

    test('preserves ambiguity policy and alternate matches', () {
      final parser = PassageParser(
        referenceParser: ReferenceParser(
          aliasesByLanguage: {
            BibleLanguageEnum.spanish: {'shared': BibleBookEnum.john},
            BibleLanguageEnum.french: {'shared': BibleBookEnum.jonah},
          },
          preferredLanguages: [BibleLanguageEnum.french],
        ),
      );
      final result = parser.parseResult('shared 2');

      expect(
        (result.valueOrNull as ChapterPassage).book,
        BibleBookEnum.jonah,
      );
      expect(result.metadataOrNull?.detectedLanguage, BibleLanguageEnum.french);
      expect(result.metadataOrNull?.hasAmbiguity, isTrue);
      expect(result.metadataOrNull?.alternateMatches, isNotEmpty);
    });
  });

  group('passage parse failures', () {
    test('tryParse and parseResult remain non-throwing', () {
      expect(Passage.tryParse(''), isNull);
      expect(Passage.tryParse('John 3:16,'), isNull);

      final result = Passage.parseResult('John 4-3');
      expect(result, isA<ParseFailure<Passage>>());
      expect(
        result.errorOrNull?.errorCode,
        ReferenceParseErrorCode.sameBookRangeNotAscending,
      );
    });

    test('rejects malformed sequence and list syntax', () {
      for (final input in [
        'John 3:16;',
        'John 3:16;;Acts 2',
        'John 3:16,,18',
        'John 3:18-16,20',
      ]) {
        expect(
          () => Passage.parse(input),
          throwsA(isA<ParseVerseRefError>()),
          reason: input,
        );
      }
    });

    test('rejects unknown books and pathological numbers', () {
      expect(
        () => Passage.parse('Unknown 3'),
        throwsA(isA<ParseVerseRefError>()),
      );
      expect(
        Passage.parseResult('John 1000').errorOrNull?.errorCode,
        ReferenceParseErrorCode.numericTokenOutOfRange,
      );
      expect(
        Passage.parseResult('John 0').errorOrNull?.errorCode,
        ReferenceParseErrorCode.nonPositiveNumericToken,
      );
    });
  });
}
