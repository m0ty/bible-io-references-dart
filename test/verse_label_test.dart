import 'dart:convert';

import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('VerseLabel', () {
    test('preserves a combined source entry and exposes its endpoints', () {
      final label = VerseLabel.parse('3-4');

      expect(label.source, '3-4');
      expect(label.startVerse, 3);
      expect(label.startSubdivision, isNull);
      expect(label.endVerse, 4);
      expect(label.endSubdivision, isNull);
      expect(label.isCombined, isTrue);
      expect(label.displayString, '3-4');
    });

    test('represents whole verses and single subdivisions', () {
      final whole = VerseLabel.parse('5');
      final part = VerseLabel.parse('5B');

      expect(whole.startVerse, 5);
      expect(whole.startSubdivision, isNull);
      expect(whole.endVerse, isNull);
      expect(whole.isCombined, isFalse);
      expect(part.startVerse, 5);
      expect(part.startSubdivision, 'b');
      expect(part.endVerse, isNull);
      expect(part.endSubdivision, isNull);
      expect(part.isCombined, isFalse);
      expect(part.source, '5B');
      expect(part.displayString, '5b');
    });

    test('preserves Unicode spelling, case, and whitespace through JSON', () {
      const source = ' \u200f۰۰۵A\u00a0–\t５b ';
      final label = VerseLabel.parse(source);

      expect(label.source, source);
      expect(label.startVerse, 5);
      expect(label.startSubdivision, 'a');
      expect(label.endVerse, 5);
      expect(label.endSubdivision, 'b');
      expect(label.displayString, '5a-5b');
      expect(label.toString(), '5a-5b');
      expect(label.toJson(), {'label': source});
      final decoded = jsonDecode(jsonEncode(label.toJson()));
      final restored = VerseLabel.fromJson(decoded as Map<String, dynamic>);
      expect(restored, label);
      expect(restored.source, source);
    });

    test('converts a single subdivision to its reference location', () {
      final reference = VerseLabel.parse('5A').toReference(
        book: BibleBookEnum.john,
        chapter: 1,
      );

      expect(reference, Reference.parse('John 1:5a'));
      expect(reference, isA<VerseRef>());
    });

    test('converts combined labels to one range reference', () {
      for (final source in ['3-4', '5a-5b', '5b-6a']) {
        final reference = VerseLabel.parse(source).toReference(
          book: BibleBookEnum.john,
          chapter: 1,
        );

        expect(reference, Reference.parse('John 1:$source'));
        expect(reference, isA<VerseRangeRef>());
      }
    });

    test('validates chapter context when converting to a reference', () {
      for (final chapter in [0, -1, 1000]) {
        expect(
          () => VerseLabel.parse('3-4').toReference(
            book: BibleBookEnum.john,
            chapter: chapter,
          ),
          throwsArgumentError,
        );
      }
    });

    test('source spelling participates in equality and hashing', () {
      final first = VerseLabel.parse('3-4');
      final same = VerseLabel.parse('3-4');
      final alternate = VerseLabel.parse('3–4');

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(alternate));
      expect(alternate.displayString, first.displayString);
      expect({first, same, alternate}, hasLength(2));
      expect(VerseLabel.parse('5A'), isNot(VerseLabel.parse('5a')));
      expect(VerseLabel.parse('005'), isNot(VerseLabel.parse('5')));
    });

    test('orders verse numbers before subdivision letters', () {
      for (final source in ['5-5a', '5a-5z', '5z-6', '99z-100a', '998-999z']) {
        expect(VerseLabel.tryParse(source)?.displayString, source);
      }
    });

    test('returns successful parse results with normalized metadata', () {
      final result = VerseLabel.parseResult(' ٣ – ٤ ');

      expect(result, isA<ParseSuccess<VerseLabel>>());
      expect(result.valueOrNull?.source, ' ٣ – ٤ ');
      expect(result.metadataOrNull?.normalizedInput, '3 - 4');
      expect(result.metadataOrNull?.bookMatches, isEmpty);
      expect(result.errorOrNull, isNull);
    });

    test('rejects malformed labels without accepting a valid prefix', () {
      for (final source in [
        'John 1:5a',
        '1:5a',
        '5a-1:6b',
        '5ab',
        '5 a',
        '5α',
        '5a text',
        '5a\n6b',
        '5a-5b-5c',
        '5a,5b',
        '5a-',
        '-5a',
        '5a--6b',
        '1.5',
      ]) {
        final result = VerseLabel.parseResult(source);
        expect(result, isA<ParseFailure<VerseLabel>>(), reason: source);
        expect(
          result.errorOrNull?.errorCode,
          ReferenceParseErrorCode.patternMismatch,
          reason: source,
        );
        expect(VerseLabel.tryParse(source), isNull, reason: source);
        expect(
          () => VerseLabel.parse(source),
          throwsA(isA<ParseVerseRefError>()),
          reason: source,
        );
      }
    });

    test('rejects empty and nonascending labels with typed errors', () {
      for (final source in ['', ' \t ', '\u200f']) {
        expect(
          VerseLabel.parseResult(source).errorOrNull?.errorCode,
          ReferenceParseErrorCode.emptyReference,
        );
      }
      for (final source in ['4-3', '3-3', '5a-5a', '5b-5a', '5a-5', '6-5z']) {
        expect(
          VerseLabel.parseResult(source).errorOrNull?.errorCode,
          ReferenceParseErrorCode.sameBookRangeNotAscending,
          reason: source,
        );
      }
    });

    test('enforces verse numeric limits at both endpoints', () {
      for (final source in ['0', '0a', '0-1', '1-0b']) {
        expect(
          VerseLabel.parseResult(source).errorOrNull?.errorCode,
          ReferenceParseErrorCode.nonPositiveNumericToken,
          reason: source,
        );
      }
      for (final source in ['1000', '1000a', '1-1000b']) {
        expect(
          VerseLabel.parseResult(source).errorOrNull?.errorCode,
          ReferenceParseErrorCode.numericTokenOutOfRange,
          reason: source,
        );
      }
      expect(VerseLabel.tryParse('9' * 100), isNull);
    });

    test('rejects missing or nonstring JSON labels', () {
      for (final json in <Map<String, Object?>>[
        {},
        {'label': null},
        {'label': 5},
        {
          'label': ['3', '4']
        },
      ]) {
        expect(() => VerseLabel.fromJson(json), throwsFormatException);
      }
      expect(
        () => VerseLabel.fromJson({'label': '5ab'}),
        throwsA(isA<ParseVerseRefError>()),
      );
    });
  });
}
