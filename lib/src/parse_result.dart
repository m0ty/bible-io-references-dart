part of '../references.dart';

/// A typed classification for reference parsing failures.
enum ReferenceParseErrorCode {
  emptyReference('empty_reference'),
  patternMismatch('pattern_mismatch'),
  unknownBook('unknown_book'),
  invalidNumericToken('invalid_numeric_token'),
  nonPositiveNumericToken('non_positive_numeric_token'),
  numericTokenOutOfRange('numeric_token_out_of_range'),
  emptyBookToken('empty_book_token'),
  ambiguousBook('ambiguous_book'),
  unsupportedLanguage('unsupported_language'),
  sameBookRangeNotAscending('same_book_range_not_ascending'),
  crossBookRangeNotAscending('cross_book_range_not_ascending'),
  missingNumericToken('missing_numeric_token'),
  unknown('unknown');

  const ReferenceParseErrorCode(this.wireName);

  /// Stable machine-readable name used by the legacy [ParseVerseRefError.code].
  final String wireName;

  /// Resolves a legacy string code to its typed equivalent.
  static ReferenceParseErrorCode fromWireName(String value) {
    for (final code in values) {
      if (code.wireName == value) return code;
    }
    return unknown;
  }
}

/// The result of a non-throwing parse operation.
sealed class ParseResult<T> {
  const ParseResult();

  bool get isSuccess;

  T? get valueOrNull;

  ParseVerseRefError? get errorOrNull;

  /// Metadata recorded while parsing, or `null` when parsing failed.
  ReferenceParseMetadata? get metadataOrNull;
}

/// A successful [ParseResult].
final class ParseSuccess<T> extends ParseResult<T> {
  const ParseSuccess(
    this.value, {
    this.metadata = ReferenceParseMetadata.empty,
  });

  final T value;

  /// Information about normalization, language detection, and book matching.
  final ReferenceParseMetadata metadata;

  @override
  bool get isSuccess => true;

  @override
  T get valueOrNull => value;

  @override
  ParseVerseRefError? get errorOrNull => null;

  @override
  ReferenceParseMetadata get metadataOrNull => metadata;
}

/// A failed [ParseResult].
final class ParseFailure<T> extends ParseResult<T> {
  const ParseFailure(this.error);

  final ParseVerseRefError error;

  @override
  bool get isSuccess => false;

  @override
  T? get valueOrNull => null;

  @override
  ParseVerseRefError get errorOrNull => error;

  @override
  ReferenceParseMetadata? get metadataOrNull => null;
}

/// Raised when a verse reference string cannot be parsed.
///
/// This exception provides machine-readable error codes and optional details
/// to help callers handle parsing failures appropriately.
///
/// Example:
/// ```dart
/// try {
///   final ref = VerseRef.parse("InvalidBook 3:16");
/// } on ParseVerseRefError catch (e) {
///   print("Error: ${e.code}"); // "unknown_book"
///   if (e.details != null) print("Details: ${e.details}");
/// }
/// ```
class ParseVerseRefError implements Exception {
  /// Machine-readable error code identifying the type of parsing failure.
  ///
  /// Common codes:
  /// - `"pattern_mismatch"`: Input doesn't match expected format
  /// - `"unknown_book"`: Book name/abbreviation not recognized
  /// - `"invalid_numeric_token"`: Chapter/verse is not a valid number
  /// - `"non_positive_numeric_token"`: Chapter/verse is zero or negative
  /// - `"numeric_token_out_of_range"`: Chapter/verse exceeds broad sanity limits
  /// - `"empty_reference"`: Input is empty or only whitespace
  /// - `"empty_book_token"`: Book token is empty after normalization
  /// - `"ambiguous_book"`: Several books match under a rejecting policy
  /// - `"unsupported_language"`: Language code not supported
  /// - `"same_book_range_not_ascending"`: Range end comes before start
  /// - `"missing_numeric_token"`: Required numeric component missing
  final String code;

  /// Optional human-readable details about the parsing failure.
  final String? details;

  /// Typed equivalent of the legacy string [code].
  ReferenceParseErrorCode get errorCode =>
      ReferenceParseErrorCode.fromWireName(code);

  ParseVerseRefError({
    required this.code,
    this.details,
  });

  ParseVerseRefError.typed({
    required ReferenceParseErrorCode code,
    this.details,
  }) : code = code.wireName;

  @override
  String toString() => details == null
      ? 'ParseVerseRefError($code)'
      : 'ParseVerseRefError($code): $details';
}

/// Controls how a [ReferenceParser] resolves aliases that match several books.
enum ReferenceAmbiguityPolicy {
  /// Select the first candidate according to custom-alias and language priority.
  preferLanguagePriority,

  /// Fail with [ReferenceParseErrorCode.ambiguousBook] when distinct books match.
  reject,
}

/// A single possible interpretation of a parsed book token.
final class ReferenceBookCandidate {
  const ReferenceBookCandidate({
    required this.book,
    required this.alias,
    required this.language,
    required this.isCustom,
  });

  /// The book represented by this candidate.
  final BibleBookEnum book;

  /// The registered alias that produced this candidate.
  final String alias;

  /// The alias language, or `null` for a language-neutral custom alias.
  final BibleLanguageEnum? language;

  /// Whether this candidate came from caller-provided aliases.
  final bool isCustom;

  Map<String, Object?> toJson() => {
        'book': book.abbreviation,
        'alias': alias,
        'language': language?.code,
        'custom': isCustom,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceBookCandidate &&
          book == other.book &&
          alias == other.alias &&
          language == other.language &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(book, alias, language, isCustom);
}

/// Match information for one explicit book token in the source text.
final class ReferenceBookTokenMatch {
  ReferenceBookTokenMatch({
    required this.input,
    required this.selected,
    Iterable<ReferenceBookCandidate> alternatives = const [],
  }) : alternatives = List.unmodifiable(alternatives);

  /// The syntax-normalized book token, trimmed but otherwise unchanged.
  final String input;

  /// The candidate chosen by the parser.
  final ReferenceBookCandidate selected;

  /// Other candidates that matched the same normalized token.
  final List<ReferenceBookCandidate> alternatives;

  /// The selected language, or `null` for a language-neutral custom alias.
  BibleLanguageEnum? get detectedLanguage => selected.language;

  /// Whether the token could have selected a different book.
  bool get isAmbiguous =>
      alternatives.any((candidate) => candidate.book != selected.book);

  Map<String, Object?> toJson() => {
        'input': input,
        'selected': selected.toJson(),
        'alternatives': [
          for (final candidate in alternatives) candidate.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceBookTokenMatch &&
          input == other.input &&
          selected == other.selected &&
          _listsEqual(alternatives, other.alternatives);

  @override
  int get hashCode =>
      Object.hash(input, selected, Object.hashAll(alternatives));
}

/// Metadata captured while a reference is parsed successfully.
final class ReferenceParseMetadata {
  ReferenceParseMetadata({
    required this.normalizedInput,
    Iterable<ReferenceBookTokenMatch> bookMatches = const [],
  }) : bookMatches = List.unmodifiable(bookMatches);

  const ReferenceParseMetadata._({
    required this.normalizedInput,
    required this.bookMatches,
  });

  /// Empty metadata used by manually-created [ParseSuccess] values.
  static const empty = ReferenceParseMetadata._(
    normalizedInput: '',
    bookMatches: <ReferenceBookTokenMatch>[],
  );

  /// The Unicode-syntax-normalized, trimmed, whitespace-normalized source.
  final String normalizedInput;

  /// Matches for each explicit book token in source order.
  final List<ReferenceBookTokenMatch> bookMatches;

  /// Every distinct language selected for explicit book tokens.
  Set<BibleLanguageEnum> get detectedLanguages => Set.unmodifiable(
        bookMatches
            .map((match) => match.detectedLanguage)
            .whereType<BibleLanguageEnum>(),
      );

  /// The one detected language, or `null` for mixed/no-language matches.
  BibleLanguageEnum? get detectedLanguage {
    final languages = detectedLanguages;
    return languages.length == 1 ? languages.first : null;
  }

  /// All non-selected book candidates in source order.
  List<ReferenceBookCandidate> get alternateMatches => List.unmodifiable(
        bookMatches.expand((match) => match.alternatives),
      );

  /// Whether any explicit token matched more than one distinct book.
  bool get hasAmbiguity => bookMatches.any((match) => match.isAmbiguous);

  Map<String, Object?> toJson() => {
        'normalizedInput': normalizedInput,
        'detectedLanguage': detectedLanguage?.code,
        'detectedLanguages': [
          for (final language in detectedLanguages) language.code,
        ],
        'bookMatches': [for (final match in bookMatches) match.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceParseMetadata &&
          normalizedInput == other.normalizedInput &&
          _listsEqual(bookMatches, other.bookMatches);

  @override
  int get hashCode => Object.hash(normalizedInput, Object.hashAll(bookMatches));
}
