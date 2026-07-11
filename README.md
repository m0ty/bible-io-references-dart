# bible-io-references-dart

A comprehensive Dart library for parsing Bible verse references into structured objects, supporting multiple languages and flexible formatting.

[![pub package](https://img.shields.io/pub/v/bible_io_references.svg)](https://pub.dev/packages/bible_io_references)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

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

## Command Line Usage

```bash
# Parse a reference from command line
dart run bible_io_references "John 3:16"
# Output: John 3:16

dart run bible_io_references "John 3:16-17"
# Output: John 3:16-17

dart run bible_io_references --language es "Juan 3:16"
# Output: Juan 3:16

dart run bible_io_references --format json "John 3:16"
# Output: {"type":"verse","book":"jo","chapter":3,"verse":16}

dart run bible_io_references --format osis "John 3:16-17"
# Output: John.3.16-John.3.17

dart run bible_io_references --format usfm "John 3:16-17"
# Output: JHN 3:16-17

# UTF-8 batch input, one reference per nonblank line
dart run bible_io_references --input references.txt --format json

# Or read a batch from stdin
dart run bible_io_references --batch --format usfm
```

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

MIT License - see [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
