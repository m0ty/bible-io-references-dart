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
final ref = VerseRef.parse("jn 1:1");
print(ref.book); // BibleBookEnum.jonah

// "jud" prefers Judges over Jude
final ref = VerseRef.parse("jud 1:1");
print(ref.book); // BibleBookEnum.judges
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
```

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
