part of '../references.dart';

// These entrypoints retain their legacy whitespace and book-matching rules.
// Keep them separate from ReferenceParser to preserve compatibility.

final _verseRangeRefPattern = RegExp(
  r'^\s*(.+?)\s+(\d+)\s*[:.]\s*(\d+[a-zA-Z]?)\s*[-\u2013\u2014\u2015]\s*(?:(.+?)\s+)?(?:(\d+)\s*[:.]\s*)?(\d+[a-zA-Z]?)\s*$',
);

/// Book term lookup helper.
class _BookTermLookup {
  late final Map<String, BibleBookEnum> _english;
  late final Map<String, BibleBookEnum> _allLanguages;
  late final Map<String, Set<BibleBookEnum>> _autoCollisions;
  late final Map<String, Map<String, BibleBookEnum>> _byLanguage;

  _BookTermLookup() {
    _english = _buildEnglishLookup();
    _allLanguages = Map.from(_english);
    _autoCollisions = {};

    _registerTermsByLanguage(_allLanguages, bookNamesByLanguage,
        preferExisting: true, collisions: _autoCollisions);
    _registerTermsByLanguage(_allLanguages, bookAbbreviationsByLanguage,
        preferExisting: true, collisions: _autoCollisions);

    _byLanguage = {};
    final languageCodes = _defaultAutoLanguagePrecedence.where((code) =>
        bookNamesByLanguage.containsKey(code) ||
        bookAbbreviationsByLanguage.containsKey(code));
    final unorderedCodes = (bookNamesByLanguage.keys.toSet()
          ..addAll(bookAbbreviationsByLanguage.keys))
        .where((code) => !languageCodes.contains(code));

    for (final code in [...languageCodes, ...unorderedCodes]) {
      final table = <String, BibleBookEnum>{};
      final names = bookNamesByLanguage[code];
      if (names != null) {
        _registerTerms(table, names);
      }
      final abbreviations = bookAbbreviationsByLanguage[code];
      if (abbreviations != null) {
        _registerTerms(table, abbreviations);
      }
      _byLanguage[code] = table;
    }
    _byLanguage[BibleLanguageEnum.english.code] = Map.from(_english);
  }

  Map<String, Set<BibleBookEnum>> get autoCollisions => {
        for (final entry in _autoCollisions.entries)
          entry.key: Set.from(entry.value),
      };

  BibleLanguageEnum normalizeLanguage(BibleLanguageEnum? language) {
    return language ?? BibleLanguageEnum.auto;
  }

  BibleBookEnum parseBookName(String bookText, BibleLanguageEnum language) {
    final normalized =
        bookText.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) {
      throw ParseVerseRefError(
          code: 'empty_book_token',
          details: 'book token is empty after normalization');
    }

    final compact = normalized.replaceAll('.', '').replaceAll(' ', '');
    Map<String, BibleBookEnum>? lookup;

    if (language == BibleLanguageEnum.auto) {
      final englishMatch = _lookupTerm(_english, normalized);
      if (englishMatch != null) return englishMatch;
      lookup = _allLanguages;
    } else {
      lookup = _byLanguage[language.code];
    }

    if (lookup == null) {
      throw ParseVerseRefError(
          code: 'unsupported_language',
          details: 'unsupported language code: ${language.code}');
    }

    var matched = _lookupTerm(lookup, normalized);
    if (matched != null) return matched;

    if (language == BibleLanguageEnum.auto) {
      try {
        return BibleBookEnum.fromStr(compact);
      } on ParseBibleBookError {
        throw ParseVerseRefError(
            code: 'unknown_book',
            details: 'book token "$bookText" did not match known books');
      }
    }

    throw ParseVerseRefError(
        code: 'unknown_book',
        details:
            'book token "$bookText" is unknown for language ${language.code}');
  }

  static Map<String, BibleBookEnum> _buildEnglishLookup() {
    final lookup = <String, BibleBookEnum>{};
    for (final book in BibleBookEnum.values) {
      lookup[book.fullName.toLowerCase()] = book;
      lookup[book.asStr().toLowerCase()] = book;
    }
    return lookup;
  }

  static void _registerTerms(
      Map<String, BibleBookEnum> table, Map<BibleBookEnum, List<String>> source,
      {bool preferExisting = false,
      Map<String, Set<BibleBookEnum>>? collisions}) {
    for (final entry in source.entries) {
      final book = entry.key;
      for (final term in entry.value) {
        final normalized = term.toLowerCase();
        final existing = table[normalized];
        if (existing != null && existing != book && collisions != null) {
          collisions.putIfAbsent(normalized, () => {}).add(existing);
          collisions[normalized]!.add(book);
        }
        if (existing == null || !preferExisting) {
          table[normalized] = book;
        }
      }
    }
  }

  static void _registerTermsByLanguage(Map<String, BibleBookEnum> table,
      Map<String, Map<BibleBookEnum, List<String>>> source,
      {bool preferExisting = false,
      Map<String, Set<BibleBookEnum>>? collisions}) {
    final orderedLanguageCodes = _defaultAutoLanguagePrecedence
        .where((code) => source.containsKey(code));
    final unorderedLanguageCodes =
        source.keys.where((code) => !orderedLanguageCodes.contains(code));
    for (final languageCode in [
      ...orderedLanguageCodes,
      ...unorderedLanguageCodes
    ]) {
      final booksForLanguage = source[languageCode]!;
      _registerTerms(table, booksForLanguage,
          preferExisting: preferExisting, collisions: collisions);
    }
  }

  static BibleBookEnum? _lookupTerm(
      Map<String, BibleBookEnum> lookup, String normalized) {
    var direct = lookup[normalized];
    if (direct != null) return direct;

    final withoutPeriods = normalized.replaceAll('.', '');
    final noPeriodMatch = lookup[withoutPeriods];
    if (noPeriodMatch != null) return noPeriodMatch;

    return lookup[withoutPeriods.replaceAll(' ', '')];
  }
}

/// Shared book lookup instance.
final _bookLookup = _BookTermLookup();

/// Auto language collisions.
final autoLanguageCollisions = _bookLookup.autoCollisions;

/// Parse a string into a VerseRef.
VerseRef verseRefFromStr(String ref, {BibleLanguageEnum? language}) {
  _ensureReferenceIsNotEmpty(ref);
  final normalizedLanguage = _bookLookup.normalizeLanguage(language);

  final match = _verseRefPattern.firstMatch(ref);
  if (match == null) {
    throw ParseVerseRefError(
        code: 'pattern_mismatch',
        details: 'reference "$ref" does not match expected format');
  }

  final chapter = _parseReferenceNumber(
    match.group(2)!,
    component: 'chapter',
    maximum: maxReferenceChapterNumber,
  );
  final verse = _parseVerseToken(
    match.group(3)!,
    component: 'verse',
  );
  final book = _bookLookup.parseBookName(match.group(1)!, normalizedLanguage);

  return VerseRef.checked(
      book: book,
      chapter: chapter,
      verse: verse.verse,
      subdivision: verse.subdivision);
}

/// Parse a string into a VerseRangeRef.
VerseRangeRef verseRangeRefFromStr(String ref, {BibleLanguageEnum? language}) {
  _ensureReferenceIsNotEmpty(ref);
  final normalizedLanguage = _bookLookup.normalizeLanguage(language);

  final match = _verseRangeRefPattern.firstMatch(ref);
  if (match == null) {
    throw ParseVerseRefError(
        code: 'pattern_mismatch',
        details: 'reference "$ref" does not match expected format');
  }

  final startChapter = _parseReferenceNumber(
    match.group(2)!,
    component: 'start chapter',
    maximum: maxReferenceChapterNumber,
  );
  final startVerse = _parseVerseToken(
    match.group(3)!,
    component: 'start verse',
  );
  final endVerse = _parseVerseToken(
    match.group(6)!,
    component: 'end verse',
  );

  final endChapterMatch = match.group(5);
  final endChapter = endChapterMatch != null
      ? _parseReferenceNumber(
          endChapterMatch,
          component: 'end chapter',
          maximum: maxReferenceChapterNumber,
        )
      : startChapter;

  final startBook =
      _bookLookup.parseBookName(match.group(1)!, normalizedLanguage);
  final endBookMatch = match.group(4);
  final endBook = endBookMatch != null
      ? _bookLookup.parseBookName(endBookMatch, normalizedLanguage)
      : startBook;

  final start = VerseRef(
    book: startBook,
    chapter: startChapter,
    verse: startVerse.verse,
    subdivision: startVerse.subdivision,
  );
  final end = VerseRef(
    book: endBook,
    chapter: endChapter,
    verse: endVerse.verse,
    subdivision: endVerse.subdivision,
  );
  if (endBook == startBook && start.compareTo(end) >= 0) {
    throw ParseVerseRefError(
        code: 'same_book_range_not_ascending',
        details:
            'end reference must come after start reference for same-book ranges');
  }

  if (start.compareTo(end) >= 0) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.crossBookRangeNotAscending,
      details: 'end reference must come after start reference',
    );
  }

  return VerseRangeRef.checked(start: start, end: end);
}

/// Parse a Bible reference string into either a VerseRef or VerseRangeRef.
///
/// @deprecated Use [Reference.parse] instead for a more ergonomic API.
@Deprecated('Use Reference.parse instead')
Reference parseReference(String ref, {BibleLanguageEnum? language}) {
  return Reference.parse(ref, language: language);
}
