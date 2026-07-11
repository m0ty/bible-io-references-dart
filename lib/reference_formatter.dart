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
/// The first registered name or abbreviation is the canonical display term for
/// a language. Formatting falls back to English when [language] is `auto`, the
/// language has no registered data, or a particular book is missing from that
/// data.
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
      '${formatBookName(reference.book)} ${reference.chapter}:${reference.verse}';

  String _formatRange(VerseRangeRef reference) {
    final start = reference.start;
    final end = reference.end;

    if (!compactRanges || start.book != end.book) {
      return '${_formatVerse(start)}-${_formatVerse(end)}';
    }

    final startText = _formatVerse(start);
    if (start.chapter == end.chapter) {
      return '$startText-${end.verse}';
    }
    return '$startText-${end.chapter}:${end.verse}';
  }
}

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
