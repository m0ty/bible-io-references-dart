part of '../references.dart';

/// A complete Bible passage expression.
///
/// Unlike [Reference], passages can describe whole books or chapters, a
/// selection of verses, or a semicolon-separated sequence of those forms.
sealed class Passage {
  const Passage();

  /// Parses [input] using the shared standard passage parser.
  static Passage parse(
    String input, {
    BibleLanguageEnum? language,
  }) =>
      _standardPassageParser.parse(input, language: language);

  /// Parses [input], returning `null` instead of throwing when it is invalid.
  static Passage? tryParse(
    String input, {
    BibleLanguageEnum? language,
  }) =>
      _standardPassageParser.tryParse(input, language: language);

  /// Parses [input] into an explicit success or failure value.
  static ParseResult<Passage> parseResult(
    String input, {
    BibleLanguageEnum? language,
  }) =>
      _standardPassageParser.parseResult(input, language: language);

  /// Restores a passage produced by [toJson].
  static Passage fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'book' => BookPassage.fromJson(json),
      'chapter' => ChapterPassage.fromJson(json),
      'verses' => VersePassage.fromJson(json),
      'sequence' => PassageSequence.fromJson(json),
      final type => throw FormatException('unknown passage type: $type'),
    };
  }

  /// A compact, canonical representation of this passage.
  String get displayString;

  /// Converts this passage to a stable JSON-compatible map.
  Map<String, Object?> toJson();

  @override
  String toString() => displayString;
}

/// A passage covering an entire Bible book.
final class BookPassage extends Passage {
  const BookPassage(this.book);

  final BibleBookEnum book;

  static BookPassage fromJson(Map<String, Object?> json) =>
      BookPassage(_bookFromJson(json['book']));

  @override
  String get displayString => book.fullName;

  @override
  Map<String, Object?> toJson() => {
        'type': 'book',
        'book': book.abbreviation,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BookPassage && book == other.book;

  @override
  int get hashCode => book.hashCode;
}

/// A passage covering one chapter or an inclusive range of chapters.
final class ChapterPassage extends Passage {
  factory ChapterPassage(
    BibleBookEnum book,
    int startChapter, [
    int? endChapter,
  ]) {
    _validateReferenceNumber(
      startChapter,
      component: 'startChapter',
      maximum: maxReferenceChapterNumber,
    );
    if (endChapter != null) {
      _validateReferenceNumber(
        endChapter,
        component: 'endChapter',
        maximum: maxReferenceChapterNumber,
      );
      if (endChapter <= startChapter) {
        throw ArgumentError.value(
          endChapter,
          'endChapter',
          'must come after startChapter',
        );
      }
    }
    return ChapterPassage._(book, startChapter, endChapter);
  }

  const ChapterPassage._(this.book, this.startChapter, this.endChapter);

  /// Creates a chapter passage while enforcing numeric and ordering checks.
  factory ChapterPassage.checked({
    required BibleBookEnum book,
    required int startChapter,
    int? endChapter,
  }) =>
      ChapterPassage(book, startChapter, endChapter);

  final BibleBookEnum book;
  final int startChapter;
  final int? endChapter;

  static ChapterPassage fromJson(Map<String, Object?> json) {
    final end = json['endChapter'];
    if (end != null && end is! int) {
      throw const FormatException('"endChapter" must be an integer or null');
    }
    return ChapterPassage(
      _bookFromJson(json['book']),
      _intFromJson(json, 'startChapter'),
      end as int?,
    );
  }

  @override
  String get displayString => endChapter == null
      ? '${book.fullName} $startChapter'
      : '${book.fullName} $startChapter-$endChapter';

  @override
  Map<String, Object?> toJson() => {
        'type': 'chapter',
        'book': book.abbreviation,
        'startChapter': startChapter,
        'endChapter': endChapter,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterPassage &&
          book == other.book &&
          startChapter == other.startChapter &&
          endChapter == other.endChapter;

  @override
  int get hashCode => Object.hash(book, startChapter, endChapter);
}

/// One or more discrete verse references belonging to one passage expression.
final class VersePassage extends Passage {
  factory VersePassage(List<Reference> selections) {
    if (selections.isEmpty) {
      throw ArgumentError.value(
        selections,
        'selections',
        'must contain at least one reference',
      );
    }
    return VersePassage._(List<Reference>.unmodifiable(selections));
  }

  const VersePassage._(this.selections);

  /// Creates a verse passage while checking that it is not empty.
  factory VersePassage.checked({
    required Iterable<Reference> selections,
  }) =>
      VersePassage(List<Reference>.of(selections));

  final List<Reference> selections;

  static VersePassage fromJson(Map<String, Object?> json) {
    final values = json['selections'];
    if (values is! List) {
      throw const FormatException('"selections" must be an array');
    }
    return VersePassage([
      for (final value in values)
        Reference.fromJson(_jsonObject(value, 'selection')),
    ]);
  }

  @override
  String get displayString {
    final first = selections.first;
    final anchor = _referenceStart(first);
    final buffer = StringBuffer(first.displayString);
    for (final selection in selections.skip(1)) {
      buffer
        ..write(',')
        ..write(_compactSelectionString(selection, anchor));
    }
    return buffer.toString();
  }

  @override
  Map<String, Object?> toJson() => {
        'type': 'verses',
        'selections': [
          for (final selection in selections) selection.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersePassage && _listsEqual(selections, other.selections);

  @override
  int get hashCode => Object.hashAll(selections);
}

/// A source-ordered sequence of passage expressions.
final class PassageSequence extends Passage {
  factory PassageSequence(List<Passage> passages) {
    if (passages.isEmpty) {
      throw ArgumentError.value(
        passages,
        'passages',
        'must contain at least one passage',
      );
    }
    return PassageSequence._(List<Passage>.unmodifiable(passages));
  }

  const PassageSequence._(this.passages);

  /// Creates a sequence while checking that it is not empty.
  factory PassageSequence.checked({
    required Iterable<Passage> passages,
  }) =>
      PassageSequence(List<Passage>.of(passages));

  final List<Passage> passages;

  static PassageSequence fromJson(Map<String, Object?> json) {
    final values = json['passages'];
    if (values is! List) {
      throw const FormatException('"passages" must be an array');
    }
    return PassageSequence([
      for (final value in values)
        Passage.fromJson(_jsonObject(value, 'passage')),
    ]);
  }

  @override
  String get displayString =>
      passages.map((passage) => passage.displayString).join('; ');

  @override
  Map<String, Object?> toJson() => {
        'type': 'sequence',
        'passages': [for (final passage in passages) passage.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassageSequence && _listsEqual(passages, other.passages);

  @override
  int get hashCode => Object.hashAll(passages);
}

VerseRef _referenceStart(Reference reference) => switch (reference) {
      VerseRef() => reference,
      VerseRangeRef() => reference.start,
    };

String _compactSelectionString(Reference reference, VerseRef anchor) {
  final start = _referenceStart(reference);
  if (start.book != anchor.book) return reference.displayString;

  final prefix = start.chapter == anchor.chapter
      ? start.verseLabel
      : '${start.chapter}:${start.verseLabel}';
  if (reference is VerseRef) return prefix;
  final end = switch (reference) {
    VerseRangeRef(:final end) => end,
    VerseRef() => throw StateError('unreachable verse reference branch'),
  };
  if (end.book != start.book) {
    return '$prefix-${end.book.fullName} ${end.chapter}:${end.verseLabel}';
  }
  if (end.chapter == start.chapter) return '$prefix-${end.verseLabel}';
  return '$prefix-${end.chapter}:${end.verseLabel}';
}
