/// Dependency-free Unicode normalization for Bible-reference input.
///
/// This is deliberately a small, reference-syntax-oriented normalization
/// rather than general Unicode NFKD normalization. It keeps letter case and
/// whitespace runs unchanged.
abstract final class ReferenceInputNormalizer {
  /// Returns [input] with common compatibility characters normalized.
  static String normalize(String input) =>
      normalizeDetailed(input).normalizedText;

  /// Normalizes [input] and preserves the UTF-16 source span of every output
  /// code unit.
  static ReferenceInputNormalization normalizeDetailed(String input) {
    final output = StringBuffer();
    final mutableSpans = <_MutableInputSpan>[];
    int? pendingRemovedStart;
    var lastEmissionStart = 0;
    var inputOffset = 0;

    while (inputOffset < input.length) {
      final decoded = _decodeCodePoint(input, inputOffset);
      final sourceEnd = inputOffset + decoded.width;

      if (_isRemovedCodePoint(decoded.value)) {
        if (mutableSpans.isEmpty) {
          pendingRemovedStart ??= inputOffset;
        } else {
          for (var i = lastEmissionStart; i < mutableSpans.length; i++) {
            mutableSpans[i].end = sourceEnd;
          }
        }
        inputOffset = sourceEnd;
        continue;
      }

      final normalizedCodePoint = _normalizeCodePoint(decoded.value);
      final sourceStart = pendingRemovedStart ?? inputOffset;
      pendingRemovedStart = null;
      lastEmissionStart = mutableSpans.length;
      output.writeCharCode(normalizedCodePoint);

      final outputWidth = normalizedCodePoint > 0xffff ? 2 : 1;
      for (var i = 0; i < outputWidth; i++) {
        mutableSpans.add(_MutableInputSpan(sourceStart, sourceEnd));
      }
      inputOffset = sourceEnd;
    }

    return ReferenceInputNormalization._(
      originalText: input,
      normalizedText: output.toString(),
      sourceSpans: List<ReferenceInputSpan>.unmodifiable(
        mutableSpans.map(
          (span) => ReferenceInputSpan(span.start, span.end),
        ),
      ),
    );
  }

  static _DecodedCodePoint _decodeCodePoint(String input, int offset) {
    final first = input.codeUnitAt(offset);
    if (first >= 0xd800 && first <= 0xdbff && offset + 1 < input.length) {
      final second = input.codeUnitAt(offset + 1);
      if (second >= 0xdc00 && second <= 0xdfff) {
        return _DecodedCodePoint(
          0x10000 + ((first - 0xd800) << 10) + second - 0xdc00,
          2,
        );
      }
    }
    return _DecodedCodePoint(first, 1);
  }

  static int _normalizeCodePoint(int value) {
    // Fullwidth ASCII forms.
    if (value >= 0xff01 && value <= 0xff5e) return value - 0xfee0;

    // Arabic-Indic and Eastern Arabic/Persian digits.
    if (value >= 0x0660 && value <= 0x0669) return 0x30 + value - 0x0660;
    if (value >= 0x06f0 && value <= 0x06f9) return 0x30 + value - 0x06f0;

    if (_isComma(value)) return 0x2c;
    if (_isSemicolon(value)) return 0x3b;
    if (_isColon(value)) return 0x3a;
    if (_isDash(value)) return 0x2d;
    if (_isSpace(value)) return 0x20;
    return value;
  }

  static bool _isComma(int value) =>
      value == 0x060c ||
      value == 0x3001 ||
      value == 0xfe10 ||
      value == 0xfe11 ||
      value == 0xfe50 ||
      value == 0xfe51 ||
      value == 0xff64;

  static bool _isSemicolon(int value) =>
      value == 0x061b || value == 0xfe14 || value == 0xfe54;

  static bool _isColon(int value) =>
      value == 0x2236 || value == 0xfe13 || value == 0xfe55;

  static bool _isDash(int value) =>
      value == 0x05be ||
      (value >= 0x2010 && value <= 0x2015) ||
      value == 0x2212 ||
      value == 0x2e3a ||
      value == 0x2e3b ||
      value == 0xfe58 ||
      value == 0xfe63;

  static bool _isSpace(int value) =>
      value == 0x00a0 ||
      (value >= 0x2000 && value <= 0x200a) ||
      value == 0x202f ||
      value == 0x205f ||
      value == 0x3000;

  static bool _isRemovedCodePoint(int value) =>
      _isBidiControl(value) ||
      _isInvisibleFormat(value) ||
      _isVariationSelector(value) ||
      _isCombiningDiacritic(value) ||
      _isHebrewMark(value) ||
      _isArabicMark(value);

  static bool _isBidiControl(int value) =>
      value == 0x061c ||
      value == 0x200e ||
      value == 0x200f ||
      (value >= 0x202a && value <= 0x202e) ||
      (value >= 0x2066 && value <= 0x206f);

  static bool _isInvisibleFormat(int value) =>
      value == 0x00ad ||
      value == 0x180e ||
      (value >= 0x200b && value <= 0x200d) ||
      value == 0x2060 ||
      value == 0xfeff;

  static bool _isVariationSelector(int value) =>
      (value >= 0xfe00 && value <= 0xfe0f) ||
      (value >= 0xe0100 && value <= 0xe01ef);

  static bool _isCombiningDiacritic(int value) =>
      (value >= 0x0300 && value <= 0x036f) ||
      (value >= 0x1dc0 && value <= 0x1dff) ||
      (value >= 0x20d0 && value <= 0x20ff) ||
      (value >= 0xfe20 && value <= 0xfe2f);

  static bool _isHebrewMark(int value) =>
      (value >= 0x0591 && value <= 0x05bd) ||
      value == 0x05bf ||
      (value >= 0x05c1 && value <= 0x05c2) ||
      (value >= 0x05c4 && value <= 0x05c5) ||
      value == 0x05c7;

  static bool _isArabicMark(int value) =>
      (value >= 0x0610 && value <= 0x061a) ||
      (value >= 0x064b && value <= 0x065f) ||
      value == 0x0670 ||
      (value >= 0x06d6 && value <= 0x06dc) ||
      (value >= 0x06df && value <= 0x06e4) ||
      (value >= 0x06e7 && value <= 0x06e8) ||
      (value >= 0x06ea && value <= 0x06ed) ||
      (value >= 0x08d3 && value <= 0x08e1) ||
      (value >= 0x08e3 && value <= 0x08ff);
}

/// The normalized input and its UTF-16 mapping back to [originalText].
final class ReferenceInputNormalization {
  const ReferenceInputNormalization._({
    required this.originalText,
    required this.normalizedText,
    required this.sourceSpans,
  });

  /// The input supplied to [ReferenceInputNormalizer.normalizeDetailed].
  final String originalText;

  /// Syntax-normalized text. Letter case and whitespace runs are preserved.
  final String normalizedText;

  /// One original source span per UTF-16 code unit in [normalizedText].
  ///
  /// Both halves of a surrogate pair point to the complete original scalar.
  /// Removed marks are attached to the nearest preceding emitted scalar, or
  /// to the first scalar when they occur at the beginning of the input.
  final List<ReferenceInputSpan> sourceSpans;

  /// Whether normalization changed the input text.
  bool get changed => normalizedText != originalText;

  /// The number of UTF-16 code units in [normalizedText].
  int get normalizedLength => normalizedText.length;

  /// Maps normalized UTF-16 `[start, end)` to its exact original source span.
  ///
  /// A non-empty span that includes a normalized surrogate code unit maps to
  /// the complete source scalar. Removed controls and marks between selected
  /// output characters are included in the returned span.
  ReferenceInputSpan mapNormalizedSpan(int start, int end) {
    RangeError.checkValueInInterval(
      start,
      0,
      normalizedText.length,
      'start',
    );
    RangeError.checkValueInInterval(end, 0, normalizedText.length, 'end');
    if (end < start) {
      throw ArgumentError.value(end, 'end', 'must not be less than start');
    }

    if (start < end) {
      return ReferenceInputSpan(
        sourceSpans[start].start,
        sourceSpans[end - 1].end,
      );
    }

    if (sourceSpans.isEmpty) {
      // The only normalized span is empty. When normalization removed the
      // complete input, preserving that source extent is more useful than
      // silently losing it (and makes full-input mapping lossless).
      return ReferenceInputSpan(0, originalText.length);
    }
    if (start == 0) {
      final offset = sourceSpans.first.start;
      return ReferenceInputSpan(offset, offset);
    }
    if (start == sourceSpans.length) {
      final offset = sourceSpans.last.end;
      return ReferenceInputSpan(offset, offset);
    }
    final offset = sourceSpans[start].start;
    return ReferenceInputSpan(offset, offset);
  }

  /// Returns the original source text represented by normalized `[start,end)`.
  String originalTextFor(int start, int end) {
    final span = mapNormalizedSpan(start, end);
    return originalText.substring(span.start, span.end);
  }
}

/// A half-open UTF-16 source span.
final class ReferenceInputSpan {
  const ReferenceInputSpan(this.start, this.end)
      : assert(start >= 0),
        assert(end >= start);

  /// Inclusive UTF-16 start offset.
  final int start;

  /// Exclusive UTF-16 end offset.
  final int end;

  /// Number of UTF-16 code units in this span.
  int get length => end - start;

  /// Whether this span contains no UTF-16 code units.
  bool get isEmpty => start == end;

  /// Extracts this span from [text].
  String textFrom(String text) => text.substring(start, end);

  @override
  bool operator ==(Object other) =>
      other is ReferenceInputSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ReferenceInputSpan($start, $end)';
}

final class _MutableInputSpan {
  _MutableInputSpan(this.start, this.end);

  final int start;
  int end;
}

final class _DecodedCodePoint {
  const _DecodedCodePoint(this.value, this.width);

  final int value;
  final int width;
}
