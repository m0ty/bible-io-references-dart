import 'dart:convert';
import 'dart:io';

import 'package:bible_io_references/bible_io_references.dart';

const _successExitCode = 0;
const _usageExitCode = 64;
const _dataErrorExitCode = 65;
const _noInputExitCode = 66;

Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments);
}

/// Runs the command-line interface and returns its process exit code.
///
/// The injectable streams make batch behavior testable without starting child
/// processes. Normal callers should use [main].
Future<int> runCli(
  List<String> arguments, {
  Stream<List<int>>? standardInput,
  StringSink? standardOutput,
  StringSink? standardError,
  Stream<List<int>> Function(String path)? openInputFile,
}) async {
  final output = standardOutput ?? stdout;
  final errors = standardError ?? stderr;

  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printUsage(output);
    return _successExitCode;
  }

  BibleLanguageEnum? language;
  var outputFormat = 'text';
  var batchFromStdin = false;
  String? inputPath;
  final inputParts = <String>[];

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--language' || argument == '-l') {
      if (index + 1 >= arguments.length) {
        return _usageError('Missing value for $argument.', errors);
      }
      try {
        language = BibleLanguageEnum.fromStr(arguments[++index]);
      } on ArgumentError catch (error) {
        return _usageError(
          error.message?.toString() ?? error.toString(),
          errors,
        );
      }
    } else if (argument.startsWith('--language=')) {
      try {
        language = BibleLanguageEnum.fromStr(argument.substring(11));
      } on ArgumentError catch (error) {
        return _usageError(
          error.message?.toString() ?? error.toString(),
          errors,
        );
      }
    } else if (argument == '--format' || argument == '-f') {
      if (index + 1 >= arguments.length) {
        return _usageError('Missing value for $argument.', errors);
      }
      outputFormat = arguments[++index];
    } else if (argument.startsWith('--format=')) {
      outputFormat = argument.substring(9);
    } else if (argument == '--batch' || argument == '-b') {
      batchFromStdin = true;
    } else if (argument == '--input' || argument == '-i') {
      if (index + 1 >= arguments.length) {
        return _usageError('Missing value for $argument.', errors);
      }
      inputPath = arguments[++index];
    } else if (argument.startsWith('--input=')) {
      inputPath = argument.substring(8);
      if (inputPath.isEmpty) {
        return _usageError('Missing value for --input.', errors);
      }
    } else if (argument.startsWith('-')) {
      return _usageError('Unknown option: $argument', errors);
    } else {
      inputParts.add(argument);
    }
  }

  if (!const {'text', 'json', 'osis', 'usfm'}.contains(outputFormat)) {
    return _usageError(
      'Unsupported format "$outputFormat". Use text, json, osis, or usfm.',
      errors,
    );
  }
  if (language != null && !language.isParsingSupported) {
    return _usageError(
      'Language "${language.code}" has no registered parser data.',
      errors,
    );
  }
  if (batchFromStdin && inputPath != null) {
    return _usageError(
      '--batch and --input cannot be used together.',
      errors,
    );
  }

  final isBatch = batchFromStdin || inputPath != null;
  if (isBatch && inputParts.isNotEmpty) {
    return _usageError(
      'A positional reference cannot be combined with batch input.',
      errors,
    );
  }
  if (!isBatch && inputParts.isEmpty) {
    return _usageError('A Bible reference is required.', errors);
  }

  if (!isBatch) {
    return _runSingle(
      inputParts.join(' '),
      language: language,
      outputFormat: outputFormat,
      output: output,
      errors: errors,
    );
  }

  try {
    final Stream<List<int>> inputBytes;
    if (inputPath case final path?) {
      final opener = openInputFile ?? _openInputFile;
      inputBytes = opener(path);
    } else {
      inputBytes = standardInput ?? stdin;
    }

    return await _runBatch(
      inputBytes,
      language: language,
      outputFormat: outputFormat,
      output: output,
      errors: errors,
    );
  } on IOException catch (error) {
    final source = inputPath == null ? 'standard input' : '"$inputPath"';
    errors.writeln('Unable to read $source: ${_ioErrorMessage(error)}');
    return _noInputExitCode;
  } on FormatException {
    final source = inputPath == null ? 'standard input' : '"$inputPath"';
    errors.writeln('Unable to read $source: input is not valid UTF-8.');
    return _noInputExitCode;
  }
}

Stream<List<int>> _openInputFile(String path) => File(path).openRead();

int _runSingle(
  String input, {
  required BibleLanguageEnum? language,
  required String outputFormat,
  required StringSink output,
  required StringSink errors,
}) {
  try {
    final parsed = _parseInput(input, language: language);
    if (outputFormat == 'json') {
      output.writeln(jsonEncode(_parsedToJson(parsed)));
    } else {
      output.writeln(_renderParsed(parsed, outputFormat, language));
    }
    return _successExitCode;
  } on ParseVerseRefError catch (error) {
    if (outputFormat == 'json') {
      output.writeln(
        jsonEncode({
          'ok': false,
          'input': input,
          'error': {
            'code': error.code,
            if (error.details case final details?) 'details': details,
          },
        }),
      );
    } else {
      _writeTextDiagnostic(errors, input: input, error: error);
    }
    return _dataErrorExitCode;
  }
}

Future<int> _runBatch(
  Stream<List<int>> inputBytes, {
  required BibleLanguageEnum? language,
  required String outputFormat,
  required StringSink output,
  required StringSink errors,
}) async {
  var lineNumber = 0;
  var hadFailure = false;
  final lines =
      inputBytes.transform(utf8.decoder).transform(const LineSplitter());

  await for (final rawLine in lines) {
    lineNumber++;
    final input = rawLine.trim();
    if (input.isEmpty) continue;

    try {
      final parsed = _parseInput(input, language: language);
      if (outputFormat == 'json') {
        output.writeln(
          jsonEncode({
            'line': lineNumber,
            'input': input,
            'ok': true,
            if (parsed is Reference)
              'reference': parsed.toJson()
            else
              'passage': (parsed as Passage).toJson(),
          }),
        );
      } else {
        output.writeln(_renderParsed(parsed, outputFormat, language));
      }
    } on ParseVerseRefError catch (error) {
      hadFailure = true;
      if (outputFormat == 'json') {
        output.writeln(
          jsonEncode({
            'line': lineNumber,
            'input': input,
            'ok': false,
            'error': {
              'code': error.code,
              if (error.details case final details?) 'details': details,
            },
          }),
        );
      } else {
        _writeTextDiagnostic(
          errors,
          input: input,
          error: error,
          lineNumber: lineNumber,
        );
      }
    }
  }

  return hadFailure ? _dataErrorExitCode : _successExitCode;
}

Object _parseInput(
  String input, {
  required BibleLanguageEnum? language,
}) {
  final reference = Reference.parseResult(input, language: language);
  if (reference.valueOrNull case final value?) return value;
  return Passage.parse(input, language: language);
}

Map<String, Object?> _parsedToJson(Object parsed) => switch (parsed) {
      Reference reference => reference.toJson(),
      Passage passage => passage.toJson(),
      _ => throw StateError('unsupported parsed value: ${parsed.runtimeType}'),
    };

String _renderParsed(
  Object parsed,
  String outputFormat,
  BibleLanguageEnum? language,
) =>
    switch (outputFormat) {
      'text' => switch (parsed) {
          Reference reference => reference.format(
              language: language ?? BibleLanguageEnum.english,
            ),
          Passage passage => passage.format(
              language: language ?? BibleLanguageEnum.english,
            ),
          _ => throw StateError(
              'unsupported parsed value: ${parsed.runtimeType}',
            ),
        },
      'osis' => switch (parsed) {
          Reference reference => reference.osisIdentifier,
          Passage passage => passage.osisIdentifier,
          _ => throw StateError(
              'unsupported parsed value: ${parsed.runtimeType}',
            ),
        },
      'usfm' => switch (parsed) {
          Reference reference => reference.usfmIdentifier,
          Passage passage => passage.usfmIdentifier,
          _ => throw StateError(
              'unsupported parsed value: ${parsed.runtimeType}',
            ),
        },
      _ => throw StateError('unsupported rendered format: $outputFormat'),
    };

void _writeTextDiagnostic(
  StringSink sink, {
  required String input,
  required ParseVerseRefError error,
  int? lineNumber,
}) {
  final prefix = lineNumber == null ? '' : 'Line $lineNumber: ';
  sink.writeln('${prefix}Unable to parse "$input" (${error.code}).');
  if (error.details case final details?) {
    sink.writeln(details);
  }
}

String _ioErrorMessage(IOException error) {
  if (error case FileSystemException(:final message)) {
    return message.endsWith('.') ? message : '$message.';
  }
  return error.toString();
}

int _usageError(String message, StringSink sink) {
  sink.writeln(message);
  _printUsage(sink);
  return _usageExitCode;
}

void _printUsage(StringSink sink) {
  sink.writeln('Usage:');
  sink.writeln(
    '  bible_io_references [--language CODE] '
    '[--format text|json|osis|usfm] '
    '"John 3:16"',
  );
  sink.writeln(
    '  bible_io_references [--language CODE] '
    '[--format text|json|osis|usfm] --batch',
  );
  sink.writeln(
    '  bible_io_references [--language CODE] '
    '[--format text|json|osis|usfm] '
    '--input FILE',
  );
  sink.writeln();
  sink.writeln('Batch input is UTF-8 with one passage per nonblank line.');
  sink.writeln('JSON batch output is JSON Lines, including per-line errors.');
  sink.writeln(
      'Exit codes: 0 success, 64 usage, 65 parse failure, 66 input error.');
}
