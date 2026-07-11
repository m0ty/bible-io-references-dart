import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('non-throwing parsing', () {
    test('tryParse returns a value or null', () {
      expect(
        Reference.tryParse('John 3:16'),
        const VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
        ),
      );
      expect(Reference.tryParse('not a reference'), isNull);
    });

    test('parseResult preserves typed diagnostics', () {
      final result = Reference.parseResult('');

      expect(result, isA<ParseFailure<Reference>>());
      expect(result.isSuccess, isFalse);
      expect(
        result.errorOrNull?.errorCode,
        ReferenceParseErrorCode.emptyReference,
      );
    });
  });

  group('reference value objects', () {
    test('have value equality and stable hash codes', () {
      final first = VerseRef.parse('John 3:16');
      final second = VerseRef.parse('John 3:16');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect({first, second}, hasLength(1));
    });

    test('support checked copies', () {
      final verse = VerseRef.parse('John 3:16');

      expect(verse.copyWith(verse: 17), VerseRef.parse('John 3:17'));
      expect(() => verse.copyWith(chapter: 0), throwsRangeError);
    });

    test('round-trip through JSON', () {
      final references = <Reference>[
        Reference.parse('John 3:16'),
        Reference.parse('John 3:16-Acts 1:2'),
      ];

      for (final reference in references) {
        expect(Reference.fromJson(reference.toJson()), reference);
      }
    });
  });

  group('range parsing', () {
    test('Reference.parse recognizes cross-book ranges', () {
      expect(
        Reference.parse('John 3:16-Acts 1:2'),
        VerseRangeRef.parse('John 3:16-Acts 1:2'),
      );
    });

    test('rejects reverse cross-book ranges', () {
      final result = Reference.parseResult('Acts 1:2-John 3:16');

      expect(result, isA<ParseFailure<Reference>>());
      expect(
        result.errorOrNull?.errorCode,
        ReferenceParseErrorCode.crossBookRangeNotAscending,
      );
    });
  });
}
