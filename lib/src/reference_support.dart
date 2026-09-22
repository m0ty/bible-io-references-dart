part of '../references.dart';

final _verseRefPattern =
    RegExp(r'^\s*(.+?)\s*(\d+)\s*[:.]\s*(\d+[a-zA-Z]?)\s*$');
final _verseTokenPattern = RegExp(r'^(\d+)([a-zA-Z]?)$');
final _verseSubdivisionPattern = RegExp(r'^[a-z]$');

({int verse, String? subdivision}) _parseVerseToken(
  String token, {
  required String component,
}) {
  final match = _verseTokenPattern.firstMatch(token);
  if (match == null) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.patternMismatch,
      details:
          '$component token "$token" must be a number with an optional letter a-z',
    );
  }
  final suffix = match.group(2)!;
  return (
    verse: _parseReferenceNumber(
      match.group(1)!,
      component: component,
      maximum: maxReferenceVerseNumber,
    ),
    subdivision: suffix.isEmpty ? null : suffix.toLowerCase(),
  );
}

void _ensureReferenceIsNotEmpty(String ref) {
  if (ref.trim().isEmpty) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.emptyReference,
      details: 'reference must not be empty',
    );
  }
}

/// Parse and broadly validate a chapter or verse number.
int _parseReferenceNumber(
  String value, {
  required String component,
  required int maximum,
}) {
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.invalidNumericToken,
      details: '$component token "$value" is not an integer',
    );
  }
  if (parsed <= 0) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.nonPositiveNumericToken,
      details: '$component token "$value" must be greater than zero',
    );
  }
  if (parsed > maximum) {
    throw ParseVerseRefError.typed(
      code: ReferenceParseErrorCode.numericTokenOutOfRange,
      details: '$component token "$value" exceeds the sanity limit $maximum',
    );
  }
  return parsed;
}

void _validateReferenceNumber(
  int value, {
  required String component,
  required int maximum,
}) {
  if (value < 1 || value > maximum) {
    throw RangeError.range(value, 1, maximum, component);
  }
}

int _intFromJson(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('"$key" must be an integer');
  }
  return value;
}

Map<String, Object?> _mapFromJson(Map<String, Object?> json, String key) =>
    _jsonObject(json[key], key);

BibleBookEnum _bookFromJson(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('"book" must be a non-empty string');
  }
  final normalized = value.trim().toLowerCase();
  for (final book in BibleBookEnum.values) {
    if (book.abbreviation.toLowerCase() == normalized ||
        book.name.toLowerCase() == normalized ||
        book.fullName.toLowerCase() == normalized) {
      return book;
    }
  }
  throw FormatException('unknown Bible book: $value');
}

Map<String, Object?> _jsonObject(Object? value, String component) {
  if (value is! Map) {
    throw FormatException('"$component" must be an object');
  }
  return Map<String, Object?>.from(value);
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
