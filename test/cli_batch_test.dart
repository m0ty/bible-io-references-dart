import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/bible_io_references.dart' as cli;

void main() {
  group('CLI batch input', () {
    test('reads stdin in order and ignores blank lines', () async {
      final output = StringBuffer();
      final errors = StringBuffer();

      final exitCode = await cli.runCli(
        ['--batch'],
        standardInput: _input('John 3:16\n\nActs 2:1-4\n'),
        standardOutput: output,
        standardError: errors,
      );

      expect(exitCode, 0);
      expect(output.toString(), 'John 3:16\nActs 2:1-4\n');
      expect(errors.toString(), isEmpty);
    });

    test('continues after text failures and returns a data error', () async {
      final output = StringBuffer();
      final errors = StringBuffer();

      final exitCode = await cli.runCli(
        ['--batch'],
        standardInput: _input('John 3:16\nNotABook 1:1\nActs 2:1\n'),
        standardOutput: output,
        standardError: errors,
      );

      expect(exitCode, 65);
      expect(output.toString(), 'John 3:16\nActs 2:1\n');
      expect(errors.toString(), contains('Line 2: Unable to parse'));
      expect(errors.toString(), contains('(unknown_book)'));
    });

    test('emits one JSON object for every nonblank record', () async {
      final output = StringBuffer();
      final errors = StringBuffer();

      final exitCode = await cli.runCli(
        ['--batch', '--format', 'json'],
        standardInput: _input('John 3:16\n\nNotABook 1:1\nActs 2:1\n'),
        standardOutput: output,
        standardError: errors,
      );
      final records = const LineSplitter()
          .convert(output.toString())
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();

      expect(exitCode, 65);
      expect(errors.toString(), isEmpty);
      expect(records, hasLength(3));
      expect(records[0]['line'], 1);
      expect(records[0]['ok'], isTrue);
      expect(records[0]['reference'], {
        'type': 'verse',
        'book': 'jo',
        'chapter': 3,
        'verse': 16,
      });
      expect(records[1]['line'], 3);
      expect(records[1]['ok'], isFalse);
      expect(
        (records[1]['error'] as Map<String, dynamic>)['code'],
        'unknown_book',
      );
      expect(records[2]['line'], 4);
      expect(records[2]['ok'], isTrue);
    });

    test('reads --input through the provided UTF-8 file source', () async {
      final output = StringBuffer();
      String? openedPath;

      final exitCode = await cli.runCli(
        ['--input', 'references.txt', '--language', 'es'],
        standardOutput: output,
        standardError: StringBuffer(),
        openInputFile: (path) {
          openedPath = path;
          return _input('Juan 3:16\n');
        },
      );

      expect(exitCode, 0);
      expect(openedPath, 'references.txt');
      expect(output.toString(), 'Juan 3:16\n');
    });

    test('returns no-input for unreadable files', () async {
      final errors = StringBuffer();

      final exitCode = await cli.runCli(
        ['--input=missing.txt'],
        standardOutput: StringBuffer(),
        standardError: errors,
        openInputFile: (_) => Stream<List<int>>.error(
          const FileSystemException('File not found'),
        ),
      );

      expect(exitCode, 66);
      expect(errors.toString(), contains('Unable to read "missing.txt"'));
      expect(errors.toString(), contains('File not found'));
    });

    test('returns no-input for malformed UTF-8', () async {
      final errors = StringBuffer();

      final exitCode = await cli.runCli(
        ['--batch'],
        standardInput: Stream<List<int>>.value([0xc3, 0x28]),
        standardOutput: StringBuffer(),
        standardError: errors,
      );

      expect(exitCode, 66);
      expect(errors.toString(), contains('input is not valid UTF-8'));
    });

    test('rejects mixed batch sources and positional input', () async {
      final mixedSourcesError = StringBuffer();
      final mixedSourcesCode = await cli.runCli(
        ['--batch', '--input', 'references.txt'],
        standardOutput: StringBuffer(),
        standardError: mixedSourcesError,
      );
      final positionalError = StringBuffer();
      final positionalCode = await cli.runCli(
        ['--batch', 'John 3:16'],
        standardOutput: StringBuffer(),
        standardError: positionalError,
      );

      expect(mixedSourcesCode, 64);
      expect(
        mixedSourcesError.toString(),
        contains('--batch and --input cannot be used together'),
      );
      expect(positionalCode, 64);
      expect(
        positionalError.toString(),
        contains('cannot be combined with batch input'),
      );
    });
  });

  test('single-reference JSON behavior remains unchanged', () async {
    final output = StringBuffer();

    final exitCode = await cli.runCli(
      ['--format=json', 'John', '3:16'],
      standardOutput: output,
      standardError: StringBuffer(),
    );

    expect(exitCode, 0);
    expect(jsonDecode(output.toString()), {
      'type': 'verse',
      'book': 'jo',
      'chapter': 3,
      'verse': 16,
    });
  });

  test('single-reference JSON errors remain machine-readable', () async {
    final output = StringBuffer();
    final errors = StringBuffer();

    final exitCode = await cli.runCli(
      ['--format=json', 'NotABook 1:1'],
      standardOutput: output,
      standardError: errors,
    );
    final record = jsonDecode(output.toString()) as Map<String, dynamic>;

    expect(exitCode, 65);
    expect(errors.toString(), isEmpty);
    expect(record['ok'], isFalse);
    expect(record['input'], 'NotABook 1:1');
    expect(
      (record['error'] as Map<String, dynamic>)['code'],
      'unknown_book',
    );
  });

  test('renders OSIS and USFM in single and batch modes', () async {
    final osisOutput = StringBuffer();
    final osisCode = await cli.runCli(
      ['--format=osis', 'John 3:16-4:1'],
      standardOutput: osisOutput,
      standardError: StringBuffer(),
    );
    final usfmOutput = StringBuffer();
    final usfmCode = await cli.runCli(
      ['--batch', '--format=usfm'],
      standardInput: _input('John 3:16\nActs 2:1-4\n'),
      standardOutput: usfmOutput,
      standardError: StringBuffer(),
    );

    expect(osisCode, 0);
    expect(osisOutput.toString(), 'John.3.16-John.4.1\n');
    expect(usfmCode, 0);
    expect(usfmOutput.toString(), 'JHN 3:16\nACT 2:1-4\n');
  });

  group('rich passage expressions', () {
    test('renders whole books, chapters, lists, and sequences', () async {
      final output = StringBuffer();

      final exitCode = await cli.runCli(
        ['John 3:16,18-20; Acts 2'],
        standardOutput: output,
        standardError: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(output.toString(), 'John 3:16,18-20; Acts 2\n');
    });

    test('serializes rich single and batch JSON without changing verse JSON',
        () async {
      final singleOutput = StringBuffer();
      final singleCode = await cli.runCli(
        ['--format=json', 'John 3'],
        standardOutput: singleOutput,
        standardError: StringBuffer(),
      );
      final batchOutput = StringBuffer();
      final batchCode = await cli.runCli(
        ['--batch', '--format=json'],
        standardInput: _input('John\nJohn 3:16,18\n'),
        standardOutput: batchOutput,
        standardError: StringBuffer(),
      );
      final batchRecords = const LineSplitter()
          .convert(batchOutput.toString())
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();

      expect(singleCode, 0);
      expect(jsonDecode(singleOutput.toString()), {
        'type': 'chapter',
        'book': 'jo',
        'startChapter': 3,
        'endChapter': null,
      });
      expect(batchCode, 0);
      expect(batchRecords[0]['passage'], {
        'type': 'book',
        'book': 'jo',
      });
      expect(
        (batchRecords[1]['passage'] as Map<String, dynamic>)['type'],
        'verses',
      );
    });

    test('renders passage OSIS and compact USFM identifiers', () async {
      final osisOutput = StringBuffer();
      final osisCode = await cli.runCli(
        ['--format=osis', 'John 3:16,18-20'],
        standardOutput: osisOutput,
        standardError: StringBuffer(),
      );
      final usfmOutput = StringBuffer();
      final usfmCode = await cli.runCli(
        ['--format=usfm', 'John 3:16,18-20'],
        standardOutput: usfmOutput,
        standardError: StringBuffer(),
      );

      expect(osisCode, 0);
      expect(osisOutput.toString(), 'John.3.16 John.3.18-John.3.20\n');
      expect(usfmCode, 0);
      expect(usfmOutput.toString(), 'JHN 3:16,18-20\n');
    });
  });

  group('canon and versification options', () {
    test('keeps validation disabled by default', () async {
      final output = StringBuffer();

      final exitCode = await cli.runCli(
        ['John 3:99'],
        standardOutput: output,
        standardError: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(output.toString(), 'John 3:99\n');
    });

    test('KJV versification reports typed coordinate errors', () async {
      final output = StringBuffer();

      final exitCode = await cli.runCli(
        ['--versification=kjv', '--format=json', 'John 3:37'],
        standardOutput: output,
        standardError: StringBuffer(),
      );
      final record = jsonDecode(output.toString()) as Map<String, dynamic>;

      expect(exitCode, 65);
      expect(
        (record['error'] as Map<String, dynamic>)['code'],
        'verse_out_of_range',
      );
    });

    test('canon-only validation supports Catholic ordering', () async {
      final output = StringBuffer();

      final exitCode = await cli.runCli(
        ['--canon', 'catholic', 'Tobit 1:1-Matthew 1:1'],
        standardOutput: output,
        standardError: StringBuffer(),
      );

      expect(exitCode, 0);
      expect(output.toString(), 'Tobit 1:1-Matthew 1:1\n');
    });

    test('rejects unknown and incompatible profile options', () async {
      final unknownErrors = StringBuffer();
      final unknownCode = await cli.runCli(
        ['--versification', 'unknown', 'John 3:16'],
        standardOutput: StringBuffer(),
        standardError: unknownErrors,
      );
      final incompatibleErrors = StringBuffer();
      final incompatibleCode = await cli.runCli(
        [
          '--canon=catholic',
          '--versification=kjv',
          'John 3:16',
        ],
        standardOutput: StringBuffer(),
        standardError: incompatibleErrors,
      );

      expect(unknownCode, 64);
      expect(unknownErrors.toString(), contains('Unsupported versification'));
      expect(incompatibleCode, 64);
      expect(
        incompatibleErrors.toString(),
        contains('same books and order'),
      );
    });
  });
}

Stream<List<int>> _input(String value) =>
    Stream<List<int>>.value(utf8.encode(value));
