## Unreleased

### Added

- Conventional `package:bible_io_references/bible_io_references.dart` entrypoint
- Non-throwing `tryParse` and typed `ParseResult` APIs
- Typed parse error classifications while preserving legacy string codes
- Value equality, checked copying, comparison, and JSON round-tripping
- Localized long/short reference formatting and supported-language introspection
- Configurable `ReferenceParser` aliases, language priority, and ambiguity rejection
- Detected-language, selected-book, custom-alias, and alternate-match metadata
- Complete OSIS and USFM book/reference identifiers with reverse parsing
- Published CLI executable with language/text/JSON/OSIS/USFM output and a package example
- UTF-8 CLI batch processing from stdin or files with JSON Lines and exit codes
- Linux and Windows CI for formatting, analysis, and the full test suite

### Fixed

- Cross-book ranges are now recognized by `Reference.parse`
- Empty input has a dedicated `empty_reference` diagnostic
- Horizontal-bar range separators are supported
- Pathological chapter and verse numbers are rejected by broad sanity limits
- Previously undiscovered property, integration, concurrency, and benchmark tests now run by default
- Ambiguous two-character Arabic aliases no longer silently select different books

## 1.0.0

### 🎉 Initial Release

**Core Features:**
- Parse single verse references (`VerseRef`)
- Parse verse ranges (`VerseRangeRef`)
- Support for flexible formatting (colons, dots, various dash types)
- Multi-language support with intelligent auto-detection
- Comprehensive error handling with detailed diagnostics

**API Design:**
- Immutable, thread-safe data structures
- Sealed class hierarchy for type safety
- Static parsing methods on classes
- Backward-compatible legacy functions

**Languages Supported:**
- English (complete)
- Spanish (complete)
- French (complete)
- German (complete)
- Portuguese (complete)
- Russian (complete)
- Korean (complete)
- Chinese (complete)
- Hebrew (complete)
- Hindi (complete)
- Indonesian (complete)
- Tagalog (complete)

**Quality Assurance:**
- 2400+ comprehensive tests
- Property-based testing
- Performance benchmarks
- Language data quality validation
- Concurrent operation testing

**Performance:**
- Sub-millisecond parsing performance
- Zero external dependencies
- Memory efficient implementation
- Thread-safe operations
