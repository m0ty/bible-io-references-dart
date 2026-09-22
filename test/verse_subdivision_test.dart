import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('verse subdivision values', () {
    test('preserves integer verse and optional subdivision in JSON', () {
      final plain = VerseRef.parse('John 1:5');
      final divided = VerseRef.parse('John 1:5a');
      expect(plain.toJson(), {
        'type': 'verse',
        'book': 'jo',
        'chapter': 1,
        'verse': 5,
      });
      expect(divided.toJson(), {
        'type': 'verse',
        'book': 'jo',
        'chapter': 1,
        'verse': 5,
        'subdivision': 'a',
      });
      expect(divided.verse, 5);
      expect(divided.subdivision, 'a');
      expect(divided.verseLabel, '5a');
      expect(Reference.fromJson(divided.toJson()), divided);
      expect(
          VerseRef.fromJson({...plain.toJson(), 'subdivision': null}), plain);
    });

    test('copies preserve, replace, or explicitly clear a subdivision', () {
      final verse = VerseRef.parse('John 1:5a');
      expect(verse.copyWith(chapter: 2), VerseRef.parse('John 2:5a'));
      expect(verse.copyWith(subdivision: 'b'), VerseRef.parse('John 1:5b'));
      expect(
          verse.copyWith(clearSubdivision: true), VerseRef.parse('John 1:5'));
      expect(verse.copyWith(), verse);
      expect(verse.copyWith().hashCode, verse.hashCode);
      expect({verse, verse.copyWith(), verse.copyWith(subdivision: 'b')},
          hasLength(2));
    });

    test('checked construction and JSON reject invalid subdivisions', () {
      final json = VerseRef.parse('John 1:5').toJson();
      for (final suffix in ['', 'A', 'ab', '1', ' a', 'a\n', '\u03b1']) {
        expect(
            () => VerseRef.checked(
                  book: BibleBookEnum.john,
                  chapter: 1,
                  verse: 5,
                  subdivision: suffix,
                ),
            throwsArgumentError,
            reason: suffix);
        expect(() => VerseRef.fromJson({...json, 'subdivision': suffix}),
            throwsArgumentError,
            reason: suffix);
      }
      expect(() => VerseRef.fromJson({...json, 'subdivision': 1}),
          throwsFormatException);
      expect(
          () => VerseRef.checked(
                book: BibleBookEnum.john,
                chapter: 1,
                verse: 0,
                subdivision: 'a',
              ),
          throwsRangeError);
    });

    test('ordering distinguishes whole verses and subdivisions', () {
      final ordered = [
        'John 1:5',
        'John 1:5a',
        'John 1:5b',
        'John 1:5z',
        'John 1:6',
        'John 2:1a',
        'Acts 1:1a'
      ].map(VerseRef.parse).toList();
      for (var index = 1; index < ordered.length; index++) {
        final start = ordered[index - 1];
        final end = ordered[index];
        expect(start.compareTo(end), lessThan(0));
        expect(end.compareTo(start), greaterThan(0));
        expect(VerseRangeRef.checked(start: start, end: end).start, start);
        expect(() => VerseRangeRef.checked(start: end, end: start),
            throwsArgumentError);
      }
    });
  });

  group('subdivision parsing', () {
    test('accepts normalized Unicode syntax, languages, and custom aliases',
        () {
      final expected = VerseRef.parse('John 1:5a');
      expect(VerseRef.parse('John 1:5A'), expected);
      expect(VerseRef.parse('\u200fJohn\uff11\uff1a\u0665\uff21'), expected);
      expect(VerseRef.parse('Juan 1:5a', language: BibleLanguageEnum.spanish),
          expected);
      final parser = ReferenceParser(aliases: {'favorite': BibleBookEnum.john});
      final result = parser.parseVerseResult('favorite 1:5A');
      expect(result.valueOrNull, expected);
      expect(
          result.metadataOrNull!.bookMatches.single.selected.isCustom, isTrue);
      expect(result.metadataOrNull!.normalizedInput, 'favorite 1:5A');
      expect(VerseRef.tryParse('John 1:5a'), expected);
      expect(Reference.parseResult('John 1:5a').valueOrNull, expected);
    });

    test('ranges round-trip subdivided endpoints without losing suffixes', () {
      for (final source in [
        'John 1:5a-5b',
        'John 1:5b-6',
        'John 1:4-5a',
        'John 1:5a-2:1b',
        'John 1:5a-Acts 1:2b',
      ]) {
        final range = VerseRangeRef.parse(source);
        expect(range.displayString, source);
        expect(Reference.parse(source), range);
        expect(VerseRangeRef.tryParse(source), range);
        expect(Reference.fromJson(range.toJson()), range);
      }
      expect(
          Reference.parse('John1:5A\u20135B'), Reference.parse('John 1:5a-5b'));
    });

    test('legacy functions accept subdivisions with their original grammar',
        () {
      expect(verseRefFromStr('John 1:5A'), VerseRef.parse('John 1:5a'));
      for (final source in [
        'John 1:5a-5b',
        'John 1:5a-2:1b',
        'John 1:5a-Acts 1:2b'
      ]) {
        expect(verseRangeRefFromStr(source), Reference.parse(source));
      }
      expect(() => verseRangeRefFromStr('John1:5a-5b'),
          throwsA(isA<ParseVerseRefError>()));
      expect(
          () => verseRangeRefFromStr('John 1:5b-5a'),
          throwsA(
            isA<ParseVerseRefError>().having((e) => e.errorCode, 'code',
                ReferenceParseErrorCode.sameBookRangeNotAscending),
          ));
    });

    test('rejects malformed labels and invalid ascending ranges', () {
      for (final input in [
        'John 1:5ab',
        'John 1:5a2',
        'John 1:5 a',
        'John 1:5a-b',
        'John 1a:5',
        'John 1:5a-',
        'John 1:5a-5ab',
        'John 1:5b-5a',
        'John 1:5a-5a',
        'John 1:5a-5',
        'Acts 1:5a-John 1:5b',
      ]) {
        expect(Reference.parseResult(input), isA<ParseFailure<Reference>>(),
            reason: input);
        expect(Passage.tryParse(input), isNull, reason: input);
      }
    });

    test('numeric sanity errors apply to the number before the subdivision',
        () {
      for (final (token, code) in [
        ('0a', ReferenceParseErrorCode.nonPositiveNumericToken),
        ('1000a', ReferenceParseErrorCode.numericTokenOutOfRange),
        (
          '9999999999999999999999999a',
          ReferenceParseErrorCode.invalidNumericToken
        ),
      ]) {
        expect(Reference.parseResult('John 1:$token').errorOrNull?.errorCode,
            code);
        expect(
            Reference.parseResult('John 1:5a-2:$token').errorOrNull?.errorCode,
            code);
      }
    });

    test('all suffixes round-trip at numeric boundaries', () {
      for (var letter = 97; letter <= 122; letter++) {
        for (final number in [1, 9, 10, 99, 999]) {
          final value = VerseRef.checked(
            book: BibleBookEnum.john,
            chapter: 1,
            verse: number,
            subdivision: String.fromCharCode(letter),
          );
          expect(VerseRef.parse(value.displayString), value);
          expect(VerseRef.fromJson(value.toJson()), value);
          expect(value.compareTo(VerseRef.parse(value.displayString)), 0);
        }
      }
    });
  });

  group('subdivisions in passages', () {
    test('lists and sequences preserve display, value, and JSON', () {
      const input = 'John 1:5a,5b-6a,2:1b; Jude 5a-5b';
      final passage = Passage.parse(input);
      expect(passage.displayString, 'John 1:5a,5b-6a,2:1b; Jude 1:5a-5b');
      expect(Passage.parse(passage.displayString), passage);
      expect(Passage.fromJson(passage.toJson()), passage);
      expect(Passage.parse('Jude 5a'),
          VersePassage([VerseRef.parse('Jude 1:5a')]));
      expect(PassageParser(singleChapterBooks: {}).tryParse('Jude 5a'), isNull);
      expect(Passage.tryParse('John 5a'), isNull);
    });
  });
}
