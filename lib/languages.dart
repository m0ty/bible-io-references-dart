// Language data for book names and abbreviations.

import 'bible_book_enum.dart';
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
final Map<String, Map<BibleBookEnum, List<String>>> bookNamesByLanguage = {
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
final Map<String, Map<BibleBookEnum, List<String>>> bookAbbreviationsByLanguage = {
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