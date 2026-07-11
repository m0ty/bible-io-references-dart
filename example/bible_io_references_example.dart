import 'package:bible_io_references/bible_io_references.dart';

void main() {
  final verse = Reference.parse('John 3:16');
  print(verse.displayString); // John 3:16

  final range = Reference.parse('John 3:16-17');
  print(range.displayString); // John 3:16-17

  final spanishVerse = Reference.parse(
    'Juan 3:16',
    language: BibleLanguageEnum.spanish,
  );
  print(
    spanishVerse.format(language: BibleLanguageEnum.spanish),
  ); // Juan 3:16

  final result = Reference.parseResult('not a reference');
  if (result case ParseFailure(error: final error)) {
    print(error.errorCode); // ReferenceParseErrorCode.patternMismatch
  }

  final restored = Reference.fromJson(verse.toJson());
  print(restored == verse); // true
}
