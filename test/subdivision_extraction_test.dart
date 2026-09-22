import 'package:bible_io_references/reference_extractor.dart';
import 'package:bible_io_references/references.dart';
import 'package:test/test.dart';

void main() {
  group('subdivision extraction', () {
    test('consumes a complete suffix and canonicalizes its case', () {
      const source = 'Read (John 1:5A), then John 1:5b!';

      final matches = ReferenceExtractor().extract(source);

      expect(matches.map((match) => match.sourceText), [
        'John 1:5A',
        'John 1:5b',
      ]);
      expect(matches.map((match) => match.passage.displayString), [
        'John 1:5a',
        'John 1:5b',
      ]);
      final verse =
          (matches.first.passage as VersePassage).selections.single as VerseRef;
      expect(verse.verse, 5);
      expect(verse.subdivision, 'a');
      expect(verse.verseLabel, '5a');
      for (final match in matches) {
        expect(source.substring(match.start, match.end), match.sourceText);
      }
    });

    test('prefers complete ranges, lists, and sequences', () {
      const reference = 'John 1:3-4,5a-5b,6b-2:1a; Jude 5a';

      final matches = ReferenceExtractor().extract('Study $reference today.');

      expect(matches, hasLength(1));
      expect(matches.single.sourceText, reference);
      expect(matches.single.passage.displayString,
          'John 1:3-4,5a-5b,6b-2:1a; Jude 1:5a');
    });

    test('consumes subdivisions at both ends of cross-book ranges', () {
      const reference = 'John 21:25b-Acts 1:1a';

      final match = ReferenceExtractor().extract('See $reference.').single;

      expect(match.sourceText, reference);
      expect(match.passage.displayString, reference);
    });

    test('maps Unicode digits, suffixes, and internal controls to source spans',
        () {
      const reference = 'Jo\u200fhn \u0661:\uff15\uff21';
      const source = '\u{1f4d6} Read \u200f$reference\u200f today.';

      final match = ReferenceExtractor().extract(source).single;

      expect(match.sourceText, reference);
      expect(match.start, source.indexOf(reference));
      expect(match.end, match.start + reference.length);
      expect(source.substring(match.start, match.end), reference);
      expect(match.passage.displayString, 'John 1:5a');
    });

    test('allows CJK prose immediately after a subdivision', () {
      const reference = '\u7ea6\u7ff0\u798f\u97f31:5a';
      const source = '\u8bf7\u8bfb$reference\u8c22\u8c22';

      final match = ReferenceExtractor().extract(source).single;

      expect(match.sourceText, reference);
      expect(match.start, source.indexOf(reference));
      expect(match.end, match.start + reference.length);
      expect(match.passage.displayString, 'John 1:5a');
    });

    for (final invalid in [
      'John 1:5abc',
      'John 1:5a2',
      'John 1:5_a',
      'John 1.5abc',
      'John 1 . 5abc',
      'John 1 : 5a2',
      'John 1:5a-6abc',
      'John 1:5a - 6a2',
      'John 1:5a-Acts 1:1abc',
      'John 1:5a - Acts 1 : 1a2',
      'John 1:999999999999999999999999a',
      'John 1:5a-Acts 1:999999999999999999999999a',
      'Jude 5abc',
      'Jude 5a2',
    ]) {
      test('does not truncate malformed label in $invalid', () {
        final matches = ReferenceExtractor().extract('Read $invalid today.');

        expect(matches, isEmpty);
      });
    }

    test('still finds valid references following malformed labels', () {
      const source = 'Ignore John 1:5abc; read Acts 2:1b.';

      final matches = ReferenceExtractor().extract(source);

      expect(matches.map((match) => match.sourceText), ['Acts 2:1b']);
    });

    test('allows a sentence-ending period before an unrelated number', () {
      const source = 'Read John 1:5a. 2 people cited Acts 2:1.';

      final matches = ReferenceExtractor().extract(source);

      expect(matches.map((match) => match.sourceText), [
        'John 1:5a',
        'Acts 2:1',
      ]);
    });

    test('supports spaced separators and leaves surrounding prose intact', () {
      const reference = 'John 1 . 5a - Acts 1 : 1b';
      final matches = ReferenceExtractor().extract('Read $reference now.');

      expect(matches, hasLength(1));
      expect(matches.single.sourceText, reference);
      expect(matches.single.passage.displayString, 'John 1:5a-Acts 1:1b');
    });

    test('a dash before ordinary prose does not hide a valid verse', () {
      const source = 'Read John 1:5a - compare Acts 2:1b next.';

      final matches = ReferenceExtractor().extract(source);

      expect(matches.map((match) => match.sourceText), [
        'John 1:5a',
        'Acts 2:1b',
      ]);
    });

    test('a separate article is not consumed as a subdivision', () {
      const source = 'Read John 1:5 a second time.';

      final match = ReferenceExtractor().extract(source).single;

      expect(match.sourceText, 'John 1:5');
      expect(match.passage.displayString, 'John 1:5');
    });

    test('replacement covers the full source label', () {
      const source = 'Read John 1:5a and Jude 5b.';

      final result = ReferenceExtractor().replaceMatches(
        source,
        (match) => '<${match.passage.displayString}>',
      );

      expect(result, 'Read <John 1:5a> and <Jude 1:5b>.');
    });

    test('Markdown links retain source labels and use parsed subdivisions', () {
      const source = 'Read John 1:5A-5b.';

      final result = ReferenceExtractor().linkifyMarkdown(
        source,
        uriBuilder: (match) => Uri.https('example.test', '/passage', {
          'q': match.passage.displayString,
        }),
      );

      expect(result,
          'Read [John 1:5A-5b](https://example.test/passage?q=John+1%3A5a-5b).');
    });
  });
}
