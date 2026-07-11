// Language data for book names and abbreviations.

import 'bible_book_enum.dart';
import 'bible_language_enum.dart';
import 'languages/arabic.dart';
import 'languages/chinese.dart';
import 'languages/french.dart';
import 'languages/german.dart';
import 'languages/hebrew.dart';
import 'languages/hindi.dart';
import 'languages/indonesian.dart';
import 'languages/korean.dart';
import 'languages/portuguese.dart';
import 'languages/russian.dart';
import 'languages/spanish.dart';
import 'languages/tagalog.dart';

/// Book names by language code.
const Map<String, Map<BibleBookEnum, List<String>>> bookNamesByLanguage = {
  'ar': arabicBookNames,
  'zh': chineseBookNames,
  'he': hebrewBookNames,
  'hi': hindiBookNames,
  'id': indonesianBookNames,
  'ko': koreanBookNames,
  'tl': tagalogBookNames,
  'es': spanishBookNames,
  'fr': frenchBookNames,
  'de': germanBookNames,
  'ru': russianBookNames,
  'pt': portugueseBookNames,
};

/// Book abbreviations by language code.
const Map<String, Map<BibleBookEnum, List<String>>>
    bookAbbreviationsByLanguage = {
  'ar': arabicBookAbbreviations,
  'zh': chineseBookAbbreviations,
  'he': hebrewBookAbbreviations,
  'hi': hindiBookAbbreviations,
  'id': indonesianBookAbbreviations,
  'ko': koreanBookAbbreviations,
  'tl': tagalogBookAbbreviations,
  'es': spanishBookAbbreviations,
  'fr': frenchBookAbbreviations,
  'de': germanBookAbbreviations,
  'ru': russianBookAbbreviations,
  'pt': portugueseBookAbbreviations,
};

/// Languages accepted by the reference parser.
///
/// This set is derived from the registered language data, with [BibleLanguageEnum.english]
/// added because English names live on [BibleBookEnum], and
/// [BibleLanguageEnum.auto] added because it is a supported parser mode. The set
/// is unmodifiable and follows [BibleLanguageEnum.values] order.
final Set<BibleLanguageEnum> supportedParsingLanguages = Set.unmodifiable(
  BibleLanguageEnum.values.where(
    (language) =>
        language == BibleLanguageEnum.auto ||
        language == BibleLanguageEnum.english ||
        bookNamesByLanguage.containsKey(language.code) ||
        bookAbbreviationsByLanguage.containsKey(language.code),
  ),
);

/// Parsing-support information for a language identifier.
extension BibleLanguageParsingSupport on BibleLanguageEnum {
  /// Whether this language (or parser mode) has registered parsing support.
  bool get isParsingSupported => supportedParsingLanguages.contains(this);
}
