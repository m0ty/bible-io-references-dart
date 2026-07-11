import 'dart:convert';
import 'dart:io';

import 'package:bible_io_references/bible_io_references.dart';

void main(List<String> arguments) {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printUsage(stdout);
    return;
  }

  BibleLanguageEnum? language;
  var outputFormat = 'text';
  final inputParts = <String>[];

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--language' || argument == '-l') {
      if (index + 1 >= arguments.length) {
        _usageError('Missing value for $argument.');
        return;
      }
      try {
        language = BibleLanguageEnum.fromStr(arguments[++index]);
      } on ArgumentError catch (error) {
        _usageError(error.message?.toString() ?? error.toString());
        return;
      }
    } else if (argument.startsWith('--language=')) {
      try {
        language = BibleLanguageEnum.fromStr(argument.substring(11));
      } on ArgumentError catch (error) {
        _usageError(error.message?.toString() ?? error.toString());
        return;
      }
    } else if (argument == '--format' || argument == '-f') {
      if (index + 1 >= arguments.length) {
        _usageError('Missing value for $argument.');
        return;
      }
      outputFormat = arguments[++index];
    } else if (argument.startsWith('--format=')) {
      outputFormat = argument.substring(9);
    } else if (argument.startsWith('-')) {
      _usageError('Unknown option: $argument');
      return;
    } else {
      inputParts.add(argument);
    }
  }

  if (inputParts.isEmpty) {
    _usageError('A Bible reference is required.');
    return;
  }
  if (outputFormat != 'text' && outputFormat != 'json') {
    _usageError('Unsupported format "$outputFormat". Use text or json.');
    return;
  }
  if (language != null && !language.isParsingSupported) {
    _usageError('Language "${language.code}" has no registered parser data.');
    return;
  }

  final input = inputParts.join(' ');

  try {
    final reference = Reference.parse(input, language: language);
    if (outputFormat == 'json') {
      stdout.writeln(jsonEncode(reference.toJson()));
    } else {
      stdout.writeln(
        reference.format(
          language: language ?? BibleLanguageEnum.english,
        ),
      );
    }
  } on ParseVerseRefError catch (error) {
    stderr.writeln('Unable to parse "$input" (${error.code}).');
    if (error.details case final details?) {
      stderr.writeln(details);
    }
    exitCode = 65;
  }
}

void _usageError(String message) {
  stderr.writeln(message);
  _printUsage(stderr);
  exitCode = 64;
}

void _printUsage(IOSink sink) {
  sink.writeln(
    'Usage: bible_io_references [--language CODE] [--format text|json] '
    '"John 3:16"',
  );
}
