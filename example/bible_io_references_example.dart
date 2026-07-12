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

  final parser = ReferenceParser(
    aliases: {'jn': BibleBookEnum.john},
    ambiguityPolicy: ReferenceAmbiguityPolicy.reject,
  );
  final customResult = parser.parseResult('jn 3:16');
  print(customResult.valueOrNull); // John 3:16
  print(customResult.metadataOrNull?.alternateMatches.length); // 1 or more

  print(verse.osisIdentifier); // John.3.16
  print(verse.usfmIdentifier); // JHN 3:16

  final passage = Passage.parse('John 3:16,18-20; Acts 2');
  print(passage); // John 3:16,18-20; Acts 2

  final normalized = ReferenceInputNormalizer.normalize(
    'John \u0663\uff1a\u0661\u0666',
  );
  print(normalized); // John 3:16

  const prose = 'Study John 3:16 and Acts 2:1-4 today.';
  final matches = ReferenceExtractor().extract(prose);
  for (final match in matches) {
    print('${match.start}-${match.end}: ${match.passage}');
  }
}
