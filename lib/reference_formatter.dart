import 'bible_book_enum.dart';
import 'bible_language_enum.dart';
import 'languages.dart';
import 'references.dart';

/// Controls how book names are rendered by [ReferenceFormatter].
enum ReferenceBookNameStyle {
  /// Use a localized full book name, such as `Juan`.
  long,

  /// Use a localized abbreviation, such as `Jn`.
  short,
}

/// Formats parsed references with localized book names.
///
/// Full names use the first nonempty registered name. Abbreviations use the
/// shortest nonempty registered term, with registration order breaking ties.
/// Formatting falls back to English when [language] is `auto`, the language has
/// no registered data, or a particular book is missing from that data.
final class ReferenceFormatter {
  /// Creates a formatter with deterministic English defaults.
  const ReferenceFormatter({
    this.language = BibleLanguageEnum.english,
    this.bookNameStyle = ReferenceBookNameStyle.long,
    this.compactRanges = true,
  });

  /// The requested output language.
  final BibleLanguageEnum language;

  /// Whether book names are written in long or short form.
  final ReferenceBookNameStyle bookNameStyle;

  /// Whether repeated range components are omitted.
  ///
  /// For example, a same-chapter range is `John 3:16-17` when compact and
  /// `John 3:16-John 3:17` otherwise.
  final bool compactRanges;

  /// Formats [reference] according to this formatter's options.
  String format(Reference reference) => switch (reference) {
        VerseRef() => _formatVerse(reference),
        VerseRangeRef() => _formatRange(reference),
      };

  /// Formats a whole-book, chapter, verse-selection, or sequence [passage].
  String formatPassage(Passage passage) => switch (passage) {
        BookPassage() => formatBookName(passage.book),
        ChapterPassage() => _formatChapterPassage(passage),
        VersePassage() => _formatVersePassage(passage),
        PassageSequence() => passage.passages.map(formatPassage).join('; '),
      };

  /// Returns the localized display name for [book].
  String formatBookName(BibleBookEnum book) {
    if (language != BibleLanguageEnum.auto && language.isParsingSupported) {
      final registry = switch (bookNameStyle) {
        ReferenceBookNameStyle.long => bookNamesByLanguage,
        ReferenceBookNameStyle.short => bookAbbreviationsByLanguage,
      };
      final terms = registry[language.code]?[book];
      if (terms != null) {
        final nonEmptyTerms = terms.where((term) => term.trim().isNotEmpty);
        if (bookNameStyle == ReferenceBookNameStyle.long) {
          if (nonEmptyTerms.isNotEmpty) return nonEmptyTerms.first;
        } else {
          String? shortest;
          for (final term in nonEmptyTerms) {
            if (shortest == null || term.length < shortest.length) {
              shortest = term;
            }
          }
          if (shortest != null) return shortest;
        }
      }
    }

    return switch (bookNameStyle) {
      ReferenceBookNameStyle.long => book.fullName,
      ReferenceBookNameStyle.short => book.asStr(),
    };
  }

  String _formatVerse(VerseRef reference) =>
      '${formatBookName(reference.book)} ${reference.chapter}:${reference.verseLabel}';

  String _formatRange(VerseRangeRef reference) {
    final start = reference.start;
    final end = reference.end;

    if (!compactRanges || start.book != end.book) {
      return '${_formatVerse(start)}-${_formatVerse(end)}';
    }

    final startText = _formatVerse(start);
    if (start.chapter == end.chapter) {
      return '$startText-${end.verseLabel}';
    }
    return '$startText-${end.chapter}:${end.verseLabel}';
  }

  String _formatChapterPassage(ChapterPassage passage) {
    final start = '${formatBookName(passage.book)} ${passage.startChapter}';
    final end = passage.endChapter;
    return end == null ? start : '$start-$end';
  }

  String _formatVersePassage(VersePassage passage) {
    if (!compactRanges || passage.selections.length == 1) {
      return passage.selections.map(format).join(',');
    }

    final anchor = _referenceStart(passage.selections.first);
    final buffer = StringBuffer(format(passage.selections.first));
    for (final selection in passage.selections.skip(1)) {
      buffer
        ..write(',')
        ..write(_formatCompactSelection(selection, anchor));
    }
    return buffer.toString();
  }

  String _formatCompactSelection(Reference selection, VerseRef anchor) =>
      switch (selection) {
        VerseRef() => _formatRelativeVerse(selection, anchor),
        VerseRangeRef() => _formatRelativeRange(selection, anchor),
      };

  String _formatRelativeVerse(VerseRef verse, VerseRef anchor) {
    if (verse.book != anchor.book) return _formatVerse(verse);
    if (verse.chapter == anchor.chapter) return verse.verseLabel;
    return '${verse.chapter}:${verse.verseLabel}';
  }

  String _formatRelativeRange(VerseRangeRef range, VerseRef anchor) {
    final start = range.start;
    final end = range.end;
    if (start.book != anchor.book || end.book != anchor.book) {
      return _formatRange(range);
    }

    final startText = start.chapter == anchor.chapter
        ? start.verseLabel
        : '${start.chapter}:${start.verseLabel}';
    final endText = start.chapter == end.chapter
        ? end.verseLabel
        : '${end.chapter}:${end.verseLabel}';
    return '$startText-$endText';
  }
}

VerseRef _referenceStart(Reference reference) => switch (reference) {
      VerseRef() => reference,
      VerseRangeRef() => reference.start,
    };

/// Convenient localized formatting for parsed references.
extension LocalizedReferenceFormatting on Reference {
  /// Formats this reference with localized long or short book names.
  String format({
    BibleLanguageEnum language = BibleLanguageEnum.english,
    ReferenceBookNameStyle bookNameStyle = ReferenceBookNameStyle.long,
    bool compactRanges = true,
  }) {
    return ReferenceFormatter(
      language: language,
      bookNameStyle: bookNameStyle,
      compactRanges: compactRanges,
    ).format(this);
  }
}

/// Convenient localized formatting for whole passage expressions.
extension LocalizedPassageFormatting on Passage {
  /// Formats this passage with localized long or short book names.
  String format({
    BibleLanguageEnum language = BibleLanguageEnum.english,
    ReferenceBookNameStyle bookNameStyle = ReferenceBookNameStyle.long,
    bool compactRanges = true,
  }) {
    return ReferenceFormatter(
      language: language,
      bookNameStyle: bookNameStyle,
      compactRanges: compactRanges,
    ).formatPassage(this);
  }
}
