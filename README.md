# bible-io-references-dart

A comprehensive Dart library for parsing Bible verse references into structured objects, supporting multiple languages and flexible formatting.

[![pub package](https://img.shields.io/pub/v/bible_io_references.svg)](https://pub.dev/packages/bible_io_references)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **Single verse parsing**: `John 3:16`, `jo 3:16` (abbreviations)
- ✅ **Verse range parsing**: `John 3:16-17`, `John 3:16-4:1`, `John 3:16-Acts 1:2`
- ✅ **Flexible formatting**: Supports `:`, `.` separators and various dash types (`-`, `–`, `—`)
- ✅ **Multi-language support**: English, Spanish, French, German, Hebrew, Hindi, Indonesian, Korean, Portuguese, Russian, Tagalog
- ✅ **Auto language detection**: Intelligently handles language precedence and collisions
- ✅ **Immutable data structures**: Thread-safe and performant
- ✅ **Comprehensive error handling**: Detailed error codes and diagnostics
- ✅ **Zero dependencies**: Pure Dart implementation

## Installation

```bash
dart pub add bible_io_references
```

## Quick Start

```dart
import 'package:bible_io_references/package.dart';

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
VerseRef verse = VerseRef.parse("John 3:16");
VerseRangeRef range = VerseRangeRef.parse("John 3:16-17");

// Flexible parsing (returns Reference union)
Reference any = Reference.parse("John 3:16"); // VerseRef
Reference any = Reference.parse("John 3:16-17"); // VerseRangeRef

// Legacy parsing functions (still available)
VerseRef verse = verseRefFromStr("John 3:16");
VerseRangeRef range = verseRangeRefFromStr("John 3:16-17");
```

### Language Support

```dart
// Auto language detection (default)
final ref = VerseRef.parse("Juan 3:16"); // Detects Spanish

// Explicit language specification
final ref = VerseRef.parse("Juan 3:16", language: BibleLanguageEnum.spanish);

// Language from string
final ref = VerseRef.parse("Juan 3:16", language: BibleLanguageEnum.fromStr("es"));
```

### Supported Languages

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
dart run bin/package.dart "John 3:16"
# Output: Parsed as single verse: John 3:16

dart run bin/package.dart "John 3:16-17"
# Output: Parsed as range: John 3:16-17
```

## Performance

- **Fast parsing**: < 1ms per reference on modern hardware
- **Memory efficient**: No external allocations during parsing
- **Thread safe**: All parsing operations are stateless
- **Zero-copy**: String processing without unnecessary copying

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
