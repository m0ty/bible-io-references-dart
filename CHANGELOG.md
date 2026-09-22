## 1.2.0 - 2026-09-22

### Added

- Optional `VerseRef.subdivision` and `verseLabel` for labels such as `5a`,
  including parsing, ordering, checked copies, and backward-compatible JSON
- Subdivision-aware ranges, passage lists, single-chapter shorthand, localized
  formatting, prose extraction, CLI output, and OSIS/USFM round trips
- `VerseLabel` to retain one source entry's exact combined or subdivided label,
  serialize it to JSON, and resolve it to a verse or range within a chapter
- Public import compatibility and subdivision regression tests

### Changed

- Organized the reference library into focused parts for models, parsers,
  metadata, alias lookup, legacy parsing, and shared validation

## 1.1.0 - 2026-07-12

### Added

- Conventional `package:bible_io_references/bible_io_references.dart` entrypoint
- Non-throwing `tryParse` and typed `ParseResult` APIs
- Typed parse error classifications while preserving legacy string codes
- Value equality, checked copying, comparison, and JSON round-tripping
- Localized long/short reference formatting and supported-language introspection
- Configurable `ReferenceParser` aliases, language priority, and ambiguity rejection
- Detected-language, selected-book, custom-alias, and alternate-match metadata
- Immutable `Passage` values and `PassageParser` support for whole books,
  chapters, chapter ranges, verse lists, semicolon-separated sequences, and
  configurable single-chapter shorthand
- Localized passage formatting plus OSIS and USFM serialization for every
  passage variant
- Reference-oriented Unicode normalization for compatibility punctuation,
  fullwidth forms, Arabic-Indic digits, combining/vocalization marks, RTL
  controls, Unicode spacing, and CJK book/chapter adjacency
- UTF-16 source-span mapping through `ReferenceInputNormalization`
- Parser-driven `ReferenceExtractor` matches with exact original offsets,
  one-pass replacement, generic linkification, and escaped Markdown links
- Complete OSIS and USFM book/reference identifiers with reverse parsing
- Published CLI executable with rich-passage language/text/JSON/OSIS/USFM
  output and a package example
- UTF-8 CLI batch processing from stdin or files with JSON Lines and exit codes
- Linux and Windows CI for formatting, analysis, and the full test suite

### Changed

- Reference validation remains edition-neutral: chapter and verse numbers use
  broad sanity limits, while canon membership and edition-specific numbering
  are intentionally not enforced

### Fixed

- Cross-book ranges are now recognized by `Reference.parse`
- Empty input has a dedicated `empty_reference` diagnostic
- Horizontal-bar range separators are supported
- Pathological chapter and verse numbers are rejected by broad sanity limits
- Previously undiscovered property, integration, concurrency, and benchmark tests now run by default
- Ambiguous two-character Arabic aliases no longer silently select different books
- README license badge and wording now match the repository's AGPL-3.0 license

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
