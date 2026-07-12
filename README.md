# bible-io-references-dart

A comprehensive Dart library for parsing Bible verse references into structured objects, supporting multiple languages and flexible formatting.

[![pub package](https://img.shields.io/pub/v/bible_io_references.svg)](https://pub.dev/packages/bible_io_references)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Features

- ✅ **Single verse parsing**: `John 3:16`, `jo 3:16` (abbreviations)
- ✅ **Verse range parsing**: `John 3:16-17`, `John 3:16-4:1`, `John 3:16-Acts 1:2`
- ✅ **Flexible formatting**: Supports `:`, `.` separators and various dash types (`-`, `–`, `—`)
- ✅ **Multi-language support**: English plus 12 localized language packs
- ✅ **Auto language detection**: Intelligently handles language precedence and collisions
- ✅ **Immutable value objects**: Equality, stable hashes, and checked copies
- ✅ **Comprehensive error handling**: Detailed error codes and diagnostics
- ✅ **Non-throwing parsing**: Nullable and typed-result APIs for user input
- ✅ **Localized formatting**: Long or abbreviated book names in supported languages
- ✅ **Value semantics and JSON**: Equality, checked copies, and serialization
- ✅ **Configurable parsing**: Custom aliases, language priority, and ambiguity policy
- ✅ **Parse metadata**: Detected languages, selected matches, and alternatives
- ✅ **Rich passage grammar**: Whole books, chapters, verse lists, sequences, and single-chapter shorthand
- ✅ **Unicode-aware input**: Fullwidth forms, Arabic-Indic digits, RTL punctuation, and CJK adjacency
- ✅ **Reference extraction**: Find and safely linkify passages embedded in arbitrary prose
- ✅ **Interoperability**: OSIS and USFM identifiers for every supported book
- ✅ **Batch CLI**: UTF-8 stdin/files, JSON Lines, and meaningful exit codes
- ✅ **Zero dependencies**: Pure Dart implementation

## Installation

```bash
dart pub add bible_io_references
```

## Quick Start

```dart
import 'package:bible_io_references/bible_io_references.dart';

void main() {
  // Parse a single verse
  final verse = VerseRef.parse("John 3:16");
  print(verse.displayString); // "John 3:16"
  print("${verse.book.fullName} ${verse.chapter}:${verse.verse}");

  // Parse a verse range
  final range = VerseRangeRef.parse("John 3:16-4:1");
  print(range.displayString); // "John 3:16-4:1"

  // Parse any reference type
  final reference = Reference.parse("John 3:16-17");
  if (reference is VerseRef) {
    print("Single verse: ${reference.displayString}");
  } else if (reference is VerseRangeRef) {
    print("Range: ${reference.displayString}");
  }
}
```

## API Overview

### Core Classes

- **`Reference`**: Sealed class representing either a verse or range
- **`VerseRef`**: Single verse reference (book, chapter, verse)
- **`VerseRangeRef`**: Verse range reference (start and end VerseRef)
- **`BibleBookEnum`**: Enumeration of all Bible books with names and abbreviations
- **`BibleLanguageEnum`**: Supported languages for parsing
- **`ReferenceParser`**: Reusable parser with aliases and ambiguity configuration
- **`Passage`**: Sealed value type for books, chapters, verse selections, and sequences
- **`PassageParser`**: Reusable rich-grammar parser built on `ReferenceParser`
- **`ReferenceInputNormalizer`**: Syntax-oriented Unicode normalization with UTF-16 source mapping
- **`ReferenceExtractor`**: Parser-driven extraction and span-safe replacement/linkification
- **`ParseResult<T>`**: Non-throwing success/failure result with parse metadata

### Parsing Methods

```dart
// Direct parsing to specific types
final verse = VerseRef.parse("John 3:16");
final range = VerseRangeRef.parse("John 3:16-17");

// Flexible parsing (returns Reference union)
final single = Reference.parse("John 3:16"); // VerseRef
final passage = Reference.parse("John 3:16-17"); // VerseRangeRef

// Non-throwing alternatives
const userInput = "John 3:16";
final optional = Reference.tryParse(userInput);
final result = Reference.parseResult(userInput);

// Legacy parsing functions (still available)
final legacyVerse = verseRefFromStr("John 3:16");
final legacyRange = verseRangeRefFromStr("John 3:16-17");
```

### Rich Passage Grammar

Use `Passage.parse` when an expression can be broader than one verse or one
contiguous verse range. `Reference.parse` intentionally remains the narrower
verse/range API.

```dart
final book = Passage.parse('John');
print(book); // John

final chapter = Passage.parse('John 3');
print(chapter); // John 3

final chapters = Passage.parse('John 3-4');
print(chapters); // John 3-4

final verses = Passage.parse('John 3:16,18-20,4:1');
print(verses); // John 3:16,18-20,4:1

final sequence = Passage.parse('John 3:16; Acts 2:1-4; Romans 8');
print(sequence); // John 3:16; Acts 2:1-4; Romans 8

// Standard single-chapter books interpret a bare number as a verse.
final jude = Passage.parse('Jude 3');
print(jude); // Jude 1:3

final result = Passage.parseResult('John 3:16,18-20');
print(result.valueOrNull);
print(result.metadataOrNull?.detectedLanguage);

print(verses.format(language: BibleLanguageEnum.spanish));
// Juan 3:16,18-20,4:1
print(verses.osisIdentifier); // John.3.16 John.3.18-John.3.20 John.4.1
print(verses.usfmIdentifier); // JHN 3:16,18-20,JHN 4:1
```

The built-in single-chapter set is Obadiah, Philemon, 2 John, 3 John, and
Jude. It can be replaced for a parser instance:

```dart
final parser = PassageParser(
  referenceParser: ReferenceParser(
    aliases: {'favorite': BibleBookEnum.john},
  ),
  singleChapterBooks: {BibleBookEnum.jude},
);

print(parser.parse('favorite 3:16,18')); // John 3:16,18
```

All passage variants have value equality, immutable collections, `toJson`,
and `Passage.fromJson` support.

### Unicode Input Normalization

Reference and passage parsing normalize common reference-syntax variants,
including fullwidth ASCII, Arabic-Indic and Eastern Arabic/Persian digits,
Unicode spaces, dash/comma/semicolon/colon variants, combining marks, and
directional controls. CJK book names may be adjacent to their chapter number.

```dart
final passage = Passage.parse('John \u0663\uff1a\u0661\u0666');
print(passage); // John 3:16

final normalization = ReferenceInputNormalizer.normalizeDetailed(
  '\u200fJohn \u0663\uff1a\u0661\u0666',
);
print(normalization.normalizedText); // John 3:16

final originalSpan = normalization.mapNormalizedSpan(
  0,
  normalization.normalizedLength,
);
print(originalSpan.start); // UTF-16 offset in the original input
print(normalization.originalTextFor(0, normalization.normalizedLength));
```

This normalizer is deliberately reference-syntax-oriented, not a general
Unicode normalization or transliteration library. It preserves letter case
and whitespace runs.

### Extracting and Linkifying References

`ReferenceExtractor` finds the longest deterministic, non-overlapping passage
matches in prose. Every match retains the parsed `Passage`, parse metadata,
exact source substring, and original UTF-16 offsets.

```dart
const text = 'Study John 3:16,18-20; Acts 2:1-4 today.';
final extractor = ReferenceExtractor();
final matches = extractor.extract(text);

for (final match in matches) {
  print(match.passage);
  print('${match.start}-${match.end}: ${match.sourceText}');
}

final markdown = extractor.linkifyMarkdown(
  text,
  uriBuilder: (match) => Uri.https(
    'example.test',
    '/passage',
    {'q': match.passage.displayString},
  ),
);
```

`replaceMatches` and `linkify` apply callbacks in one pass; reference-looking
text returned by a callback is never scanned again. Bare-book extraction is
off by default and can be enabled with
`ReferenceExtractor(includeBareBooks: true)`.

### Language Support

```dart
// Auto language detection (default)
final detected = VerseRef.parse("Juan 3:16"); // Detects Spanish

// Explicit language specification
final spanish = VerseRef.parse(
  "Juan 3:16",
  language: BibleLanguageEnum.spanish,
);

// Language from string
final fromCode = VerseRef.parse(
  "Juan 3:16",
  language: BibleLanguageEnum.fromStr("es"),
);
```

### Configurable Parsing and Detection Metadata

```dart
final parser = ReferenceParser(
  aliases: {'jn': BibleBookEnum.john},
  preferredLanguages: [BibleLanguageEnum.spanish],
  ambiguityPolicy: ReferenceAmbiguityPolicy.reject,
);

final result = parser.parseResult('jn 3:16');
if (result case ParseSuccess(value: final reference, metadata: final metadata)) {
  print(reference);                         // John 3:16
  print(metadata.detectedLanguage);         // null: custom global alias
  print(metadata.alternateMatches.length);  // bundled matches remain visible
}

final detected = Reference.parseResult('Juan 3:16');
print(detected.metadataOrNull?.detectedLanguage); // Spanish
```

### Localized Formatting

```dart
final ref = Reference.parse('Juan 3:16', language: BibleLanguageEnum.spanish);

print(ref.format(language: BibleLanguageEnum.spanish));
// Juan 3:16

print(ref.format(
  language: BibleLanguageEnum.spanish,
  bookNameStyle: ReferenceBookNameStyle.short,
));
// Jn 3:16

print(BibleLanguageEnum.spanish.isParsingSupported); // true
print(BibleLanguageEnum.greek.isParsingSupported);   // false
```

### Value Objects and JSON

```dart
final verse = VerseRef.parse('John 3:16');
final nextVerse = verse.copyWith(verse: 17);

final json = nextVerse.toJson();
final restored = Reference.fromJson(json);
print(restored == nextVerse); // true
```

### OSIS and USFM Identifiers

```dart
final verse = Reference.parse('John 3:16');
print(verse.osisIdentifier); // John.3.16
print(verse.usfmIdentifier); // JHN 3:16

final range = referenceFromOsisIdentifier('2Cor.6.14-2Cor.7.1');
print(range); // 2 Corinthians 6:14-7:1

print(BibleBookEnum.john.osisIdentifier); // John
print(BibleBookEnum.john.usfmIdentifier); // JHN
```

OSIS ranges use complete dotted endpoints. USFM identifiers use the official
three-character book codes; `ADE` is retained as a documented
Paratext-compatible extension for separately modeled Esther additions.
Mappings follow the [CrossWire OSIS book vocabulary](https://wiki.crosswire.org/OSIS_Book_Abbreviations)
and the [official USFM book identifier table](https://ubsicap.github.io/usfm/usfm3.0/identification/books.html).

### Supported Languages

- **Arabic** (ar) - Complete support
- **English** (en) - Complete support
- **Spanish** (es) - Complete support
- **French** (fr) - Complete support
- **German** (de) - Complete support
- **Portuguese** (pt) - Complete support
- **Russian** (ru) - Complete support
- **Korean** (ko) - Complete support
- **Chinese** (zh) - Complete support
- **Hebrew** (he) - Complete support
- **Hindi** (hi) - Complete support
- **Indonesian** (id) - Complete support
- **Tagalog** (tl) - Complete support

Use `language.isParsingSupported` or `supportedParsingLanguages` before
offering a language in user-facing controls. Some enum identifiers are reserved
for future language packs but do not yet have parsing data.

## Advanced Usage

### Error Handling

```dart
try {
  final ref = VerseRef.parse("InvalidBook 3:16");
} on ParseVerseRefError catch (e) {
  print("Error code: ${e.code}");      // "unknown_book"
  print("Details: ${e.details}");      // "book token 'InvalidBook' did not match known books"
}
```

### Working with Book Enums

```dart
// Get all books
for (final book in BibleBookEnum.values) {
  print("${book.fullName} (${book.asStr()})");
}

// Parse from abbreviation
final book = BibleBookEnum.fromStr("jn"); // BibleBookEnum.jonah
```

### Auto Language Collisions

The library handles ambiguous abbreviations intelligently:

```dart
// "jn" could be Jonah or John - auto mode prefers Jonah due to precedence
final jonahRef = VerseRef.parse("jn 1:1");
print(jonahRef.book); // BibleBookEnum.jonah

// "jud" prefers Judges over Jude
final judgesRef = VerseRef.parse("jud 1:1");
print(judgesRef.book); // BibleBookEnum.judges
```

### Current Limitations

- Chapter and verse numbers receive broad sanity checks only. The package does
  not apply edition-specific chapter or verse tables.
- Canon membership is not enforced; book availability and numbering vary by
  Bible tradition and edition.
- Rich passage lists use commas and passage sequences use semicolons; prose
  words such as “and” are not grammar separators.
- Unicode normalization targets reference syntax. It does not transliterate
  book names, perform locale-sensitive case folding, or provide general-purpose
  Unicode normalization.
- Extraction is bounded by configurable look-behind/look-ahead windows
  (96/256 UTF-16 code units by default). Bare books are opt-in, and auto mode
  suppresses several very short/common aliases to avoid prose false positives;
  pass an explicit `language:` to extraction when those aliases are intentional.

## Command Line Usage

```bash
# Parse a verse, range, or richer passage from the command line
dart run bible_io_references "John 3:16"
# Output: John 3:16

dart run bible_io_references "John 3:16,18-20; Acts 2"
# Output: John 3:16,18-20; Acts 2

dart run bible_io_references --language es "Juan 3:16"
# Output: Juan 3:16

dart run bible_io_references --format json "John 3:16"
# Output: {"type":"verse","book":"jo","chapter":3,"verse":16}

dart run bible_io_references --format osis "John 3:16-17"
# Output: John.3.16-John.3.17

dart run bible_io_references --format usfm "John 3:16-17"
# Output: JHN 3:16-17

# UTF-8 batch input, one passage per nonblank line
dart run bible_io_references --input references.txt --format json

# Or read a batch from stdin
dart run bible_io_references --batch --format usfm
```

Existing verse/range JSON remains unchanged. Rich single-input JSON uses the
`book`, `chapter`, `verses`, or `sequence` passage shape; batch success records
contain `reference` for the narrow legacy shapes and `passage` for rich shapes.
Batch JSON uses JSON Lines and includes a record for every success or failure.
Exit codes are `0` for success, `64` for usage errors, `65` when parsing fails,
and `66` when input cannot be read or decoded.

## Performance

- **Fast parsing**: Cached book lookups keep repeated parsing inexpensive
- **Stateless API**: Parse operations do not mutate shared parser state
- **Small footprint**: No runtime package dependencies
- **Benchmarked**: Performance checks are isolated behind the `performance` tag

## Testing

The package includes comprehensive test coverage:

```bash
# Run all tests
dart test

# Run with coverage
dart test --coverage=coverage

# Run specific test groups
dart test --tags performance
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

GNU Affero General Public License v3.0 - see [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
