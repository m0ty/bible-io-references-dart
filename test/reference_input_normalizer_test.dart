import 'package:bible_io_references/reference_input_normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceInputNormalizer.normalize', () {
    test('keeps ASCII text, case, and whitespace runs unchanged', () {
      const input = 'JoHn  3:16-18, 20; Acts 2:1';

      expect(ReferenceInputNormalizer.normalize(input), input);
    });

    test('normalizes fullwidth ASCII and ideographic space', () {
      expect(
        ReferenceInputNormalizer.normalize(
          'Ｊｏｈｎ　３：１６－１８；Ａｃｔｓ　２：１',
        ),
        'John 3:16-18;Acts 2:1',
      );
    });

    test('normalizes Arabic-Indic and Eastern Arabic/Persian digits', () {
      expect(
        ReferenceInputNormalizer.normalize(
          '٠١٢٣٤٥٦٧٨٩ ۰۱۲۳۴۵۶۷۸۹',
        ),
        '0123456789 0123456789',
      );
    });

    test('normalizes comma variants', () {
      const variants = <String>[
        ',',
        '，',
        '،',
        '、',
        '︐',
        '︑',
        '﹐',
        '﹑',
        '､',
      ];

      for (final variant in variants) {
        expect(
          ReferenceInputNormalizer.normalize('16${variant}18'),
          '16,18',
          reason: 'U+${variant.runes.single.toRadixString(16)}',
        );
      }
    });

    test('normalizes semicolon variants', () {
      const variants = <String>[';', '；', '؛', '︔', '﹔'];

      for (final variant in variants) {
        expect(
          ReferenceInputNormalizer.normalize('16${variant}Acts'),
          '16;Acts',
          reason: 'U+${variant.runes.single.toRadixString(16)}',
        );
      }
    });

    test('normalizes colon variants', () {
      const variants = <String>[':', '：', '︓', '﹕'];

      for (final variant in variants) {
        expect(
          ReferenceInputNormalizer.normalize('3${variant}16'),
          '3:16',
          reason: 'U+${variant.runes.single.toRadixString(16)}',
        );
      }
    });

    test('normalizes common dash and minus variants', () {
      const variants = <String>[
        '-',
        '－',
        '‐',
        '‑',
        '‒',
        '–',
        '—',
        '―',
        '−',
        '⸺',
        '⸻',
        '﹘',
        '﹣',
      ];

      for (final variant in variants) {
        expect(
          ReferenceInputNormalizer.normalize('16${variant}18'),
          '16-18',
          reason: 'U+${variant.runes.single.toRadixString(16)}',
        );
      }
    });

    test('normalizes Unicode spacing characters without collapsing them', () {
      const variants = <String>[
        '\u00a0',
        '\u2000',
        '\u2001',
        '\u2002',
        '\u2003',
        '\u2004',
        '\u2005',
        '\u2006',
        '\u2007',
        '\u2008',
        '\u2009',
        '\u200a',
        '\u202f',
        '\u205f',
        '\u3000',
      ];

      for (final variant in variants) {
        expect(
          ReferenceInputNormalizer.normalize('John${variant}3'),
          'John 3',
          reason: 'U+${variant.runes.single.toRadixString(16)}',
        );
      }
      expect(
        ReferenceInputNormalizer.normalize('John\u00a0\u30003'),
        'John  3',
      );
    });

    test('strips directional formatting and isolation controls', () {
      const controls = <String>[
        '\u061c',
        '\u200e',
        '\u200f',
        '\u202a',
        '\u202b',
        '\u202c',
        '\u202d',
        '\u202e',
        '\u2066',
        '\u2067',
        '\u2068',
        '\u2069',
        '\u206a',
        '\u206b',
        '\u206c',
        '\u206d',
        '\u206e',
        '\u206f',
      ];

      for (final control in controls) {
        expect(
          ReferenceInputNormalizer.normalize('${control}John$control'),
          'John',
          reason: 'U+${control.runes.single.toRadixString(16)}',
        );
      }
    });

    test('strips invisible format controls and variation selectors', () {
      expect(
        ReferenceInputNormalizer.normalize(
          '\ufeffJo\u00ad\u200bhn\u2060 3\u223616\u05be18\ufe0f',
        ),
        'John 3:16-18',
      );
    });

    test('strips decomposed Latin diacritics but not letter case', () {
      expect(
        ReferenceInputNormalizer.normalize('Génêsis JOHN'),
        'Genesis JOHN',
      );
    });

    test('strips Hebrew points and cantillation marks', () {
      expect(
        ReferenceInputNormalizer.normalize('בְּרֵאשִׁית'),
        'בראשית',
      );
      expect(
        ReferenceInputNormalizer.normalize('ב֖ראשית'),
        'בראשית',
      );
    });

    test('strips Arabic vocalization marks', () {
      expect(
        ReferenceInputNormalizer.normalize('يُوحَنَّا'),
        'يوحنا',
      );
    });
  });

  group('ReferenceInputNormalization mapping', () {
    test('maps transformed and removed characters to exact UTF-16 offsets', () {
      const input = '\u200fJóhn\u200e ٣：١٦';
      final result = ReferenceInputNormalizer.normalizeDetailed(input);

      expect(result.normalizedText, 'John 3:16');
      expect(result.originalText, input);
      expect(result.changed, isTrue);
      expect(result.normalizedLength, 9);
      expect(result.sourceSpans, hasLength(9));

      expect(
        result.mapNormalizedSpan(0, 4),
        const ReferenceInputSpan(0, 7),
      );
      expect(result.originalTextFor(0, 4), '\u200fJóhn\u200e');
      expect(
        result.mapNormalizedSpan(1, 2),
        const ReferenceInputSpan(2, 4),
      );
      expect(result.originalTextFor(1, 2), 'ó');
      expect(
        result.mapNormalizedSpan(5, 9),
        const ReferenceInputSpan(8, 12),
      );
      expect(result.originalTextFor(5, 9), '٣：١٦');
      expect(
        result.mapNormalizedSpan(0, result.normalizedLength),
        const ReferenceInputSpan(0, 12),
      );
    });

    test('maps emoji surrogate pairs as complete source scalars', () {
      const input = 'A😀B';
      final result = ReferenceInputNormalizer.normalizeDetailed(input);

      expect(result.normalizedText, input);
      expect(result.normalizedLength, 4);
      expect(result.sourceSpans, hasLength(4));
      expect(
        result.mapNormalizedSpan(1, 3),
        const ReferenceInputSpan(1, 3),
      );
      expect(
        result.mapNormalizedSpan(1, 2),
        const ReferenceInputSpan(1, 3),
      );
      expect(
        result.mapNormalizedSpan(2, 3),
        const ReferenceInputSpan(1, 3),
      );
      expect(result.originalTextFor(1, 2), '😀');
      expect(
        result.mapNormalizedSpan(0, 4),
        const ReferenceInputSpan(0, 4),
      );
    });

    test('attaches controls after a surrogate pair to the whole scalar', () {
      const input = 'A😀\u200fB';
      final result = ReferenceInputNormalizer.normalizeDetailed(input);

      expect(result.normalizedText, 'A😀B');
      expect(
        result.mapNormalizedSpan(1, 3),
        const ReferenceInputSpan(1, 4),
      );
      expect(result.originalTextFor(1, 3), '😀\u200f');
    });

    test('maps zero-width boundaries deterministically', () {
      final result = ReferenceInputNormalizer.normalizeDetailed('A\u200fB');

      expect(
        result.mapNormalizedSpan(0, 0),
        const ReferenceInputSpan(0, 0),
      );
      expect(
        result.mapNormalizedSpan(1, 1),
        const ReferenceInputSpan(2, 2),
      );
      expect(
        result.mapNormalizedSpan(2, 2),
        const ReferenceInputSpan(3, 3),
      );
    });

    test('preserves a source extent when the complete input is removed', () {
      final result = ReferenceInputNormalizer.normalizeDetailed(
        '\u200f\u0301\u200e',
      );

      expect(result.normalizedText, isEmpty);
      expect(result.sourceSpans, isEmpty);
      expect(
        result.mapNormalizedSpan(0, 0),
        const ReferenceInputSpan(0, 3),
      );
      expect(result.originalTextFor(0, 0), '\u200f\u0301\u200e');
    });

    test('returns an immutable mapping', () {
      final result = ReferenceInputNormalizer.normalizeDetailed('John');

      expect(
        () => result.sourceSpans.add(const ReferenceInputSpan(0, 0)),
        throwsUnsupportedError,
      );
    });

    test('validates normalized span bounds', () {
      final result = ReferenceInputNormalizer.normalizeDetailed('John');

      expect(() => result.mapNormalizedSpan(-1, 1), throwsRangeError);
      expect(() => result.mapNormalizedSpan(0, 5), throwsRangeError);
      expect(() => result.mapNormalizedSpan(3, 2), throwsArgumentError);
    });
  });

  group('ReferenceInputSpan', () {
    test('is an immutable value and extracts text', () {
      const first = ReferenceInputSpan(1, 3);
      const second = ReferenceInputSpan(1, 3);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.length, 2);
      expect(first.isEmpty, isFalse);
      expect(first.textFrom('A😀B'), '😀');
      expect(first.toString(), 'ReferenceInputSpan(1, 3)');
    });
  });
}
