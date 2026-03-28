import 'package:bible_io_references/package.dart';
import 'package:test/test.dart';

/// Represents a quality issue found in language term data
class LanguageTermIssue {
  final String languageCode;
  final String issueType;
  final String description;
  final BibleBookEnum? book;
  final String? term;

  LanguageTermIssue({
    required this.languageCode,
    required this.issueType,
    required this.description,
    this.book,
    this.term,
  });

  @override
  String toString() => '$languageCode: $issueType - $description';
}

/// Audits language term data for quality issues
class LanguageTermAuditReport {
  final List<LanguageTermIssue> issues;

  LanguageTermAuditReport(this.issues);

  bool get hasIssues => issues.isNotEmpty;

  List<LanguageTermIssue> get blockingIssues =>
      issues.where((issue) => _isBlockingIssue(issue)).toList();

  bool get hasBlockingIssues => blockingIssues.isNotEmpty;

  static bool _isBlockingIssue(LanguageTermIssue issue) {
    return issue.issueType == 'missing_name' ||
           issue.issueType == 'missing_abbreviation' ||
           issue.issueType == 'collision';
  }
}

LanguageTermAuditReport auditLanguageTerms() {
  final issues = <LanguageTermIssue>[];

  // Check that all books have names and abbreviations for each language
  for (final languageCode in bookNamesByLanguage.keys) {
    final names = bookNamesByLanguage[languageCode]!;
    final abbreviations = bookAbbreviationsByLanguage[languageCode]!;

    for (final book in BibleBookEnum.values) {
      if (!names.containsKey(book)) {
        issues.add(LanguageTermIssue(
          languageCode: languageCode,
          issueType: 'missing_name',
          description: 'Missing name for ${book.fullName}',
          book: book,
        ));
      }

      if (!abbreviations.containsKey(book)) {
        issues.add(LanguageTermIssue(
          languageCode: languageCode,
          issueType: 'missing_abbreviation',
          description: 'Missing abbreviation for ${book.fullName}',
          book: book,
        ));
      }
    }
  }

  // Check for duplicate terms within the same language
  for (final languageCode in bookNamesByLanguage.keys) {
    final names = bookNamesByLanguage[languageCode]!;
    final abbreviations = bookAbbreviationsByLanguage[languageCode]!;

    _checkForDuplicates(issues, languageCode, 'names', names);
    _checkForDuplicates(issues, languageCode, 'abbreviations', abbreviations);
  }

  // Check for whitespace issues
  for (final languageCode in bookNamesByLanguage.keys) {
    final names = bookNamesByLanguage[languageCode]!;
    final abbreviations = bookAbbreviationsByLanguage[languageCode]!;

    _checkWhitespaceIssues(issues, languageCode, 'names', names);
    _checkWhitespaceIssues(issues, languageCode, 'abbreviations', abbreviations);
  }

  // Check for potential collisions in normalized forms
  _checkNormalizationCollisions(issues);

  return LanguageTermAuditReport(issues);
}

void _checkForDuplicates(
  List<LanguageTermIssue> issues,
  String languageCode,
  String sourceType,
  Map<BibleBookEnum, List<String>> terms,
) {
  final seenTerms = <String, BibleBookEnum>{};

  for (final entry in terms. entries) {
    final book = entry.key;
    for (final term in entry.value) {
      final normalized = term.toLowerCase().trim();
      if (seenTerms.containsKey(normalized)) {
        issues.add(LanguageTermIssue(
          languageCode: languageCode,
          issueType: 'duplicate_term',
          description: 'Duplicate term "$term" for ${book.fullName} and ${seenTerms[normalized]!.fullName}',
          book: book,
          term: term,
        ));
      } else {
        seenTerms[normalized] = book;
      }
    }
  }
}

void _checkWhitespaceIssues(
  List<LanguageTermIssue> issues,
  String languageCode,
  String sourceType,
  Map<BibleBookEnum, List<String>> terms,
) {
  for (final entry in terms.entries) {
    final book = entry.key;
    for (final term in entry.value) {
      if (term.trim() != term) {
        issues.add(LanguageTermIssue(
          languageCode: languageCode,
          issueType: 'whitespace_issue',
          description: 'Term "$term" has leading/trailing whitespace',
          book: book,
          term: term,
        ));
      }

      if (term.contains('  ')) {
        issues.add(LanguageTermIssue(
          languageCode: languageCode,
          issueType: 'whitespace_issue',
          description: 'Term "$term" has multiple consecutive spaces',
          book: book,
          term: term,
        ));
      }
    }
  }
}

void _checkNormalizationCollisions(List<LanguageTermIssue> issues) {
  // This is a simplified check - in practice you'd want to check the actual
  // normalization logic used in _BookTermLookup
  final normalizedTerms = <String, List<String>>{};

  for (final languageCode in bookNamesByLanguage.keys) {
    final names = bookNamesByLanguage[languageCode]!;
    final abbreviations = bookAbbreviationsByLanguage[languageCode]!;

    for (final entry in names.entries) {
      for (final term in entry.value) {
        final normalized = term.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
        normalizedTerms.putIfAbsent(normalized, () => []).add('$languageCode:names:${entry.key.fullName}');
      }
    }

    for (final entry in abbreviations.entries) {
      for (final term in entry.value) {
        final normalized = term.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
        normalizedTerms.putIfAbsent(normalized, () => []).add('$languageCode:abbreviations:${entry.key.fullName}');
      }
    }
  }

  for (final entry in normalizedTerms.entries) {
    if (entry.value.length > 1) {
      issues.add(LanguageTermIssue(
        languageCode: 'multiple',
        issueType: 'normalization_collision',
        description: 'Normalized term "${entry.key}" collides between: ${entry.value.join(', ')}',
        term: entry.key,
      ));
    }
  }
}

void main() {
  group('Language term audit tests', () {
    test('language term data has no blocking quality issues', () {
      final report = auditLanguageTerms();

      if (report.hasBlockingIssues) {
        for (final issue in report.blockingIssues) {
          print('BLOCKING ISSUE: $issue');
        }
      }

      expect(report.hasBlockingIssues, isFalse,
          reason: 'Found ${report.blockingIssues.length} blocking issues in language term data');
    });

    test('language term data has no duplicate terms within languages', () {
      final report = auditLanguageTerms();
      final duplicateIssues = report.issues.where((issue) => issue.issueType == 'duplicate_term');

      if (duplicateIssues.isNotEmpty) {
        for (final issue in duplicateIssues) {
          print('DUPLICATE: $issue');
        }
      }

      expect(duplicateIssues.length, 0,
          reason: 'Found ${duplicateIssues.length} duplicate terms in language data');
    });

    test('language term data has no whitespace issues', () {
      final report = auditLanguageTerms();
      final whitespaceIssues = report.issues.where((issue) => issue.issueType == 'whitespace_issue');

      if (whitespaceIssues.isNotEmpty) {
        for (final issue in whitespaceIssues) {
          print('WHITESPACE: $issue');
        }
      }

      expect(whitespaceIssues.length, 0,
          reason: 'Found ${whitespaceIssues.length} whitespace issues in language data');
    });

    test('all languages have complete book coverage', () {
      for (final languageCode in bookNamesByLanguage.keys) {
        final names = bookNamesByLanguage[languageCode]!;
        final abbreviations = bookAbbreviationsByLanguage[languageCode]!;

        for (final book in BibleBookEnum.values) {
          expect(names.containsKey(book), isTrue,
              reason: 'Language $languageCode missing name for ${book.fullName}');
          expect(abbreviations.containsKey(book), isTrue,
              reason: 'Language $languageCode missing abbreviation for ${book.fullName}');
        }
      }
    });

    test('auto language collisions are properly documented', () {
      // Test that the auto language collision data is consistent
      expect(autoLanguageCollisions, isNotEmpty);

      for (final term in autoLanguageCollisions.keys) {
        expect(autoLanguageCollisions[term]!.length, greaterThan(1),
            reason: 'Collision term "$term" should have multiple books');
      }
    });
  });
}