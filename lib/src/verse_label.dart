part of '../references.dart';

/// The verse label of one text entry in a Bible translation.
///
/// A source may store combined verses under a label such as `3-4`, or divide a
/// verse into entries such as `5a` and `5b`. This model preserves that exact
/// [source] while exposing normalized verse numbers and subdivision letters.
/// It describes one source entry; an ordinary [VerseRangeRef] describes only
/// the range and does not imply that its verses share a text entry.
///
/// Labels contain a verse number, optionally followed by one letter `a`-`z`,
/// and an optional ascending endpoint in the same chapter. Uppercase letters
/// and the Unicode syntax supported by [ReferenceInputNormalizer] are accepted.
/// Numbers use the same broad sanity limits as [VerseRef].
///
/// ```dart
/// final label = VerseLabel.parse('3–4');
/// print(label.source); // 3–4
/// print(label.displayString); // 3-4
/// final reference = label.toReference(book: BibleBookEnum.john, chapter: 1);
/// ```
final class VerseLabel {
  const VerseLabel._({
    required this.source,
    required this.startVerse,
    required this.startSubdivision,
    required this.endVerse,
    required this.endSubdivision,
  });

  /// Parses one source label, retaining its exact original spelling.
  ///
  /// Throws [ParseVerseRefError] for invalid syntax, numbers, or range order.
  factory VerseLabel.parse(String label) =>
      _parseNormalized(label, _normalize(label));

  /// The exact source label, including whitespace, case, digits, and dashes.
  final String source;

  /// The verse number at the start of this entry (1-based).
  final int startVerse;

  /// The lowercase starting subdivision letter, or `null` for a whole verse.
  final String? startSubdivision;

  /// The ending verse number for a combined entry, or `null` for one verse.
  final int? endVerse;

  /// The lowercase ending subdivision letter, or `null` for a whole verse.
  final String? endSubdivision;

  /// Whether this source entry combines a range of verses or subdivisions.
  bool get isCombined => endVerse != null;

  /// The label with ASCII numbers, lowercase subdivisions, and a hyphen.
  String get displayString {
    final start = '$startVerse${startSubdivision ?? ''}';
    return isCombined ? '$start-$endVerse${endSubdivision ?? ''}' : start;
  }

  /// Parses [label], returning `null` instead of throwing for invalid input.
  static VerseLabel? tryParse(String label) => parseResult(label).valueOrNull;

  /// Parses [label] into an explicit success or failure value.
  static ParseResult<VerseLabel> parseResult(String label) {
    final normalized = _normalize(label);
    try {
      return ParseSuccess(
        _parseNormalized(label, normalized),
        metadata: ReferenceParseMetadata(normalizedInput: normalized),
      );
    } on ParseVerseRefError catch (error) {
      return ParseFailure(error);
    }
  }

  /// Restores a source label produced by [toJson].
  factory VerseLabel.fromJson(Map<String, Object?> json) {
    final label = json['label'];
    if (label is! String) {
      throw const FormatException('label must be a string');
    }
    return VerseLabel.parse(label);
  }

  /// Creates the location covered by this entry in [book] and [chapter].
  ///
  /// Returns a [VerseRangeRef] for a combined label and a [VerseRef] otherwise.
  /// The returned reference uses normalized spelling. Retain this [VerseLabel]
  /// alongside the text entry to preserve its original source label.
  Reference toReference({required BibleBookEnum book, required int chapter}) {
    final start = VerseRef.checked(
      book: book,
      chapter: chapter,
      verse: startVerse,
      subdivision: startSubdivision,
    );
    final lastVerse = endVerse;
    if (lastVerse == null) return start;
    return VerseRangeRef.checked(
      start: start,
      end: VerseRef.checked(
        book: book,
        chapter: chapter,
        verse: lastVerse,
        subdivision: endSubdivision,
      ),
    );
  }

  /// Serializes the exact source label without expanding a combined entry.
  Map<String, Object?> toJson() => {'label': source};

  static String _normalize(String label) =>
      ReferenceInputNormalizer.normalize(label)
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');

  static final _pattern =
      RegExp(r'^([0-9]+[a-zA-Z]?)(?:\s*-\s*([0-9]+[a-zA-Z]?))?$');

  static VerseLabel _parseNormalized(String source, String normalized) {
    if (normalized.isEmpty) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.emptyReference,
        details: 'verse label is empty',
      );
    }
    final match = _pattern.firstMatch(normalized);
    if (match == null || match.end != normalized.length) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.patternMismatch,
        details: 'expected a verse label such as 3-4, 5a, or 5a-5b',
      );
    }
    final start = _parseVerseToken(match.group(1)!, component: 'verse');
    final endToken = match.group(2);
    final end = endToken == null
        ? null
        : _parseVerseToken(endToken, component: 'end verse');
    if (end != null &&
        (start.verse > end.verse ||
            (start.verse == end.verse &&
                (start.subdivision ?? '').compareTo(end.subdivision ?? '') >=
                    0))) {
      throw ParseVerseRefError.typed(
        code: ReferenceParseErrorCode.sameBookRangeNotAscending,
        details: 'verse label end must come after its start',
      );
    }
    return VerseLabel._(
      source: source,
      startVerse: start.verse,
      startSubdivision: start.subdivision,
      endVerse: end?.verse,
      endSubdivision: end?.subdivision,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VerseLabel && source == other.source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => displayString;
}
