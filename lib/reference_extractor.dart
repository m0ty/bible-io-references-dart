import 'bible_book_enum.dart';
import 'bible_language_enum.dart';
import 'reference_input_normalizer.dart';
import 'references.dart';

/// A successfully parsed passage and its exact location in a source string.
final class PassageMatch {
  const PassageMatch({
    required this.passage,
    required this.start,
    required this.end,
    required this.sourceText,
    required this.metadata,
  });

  /// The parsed passage.
  final Passage passage;

  /// Inclusive UTF-16 offset in the original source string.
  final int start;

  /// Exclusive UTF-16 offset in the original source string.
  final int end;

  /// The exact substring at `[start, end)` in the original source.
  final String sourceText;

  /// Metadata produced by the passage parser.
  final ReferenceParseMetadata metadata;

  int get startOffset => start;

  int get endOffset => end;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassageMatch &&
          passage == other.passage &&
          start == other.start &&
          end == other.end &&
          sourceText == other.sourceText &&
          metadata == other.metadata;

  @override
  int get hashCode => Object.hash(passage, start, end, sourceText, metadata);
}

/// Creates replacement text for a passage found in an original source string.
typedef PassageReplacement = String Function(PassageMatch match);

/// Creates a destination URI for a passage found in source text.
typedef PassageUriBuilder = Uri Function(PassageMatch match);

/// Finds parseable Bible passages embedded in arbitrary prose.
///
/// Extraction is parser-driven rather than tied to one language's book-name
/// regular expression. Matches are returned from left to right, never overlap,
/// and prefer the longest parse that begins at a given source offset.
final class ReferenceExtractor {
  ReferenceExtractor({
    PassageParser? parser,
    this.includeBareBooks = false,
    this.maxLookBehind = 96,
    this.maxLookAhead = 256,
  }) : parser = parser ?? PassageParser() {
    RangeError.checkValueInInterval(
      maxLookBehind,
      1,
      4096,
      'maxLookBehind',
    );
    RangeError.checkValueInInterval(
      maxLookAhead,
      1,
      4096,
      'maxLookAhead',
    );
  }

  /// Parser used to validate every candidate span.
  final PassageParser parser;

  /// Whether whole-book passages without chapter or verse syntax are included.
  final bool includeBareBooks;

  /// Maximum number of UTF-16 code units searched before a numeric anchor.
  final int maxLookBehind;

  /// Maximum number of UTF-16 code units searched after a numeric anchor.
  final int maxLookAhead;

  /// Finds deterministic, non-overlapping passages in [source].
  List<PassageMatch> extract(
    String source, {
    BibleLanguageEnum? language,
  }) {
    if (source.isEmpty) return const [];

    final normalization = ReferenceInputNormalizer.normalizeDetailed(source);
    final searchText = normalization.normalizedText;
    final candidates = <(int, int), PassageMatch>{};
    final anchors = _numericAnchors(searchText);
    for (final anchor in anchors) {
      final minimumStart =
          _clamp(anchor.$1 - maxLookBehind, 0, searchText.length);
      final maximumEnd = _clamp(anchor.$2 + maxLookAhead, 0, searchText.length);
      _searchWindow(
        searchText,
        normalization: normalization,
        minimumStart: minimumStart,
        requiredStartBefore: anchor.$1,
        requiredEndAfter: anchor.$2,
        maximumEnd: maximumEnd,
        language: language,
        output: candidates,
      );
    }

    if (includeBareBooks) {
      _searchBarePassages(
        searchText,
        normalization: normalization,
        language: language,
        output: candidates,
      );
    }

    final ordered = candidates.values.toList()
      ..sort((left, right) {
        final startComparison = left.start.compareTo(right.start);
        if (startComparison != 0) return startComparison;
        return right.end.compareTo(left.end);
      });

    final selected = <PassageMatch>[];
    var consumedThrough = 0;
    for (final candidate in ordered) {
      if (candidate.start < consumedThrough) continue;
      selected.add(candidate);
      consumedThrough = candidate.end;
    }
    return List.unmodifiable(selected);
  }

  /// Alias for [extract].
  List<PassageMatch> findAll(
    String source, {
    BibleLanguageEnum? language,
  }) =>
      extract(source, language: language);

  /// Replaces matches in one pass without scanning replacement text again.
  String replaceMatches(
    String source,
    PassageReplacement replacement, {
    BibleLanguageEnum? language,
  }) {
    final matches = extract(source, language: language);
    if (matches.isEmpty) return source;

    final output = StringBuffer();
    var copiedThrough = 0;
    for (final match in matches) {
      output.write(source.substring(copiedThrough, match.start));
      output.write(replacement(match));
      copiedThrough = match.end;
    }
    output.write(source.substring(copiedThrough));
    return output.toString();
  }

  /// Linkifies matches with a caller-provided renderer.
  String linkify(
    String source,
    PassageReplacement linkBuilder, {
    BibleLanguageEnum? language,
  }) =>
      replaceMatches(source, linkBuilder, language: language);

  /// Replaces matches with Markdown links.
  String linkifyMarkdown(
    String source, {
    required PassageUriBuilder uriBuilder,
    String Function(PassageMatch match)? labelBuilder,
    BibleLanguageEnum? language,
  }) {
    return replaceMatches(
      source,
      (match) {
        final label = _escapeMarkdownLabel(
          labelBuilder?.call(match) ?? match.sourceText,
        );
        final destination = _escapeMarkdownDestination(uriBuilder(match));
        return '[$label]($destination)';
      },
      language: language,
    );
  }

  /// Alias for [linkifyMarkdown].
  String markdownLinkify(
    String source, {
    required PassageUriBuilder uriBuilder,
    String Function(PassageMatch match)? labelBuilder,
    BibleLanguageEnum? language,
  }) =>
      linkifyMarkdown(
        source,
        uriBuilder: uriBuilder,
        labelBuilder: labelBuilder,
        language: language,
      );

  void _searchWindow(
    String searchText, {
    required ReferenceInputNormalization normalization,
    required int minimumStart,
    required int requiredStartBefore,
    required int requiredEndAfter,
    required int maximumEnd,
    required BibleLanguageEnum? language,
    required Map<(int, int), PassageMatch> output,
  }) {
    final starts = <int>[];
    for (var index = minimumStart; index < requiredStartBefore; index++) {
      if (_canStartAt(searchText, index)) starts.add(index);
    }

    final ends = <int>[];
    for (var index = requiredEndAfter; index <= maximumEnd; index++) {
      if (_canNumericEndAt(searchText, index)) ends.add(index);
    }

    for (final start in starts) {
      for (final end in ends.reversed) {
        if (end <= start || !_hasSafeOuterBoundaries(searchText, start, end)) {
          continue;
        }
        final matched = _tryCandidate(
          searchText,
          start,
          end,
          normalization: normalization,
          language: language,
          output: output,
        );
        if (matched) break;
      }
    }
  }

  void _searchBarePassages(
    String searchText, {
    required ReferenceInputNormalization normalization,
    required BibleLanguageEnum? language,
    required Map<(int, int), PassageMatch> output,
  }) {
    for (var start = 0; start < searchText.length; start++) {
      if (!_canStartAt(searchText, start)) continue;
      final maximumEnd = _clamp(start + maxLookAhead, 0, searchText.length);
      for (var end = maximumEnd; end > start; end--) {
        if (!_canEndAt(searchText, end) ||
            !_hasSafeOuterBoundaries(searchText, start, end)) {
          continue;
        }
        _tryCandidate(
          searchText,
          start,
          end,
          normalization: normalization,
          language: language,
          output: output,
        );
      }
    }
  }

  bool _tryCandidate(
    String searchText,
    int start,
    int end, {
    required ReferenceInputNormalization normalization,
    required BibleLanguageEnum? language,
    required Map<(int, int), PassageMatch> output,
  }) {
    final normalizedCandidate = searchText.substring(start, end);
    final normalizedResult =
        parser.parseResult(normalizedCandidate, language: language);
    final normalizedPassage = normalizedResult.valueOrNull;
    final normalizedMetadata = normalizedResult.metadataOrNull;
    if (normalizedPassage == null || normalizedMetadata == null) return false;
    if (!includeBareBooks &&
        (_containsBareBook(normalizedPassage) ||
            !_containsReferenceNumber(normalizedCandidate))) {
      return false;
    }
    var passage = normalizedPassage;
    var metadata = normalizedMetadata;

    final mappedSpan = normalization.mapNormalizedSpan(start, end);
    final originalSpan = _trimBidiControls(
      normalization.originalText,
      mappedSpan,
    );
    final key = (originalSpan.start, originalSpan.end);
    if (output.containsKey(key)) return true;
    final sourceText = normalization.originalText.substring(
      originalSpan.start,
      originalSpan.end,
    );
    final originalResult = parser.parseResult(sourceText, language: language);
    final originalPassage = originalResult.valueOrNull;
    final originalMetadata = originalResult.metadataOrNull;
    if (originalPassage != null && originalMetadata != null) {
      passage = originalPassage;
      metadata = originalMetadata;
    }
    if (_looksLikeCommonWord(metadata, language: language)) return false;

    output[key] = PassageMatch(
      passage: passage,
      start: originalSpan.start,
      end: originalSpan.end,
      sourceText: sourceText,
      metadata: metadata,
    );
    return true;
  }
}

List<(int, int)> _numericAnchors(String source) {
  final anchors = <(int, int)>[];
  var index = 0;
  while (index < source.length) {
    if (!_isReferenceDigit(source.codeUnitAt(index))) {
      index++;
      continue;
    }
    final start = index;
    do {
      index++;
    } while (
        index < source.length && _isReferenceDigit(source.codeUnitAt(index)));
    anchors.add((start, index));
  }
  return anchors;
}

bool _containsReferenceNumber(String value) {
  for (var index = 0; index < value.length; index++) {
    if (_isReferenceDigit(value.codeUnitAt(index))) return true;
  }
  return false;
}

bool _containsBareBook(Passage passage) => switch (passage) {
      BookPassage() => true,
      ChapterPassage() => false,
      VersePassage() => false,
      PassageSequence(:final passages) => passages.any(_containsBareBook),
    };

bool _isReferenceDigit(int codeUnit) =>
    (codeUnit >= 0x30 && codeUnit <= 0x39) ||
    (codeUnit >= 0x0660 && codeUnit <= 0x0669) ||
    (codeUnit >= 0x06f0 && codeUnit <= 0x06f9) ||
    (codeUnit >= 0xff10 && codeUnit <= 0xff19);

bool _canStartAt(String source, int index) {
  if (index < 0 || index >= source.length) return false;
  final current = source.codeUnitAt(index);
  if (_isLowSurrogate(current) || _isEdgeDelimiter(current)) return false;
  if (index == 0) return true;
  final previous = source.codeUnitAt(index - 1);
  return !(_isAsciiWord(previous) && _isAsciiWord(current));
}

bool _canEndAt(String source, int index) {
  if (index <= 0 || index > source.length) return false;
  if (index < source.length && _isLowSurrogate(source.codeUnitAt(index))) {
    return false;
  }
  return !_isEdgeDelimiter(source.codeUnitAt(index - 1));
}

bool _canNumericEndAt(String source, int index) =>
    _canEndAt(source, index) && _isReferenceDigit(source.codeUnitAt(index - 1));

ReferenceInputSpan _trimBidiControls(
  String source,
  ReferenceInputSpan span,
) {
  var start = span.start;
  var end = span.end;
  while (start < end && _isBidiControl(source.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _isBidiControl(source.codeUnitAt(end - 1))) {
    end--;
  }
  return ReferenceInputSpan(start, end);
}

bool _isBidiControl(int codeUnit) =>
    codeUnit == 0x061c ||
    codeUnit == 0x200e ||
    codeUnit == 0x200f ||
    (codeUnit >= 0x202a && codeUnit <= 0x202e) ||
    (codeUnit >= 0x2066 && codeUnit <= 0x206f);

bool _hasSafeOuterBoundaries(String source, int start, int end) {
  if (start > 0 &&
      _isAsciiWord(source.codeUnitAt(start - 1)) &&
      _isAsciiWord(source.codeUnitAt(start))) {
    return false;
  }
  if (end < source.length &&
      _isAsciiWord(source.codeUnitAt(end - 1)) &&
      _isAsciiWord(source.codeUnitAt(end))) {
    return false;
  }
  return true;
}

bool _looksLikeCommonWord(
  ReferenceParseMetadata metadata, {
  required BibleLanguageEnum? language,
}) {
  for (final match in metadata.bookMatches) {
    final book = match.selected.book;
    final token = match.input.trimLeft();
    final compactToken =
        token.toLowerCase().replaceAll(' ', '').replaceAll('.', '');
    if ((language == null || language == BibleLanguageEnum.auto) &&
        _commonAutoLanguageWords.contains(compactToken)) {
      return true;
    }
    var firstAsciiLetterIsLowercase = false;
    var asciiLetterCount = 0;
    var isSimpleAsciiAlias = true;
    for (var index = 0; index < token.length; index++) {
      final codeUnit = token.codeUnitAt(index);
      if (codeUnit >= 0x41 && codeUnit <= 0x5a) {
        asciiLetterCount++;
      } else if (codeUnit >= 0x61 && codeUnit <= 0x7a) {
        firstAsciiLetterIsLowercase |= asciiLetterCount == 0;
        asciiLetterCount++;
      } else if (codeUnit != 0x20 &&
          codeUnit != 0x2e &&
          !_isReferenceDigit(codeUnit)) {
        isSimpleAsciiAlias = false;
      }
    }
    if (!firstAsciiLetterIsLowercase) continue;
    if (book == BibleBookEnum.mark || book == BibleBookEnum.job) return true;
    if ((language == null || language == BibleLanguageEnum.auto) &&
        isSimpleAsciiAlias &&
        asciiLetterCount <= 3) {
      return true;
    }
  }
  return false;
}

const _commonAutoLanguageWords = {'am', 'at', 'is', 'so'};

bool _isAsciiWord(int codeUnit) =>
    (codeUnit >= 0x30 && codeUnit <= 0x39) ||
    (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
    (codeUnit >= 0x61 && codeUnit <= 0x7a) ||
    codeUnit == 0x5f;

bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xdc00 && codeUnit <= 0xdfff;

bool _isEdgeDelimiter(int codeUnit) =>
    codeUnit <= 0x20 ||
    codeUnit == 0x7f ||
    codeUnit == 0x200e ||
    codeUnit == 0x200f ||
    (codeUnit >= 0x202a && codeUnit <= 0x202e) ||
    (codeUnit >= 0x2066 && codeUnit <= 0x2069) ||
    '.,!?;:()[]{}<>"\''.codeUnits.contains(codeUnit);

int _clamp(int value, int minimum, int maximum) =>
    value < minimum ? minimum : (value > maximum ? maximum : value);

String _escapeMarkdownLabel(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll('[', '\\[')
    .replaceAll(']', '\\]');

String _escapeMarkdownDestination(Uri value) =>
    value.toString().replaceAll('(', '%28').replaceAll(')', '%29');
