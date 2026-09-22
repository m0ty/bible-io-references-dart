import 'package:bible_io_references/bible_io_references.dart' as api;
import 'package:bible_io_references/package.dart' as legacy;
import 'package:bible_io_references/references.dart' as references;
import 'package:test/test.dart';

void main() {
  test('public entrypoints expose the same reference and passage types', () {
    final types = <(Type, Type, Type)>[
      (api.Reference, references.Reference, legacy.Reference),
      (api.VerseRef, references.VerseRef, legacy.VerseRef),
      (api.VerseLabel, references.VerseLabel, legacy.VerseLabel),
      (api.VerseRangeRef, references.VerseRangeRef, legacy.VerseRangeRef),
      (api.Passage, references.Passage, legacy.Passage),
      (api.BookPassage, references.BookPassage, legacy.BookPassage),
      (api.ChapterPassage, references.ChapterPassage, legacy.ChapterPassage),
      (api.VersePassage, references.VersePassage, legacy.VersePassage),
      (api.PassageSequence, references.PassageSequence, legacy.PassageSequence),
      (
        api.ReferenceParseErrorCode,
        references.ReferenceParseErrorCode,
        legacy.ReferenceParseErrorCode,
      ),
      (
        api.ParseVerseRefError,
        references.ParseVerseRefError,
        legacy.ParseVerseRefError,
      ),
      (api.ParseResult, references.ParseResult, legacy.ParseResult),
      (api.ParseSuccess, references.ParseSuccess, legacy.ParseSuccess),
      (api.ParseFailure, references.ParseFailure, legacy.ParseFailure),
      (
        api.ReferenceParseMetadata,
        references.ReferenceParseMetadata,
        legacy.ReferenceParseMetadata,
      ),
      (
        api.ReferenceBookCandidate,
        references.ReferenceBookCandidate,
        legacy.ReferenceBookCandidate,
      ),
      (
        api.ReferenceBookTokenMatch,
        references.ReferenceBookTokenMatch,
        legacy.ReferenceBookTokenMatch,
      ),
      (
        api.ReferenceAmbiguityPolicy,
        references.ReferenceAmbiguityPolicy,
        legacy.ReferenceAmbiguityPolicy,
      ),
      (api.ReferenceParser, references.ReferenceParser, legacy.ReferenceParser),
      (api.PassageParser, references.PassageParser, legacy.PassageParser),
    ];

    for (final (canonical, direct, compatibility) in types) {
      expect(direct, same(canonical));
      expect(compatibility, same(canonical));
    }
  });

  test('values and JSON can cross public entrypoints', () {
    final references.VerseRef verse = api.VerseRef.parse('John 3:16');
    final legacy.VerseRangeRef range = references.VerseRangeRef.checked(
      start: verse,
      end: legacy.VerseRef.parse('John 3:18'),
    );
    final api.Passage sequence = legacy.PassageSequence([
      references.VersePassage([range]),
      const api.BookPassage(legacy.BibleBookEnum.acts),
      references.ChapterPassage(api.BibleBookEnum.romans, 8),
    ]);

    expect(legacy.Reference.fromJson(range.toJson()), range);
    expect(references.Passage.fromJson(sequence.toJson()), sequence);
    expect(sequence.displayString, 'John 3:16-18; Acts; Romans 8');
  });

  test('configured parsers and successful metadata cross public entrypoints',
      () {
    final legacy.ReferenceParser referenceParser = references.ReferenceParser(
      aliases: {'favorite': api.BibleBookEnum.john},
      ambiguityPolicy: api.ReferenceAmbiguityPolicy.preferLanguagePriority,
    );
    final api.PassageParser passageParser = legacy.PassageParser(
      referenceParser: referenceParser,
    );
    final references.ParseResult<legacy.Passage> result =
        passageParser.parseResult('favorite 3:16,18');
    final api.ReferenceParseMetadata metadata = result.metadataOrNull!;
    final legacy.ReferenceBookTokenMatch match = metadata.bookMatches.single;
    final references.ReferenceBookCandidate candidate = match.selected;

    expect(result, isA<api.ParseSuccess<references.Passage>>());
    expect(result.valueOrNull, api.Passage.parse('John 3:16,18'));
    expect(candidate.book, api.BibleBookEnum.john);
    expect(candidate.isCustom, isTrue);
    expect(
      references.ReferenceParser.standard,
      same(legacy.ReferenceParser.standard),
    );
    expect(
      api.ReferenceParseMetadata.empty,
      same(references.ReferenceParseMetadata.empty),
    );
  });

  test('typed failures and thrown errors cross public entrypoints', () {
    final legacy.ParseResult<api.Reference> result =
        references.Reference.parseResult('');
    final api.ParseVerseRefError error = result.errorOrNull!;

    expect(result, isA<references.ParseFailure<legacy.Reference>>());
    expect(error.errorCode, legacy.ReferenceParseErrorCode.emptyReference);
    expect(
      () => legacy.Reference.parse(''),
      throwsA(isA<references.ParseVerseRefError>()),
    );
    expect(
      api.ParseFailure<references.Reference>(error).errorOrNull,
      same(error),
    );
  });

  test('legacy parsing functions and lookup metadata remain available', () {
    final verse = api.Reference.parse('John 3:16');
    final range = api.Reference.parse('John 3:16-18');

    expect(references.verseRefFromStr('John 3:16'), verse);
    expect(legacy.verseRefFromStr('John 3:16'), verse);
    expect(references.verseRangeRefFromStr('John 3:16-18'), range);
    expect(legacy.verseRangeRefFromStr('John 3:16-18'), range);
    expect(references.parseReference('John 3:16-18'), range);
    expect(legacy.parseReference('John 3:16'), verse);
    expect(
      references.autoLanguagePrecedence,
      same(legacy.autoLanguagePrecedence),
    );
    expect(references.autoLanguageCollisions, same(api.autoLanguageCollisions));
    expect(references.maxReferenceChapterNumber, api.maxReferenceChapterNumber);
    expect(references.maxReferenceVerseNumber, legacy.maxReferenceVerseNumber);
  });
}
