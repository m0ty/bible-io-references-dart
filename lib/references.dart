/// Bible reference and passage models, parsing APIs, and parse results.
library;

import 'bible_book_enum.dart';
import 'bible_language_enum.dart';
import 'languages.dart';
import 'reference_input_normalizer.dart';

// One library preserves public type identity and lets sealed models and parsers
// share private implementation details across these focused source files.
part 'src/reference_models.dart';
part 'src/verse_label.dart';
part 'src/passage_models.dart';
part 'src/parse_result.dart';
part 'src/reference_parser.dart';
part 'src/passage_parser.dart';
part 'src/book_alias_index.dart';
part 'src/legacy_reference_parser.dart';
part 'src/reference_support.dart';
