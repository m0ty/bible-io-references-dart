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

    test('successful parse metadata has value semantics', () {
      final first = Reference.parseResult('Juan 3:16').metadataOrNull;
      final second = Reference.parseResult('Juan 3:16').metadataOrNull;

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect({first, second}, hasLength(1));
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

  group('Unicode and adjacent syntax', () {
    test('normalizes digits and punctuation in Reference.parse', () {
      final result = Reference.parseResult(
        '\u200fJohn\u0663\uff1a\u0661\u0666\u2013Acts\u0661\uff1a\u0662',
      );

      expect(
        result.valueOrNull,
        Reference.parse('John 3:16-Acts 1:2'),
      );
      expect(
        result.metadataOrNull?.normalizedInput,
        'John3:16-Acts1:2',
      );
    });

    test('accepts CJK book and chapter adjacency', () {
      expect(
        Reference.parse(
          '\u7ea6\u7ff0\u798f\u97f33:16',
          language: BibleLanguageEnum.chinese,
        ),
        const VerseRef(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
        ),
      );

      expect(
        Reference.parse(
          '\u7ea6\u7ff0\u798f\u97f33:16-\u4f7f\u5f92\u884c\u4f201:2',
          language: BibleLanguageEnum.chinese,
        ),
        Reference.parse('John 3:16-Acts 1:2'),
      );
    });

    test('keeps numbered books distinct from adjacent coordinates', () {
      expect(
        Reference.parse('1John1:1-2John1:2'),
        Reference.parse('1 John 1:1-2 John 1:2'),
      );
    });
  });
}
