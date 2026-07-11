import 'package:bible_io_references/reference_extractor.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractor', () {
    test('finds punctuation-delimited repeated references with exact spans',
        () {
      const source = 'Read (John 3:16), then John 3:16!';
      final matches = ReferenceExtractor().extract(source);

      expect(matches, hasLength(2));
      expect(matches.map((match) => match.sourceText), [
        'John 3:16',
        'John 3:16',
      ]);
      expect(matches[0].start, source.indexOf('John 3:16'));
      expect(matches[0].end, matches[0].start + 'John 3:16'.length);
      expect(matches[1].start, source.lastIndexOf('John 3:16'));
      expect(
        source.substring(matches[1].start, matches[1].end),
        matches[1].sourceText,
      );
      expect(matches[0].metadata.bookMatches, isNotEmpty);
      expect(() => matches.add(matches.first), throwsUnsupportedError);
    });

    test('prefers a complete list and sequence over overlapping fragments', () {
      const source = 'Study John 3:16,18-20; Acts 2:1-4 today.';
      final matches = ReferenceExtractor().extract(source);

      expect(matches, hasLength(1));
      expect(matches.single.sourceText, 'John 3:16,18-20; Acts 2:1-4');
      expect(
        matches.single.passage.displayString,
        'John 3:16,18-20; Acts 2:1-4',
      );
    });

    test('extracts chapter and multilingual references', () {
      const source = 'Compare John 3 with Juan 3:16.';
      final matches = ReferenceExtractor().extract(source);

      expect(matches.map((match) => match.sourceText), [
        'John 3',
        'Juan 3:16',
      ]);
      expect(matches.last.metadata.detectedLanguages, isNotEmpty);
    });

    test('supports CJK references adjacent to prose', () {
      const reference = '\u7ea6\u7ff0\u798f\u97f33:16';
      const source = '\u8bf7\u8bfb$reference\u8c22\u8c22';

      final matches = ReferenceExtractor().extract(source);

      expect(matches, hasLength(1));
      expect(matches.single.sourceText, reference);
      expect(matches.single.start, source.indexOf(reference));
      expect(matches.single.end, matches.single.start + reference.length);
    });

    test('does not treat ordinary numbers or lowercase Mark and Job as refs',
        () {
      const source =
          'At 12:30, please mark 3:16 on the form; the job 2:4 is queued.';

      expect(
        ReferenceExtractor().extract(source).map((match) => match.sourceText),
        isEmpty,
      );
    });

    test('still recognizes capitalized Mark and Job references', () {
      const source = 'Read Mark 3:16 and Job 2:4.';

      expect(
        ReferenceExtractor().extract(source).map((match) => match.sourceText),
        ['Mark 3:16', 'Job 2:4'],
      );
    });

    test('bare books are opt-in', () {
      const source = 'Read Mark and Job.';

      expect(ReferenceExtractor().extract(source), isEmpty);
      expect(
        ReferenceExtractor(includeBareBooks: true)
            .extract(source)
            .map((match) => match.sourceText),
        ['Mark', 'Job'],
      );
    });

    test('keeps surrounding RTL controls outside the matched source span', () {
      const reference = 'John \u0663:\u0661\u0666';
      const source = 'Before \u200f$reference\u200f after';

      final matches = ReferenceExtractor().extract(source);

      expect(matches, hasLength(1));
      expect(matches.single.sourceText, reference);
      expect(
        source.substring(matches.single.start, matches.single.end),
        reference,
      );
    });

    test('retains directional controls that occur inside a match', () {
      const reference = 'Jo\u200fhn \u0663:\u0661\u0666';
      const source = 'Read $reference today.';

      final match = ReferenceExtractor().extract(source).single;

      expect(match.sourceText, reference);
      expect(match.start, source.indexOf(reference));
      expect(match.end, match.start + reference.length);
    });
  });

  group('linkification', () {
    test('replacement text is never reinterpreted', () {
      const source = 'Read John 3:16 once.';
      var calls = 0;

      final result = ReferenceExtractor().replaceMatches(source, (match) {
        calls++;
        return 'Acts 1:1 and Mark 2:2';
      });

      expect(calls, 1);
      expect(result, 'Read Acts 1:1 and Mark 2:2 once.');
    });

    test('leaves surrounding directional controls outside replacements', () {
      const source = 'Read \u200fJohn 3:16\u200f once.';

      final result = ReferenceExtractor().replaceMatches(
        source,
        (_) => '<reference>',
      );

      expect(result, 'Read \u200f<reference>\u200f once.');
    });

    test('Markdown helper escapes labels and builds a URI once per match', () {
      const source = 'Read John 3:16.';

      final result = ReferenceExtractor().linkifyMarkdown(
        source,
        labelBuilder: (_) => '[John]',
        uriBuilder: (_) =>
            Uri.https('example.test', '/passage', {'q': 'John 3'}),
      );

      expect(
        result,
        r'Read [\[John\]](https://example.test/passage?q=John+3).',
      );
    });
  });
}
