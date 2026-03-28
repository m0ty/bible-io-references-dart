import 'package:bible_io_references/package.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Usage: dart run bin/package.dart "John 3:16"');
    return;
  }

  final refStr = arguments[0];
  try {
    final parsed = Reference.parse(refStr);
    if (parsed is VerseRef) {
      print('Parsed as single verse: $parsed');
    } else if (parsed is VerseRangeRef) {
      print('Parsed as range: $parsed');
    }
  } catch (e) {
    print('Error parsing "$refStr": $e');
  }
}
