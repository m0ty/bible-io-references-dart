# Test Suite Documentation

This document describes the comprehensive test suite for the `bible_io_references` package.

## Test Structure

### `test/package_test.dart`
**Core functionality tests**
- Basic parsing (verse references, ranges, separators)
- Auto language detection and precedence
- Error handling and validation
- All Bible books parsing
- Immutability verification
- `Reference.parse()` API testing

### `test/non_english/`
**Language-specific parsing tests**
- Individual test files for each supported language
- Tests parsing with native book names and abbreviations
- Cross-language collision handling
- Unicode character support

### `test/property/`
**Property-based and quality assurance tests**
- `property_tests.dart`: Edge cases, boundary conditions, round-trip parsing
- `language_audit_tests.dart`: Language data quality validation

### `test/integration/`
**Integration and system-level tests**
- `integration_tests.dart`: Complex multi-language scenarios, error propagation
- `concurrent_tests.dart`: Thread safety and concurrent parsing

### `test/benchmarks/`
**Performance testing**
- `benchmark_tests.dart`: Parsing speed, memory efficiency, lookup performance

## Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/property/property_tests.dart

# Run with coverage (if available)
dart test --coverage=coverage

# Run benchmarks only
dart test test/benchmarks/
```

## Test Categories

### Unit Tests
- Individual function/method testing
- Error condition validation
- Data structure immutability

### Integration Tests
- Multi-component interaction
- Language data consistency
- Concurrent operation safety

### Property Tests
- Edge case exploration
- Data quality validation
- Round-trip correctness

### Performance Tests
- Parsing speed benchmarks
- Memory usage validation
- Scalability testing

## Adding New Tests

### For New Features
1. Add unit tests in `package_test.dart` for basic functionality
2. Add integration tests if the feature interacts with multiple components
3. Add property tests for edge cases and validation
4. Add performance tests if the feature could impact speed

### For New Languages
1. Create `test/non_english/{language}_test.dart`
2. Test parsing with native book names and abbreviations
3. Verify auto language detection works correctly
4. Update language audit tests if needed

### For Bug Fixes
1. Add a regression test that reproduces the bug
2. Verify the test fails before the fix
3. Ensure the test passes after the fix

## Test Quality Guidelines

- **Descriptive test names**: Tests should clearly describe what they're testing
- **Single responsibility**: Each test should verify one specific behavior
- **Arrange-Act-Assert**: Structure tests clearly
- **Edge cases**: Test boundary conditions and error states
- **Performance**: Include timing assertions where relevant
- **Concurrency**: Test thread safety for shared resources

## Coverage Goals

- **Statement coverage**: >95%
- **Branch coverage**: >90%
- **Function coverage**: 100%
- **Error path coverage**: All error conditions tested

## Continuous Integration

Tests are designed to run in CI environments with:
- Fast execution (< 30 seconds for full suite)
- No external dependencies
- Deterministic results
- Clear failure reporting