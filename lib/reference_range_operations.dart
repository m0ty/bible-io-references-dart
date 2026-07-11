import 'references.dart';
import 'versification_profile.dart';

/// Profile-aware operations over the inclusive verse span of a [Reference].
///
/// A [VerseRef] is treated as a one-verse span. A [VerseRangeRef] includes
/// both its [VerseRangeRef.start] and [VerseRangeRef.end] verses. Every
/// operation that depends on ordering or verse counts requires an explicit
/// [VersificationProfile], so cross-book behavior never relies on
/// [BibleBookEnum.index].
extension ReferenceRangeOperations on Reference {
  /// The inclusive first verse represented by this reference.
  VerseRef get firstVerse => switch (this) {
        VerseRef verse => verse,
        VerseRangeRef range => range.start,
      };

  /// The inclusive last verse represented by this reference.
  VerseRef get lastVerse => switch (this) {
        VerseRef verse => verse,
        VerseRangeRef range => range.end,
      };

  /// Whether this reference contains every verse represented by [other].
  ///
  /// Both references are validated against [profile]. Invalid coordinates
  /// propagate [ReferenceValidationException]. A raw range whose end does not
  /// come after its start in the selected profile throws [ArgumentError].
  bool contains(
    Reference other, {
    required VersificationProfile profile,
  }) {
    final span = _ResolvedReferenceSpan.fromReference(this, profile);
    final otherSpan = _ResolvedReferenceSpan.fromReference(other, profile);
    return span.startOrdinal <= otherSpan.startOrdinal &&
        span.endOrdinal >= otherSpan.endOrdinal;
  }

  /// Whether this reference and [other] share at least one verse.
  ///
  /// Adjacent references do not intersect. Use [merge] with its default
  /// `includeAdjacent` value to combine an adjacent pair.
  bool intersects(
    Reference other, {
    required VersificationProfile profile,
  }) {
    final span = _ResolvedReferenceSpan.fromReference(this, profile);
    final otherSpan = _ResolvedReferenceSpan.fromReference(other, profile);
    return span.startOrdinal <= otherSpan.endOrdinal &&
        otherSpan.startOrdinal <= span.endOrdinal;
  }

  /// Returns the inclusive union of this reference and [other].
  ///
  /// The result is `null` when the union would contain a hole. By default,
  /// immediately adjacent references merge because their union is contiguous
  /// in the discrete verse sequence. Set [includeAdjacent] to `false` to
  /// restrict merging to references that overlap.
  ///
  /// The result is a [VerseRef] when the union contains one verse and a
  /// [VerseRangeRef] otherwise. Ranges are constructed after profile-aware
  /// validation rather than through the legacy enum-order checked factory.
  Reference? merge(
    Reference other, {
    required VersificationProfile profile,
    bool includeAdjacent = true,
  }) {
    final left = _ResolvedReferenceSpan.fromReference(this, profile);
    final right = _ResolvedReferenceSpan.fromReference(other, profile);

    final earlier = left.startOrdinal <= right.startOrdinal ? left : right;
    final later = identical(earlier, left) ? right : left;
    final overlaps = later.startOrdinal <= earlier.endOrdinal;
    final isAdjacent = later.startOrdinal - earlier.endOrdinal == 1;
    if (!overlaps && !(includeAdjacent && isAdjacent)) return null;

    final startOrdinal = earlier.startOrdinal;
    final endOrdinal = left.endOrdinal >= right.endOrdinal
        ? left.endOrdinal
        : right.endOrdinal;
    final start = _verseAt(profile, startOrdinal);
    if (startOrdinal == endOrdinal) return start;
    return VerseRangeRef(
      start: start,
      end: _verseAt(profile, endOrdinal),
    );
  }

  /// Lazily iterates over every represented verse in canonical order.
  ///
  /// The reference is validated eagerly when this method is called; individual
  /// [VerseRef] values are produced only as the returned iterable is consumed.
  Iterable<VerseRef> verses({
    required VersificationProfile profile,
  }) {
    final span = _ResolvedReferenceSpan.fromReference(this, profile);
    return Iterable<VerseRef>.generate(
      span.length,
      (offset) => _verseAt(profile, span.startOrdinal + offset),
    );
  }

  /// The inclusive number of verses represented by this reference.
  int verseCount({
    required VersificationProfile profile,
  }) =>
      _ResolvedReferenceSpan.fromReference(this, profile).length;
}

final class _ResolvedReferenceSpan {
  const _ResolvedReferenceSpan(this.startOrdinal, this.endOrdinal);

  factory _ResolvedReferenceSpan.fromReference(
    Reference reference,
    VersificationProfile profile,
  ) {
    final startOrdinal = _ordinalOf(profile, reference.firstVerse);
    final endOrdinal = _ordinalOf(profile, reference.lastVerse);
    if (reference is VerseRangeRef && startOrdinal >= endOrdinal) {
      throw ArgumentError.value(
        reference,
        'reference',
        'range end must come after its start in the ${profile.displayName} '
            'versification',
      );
    }
    return _ResolvedReferenceSpan(startOrdinal, endOrdinal);
  }

  final int startOrdinal;
  final int endOrdinal;

  int get length => endOrdinal - startOrdinal + 1;
}

int _ordinalOf(VersificationProfile profile, VerseRef verse) =>
    profile.ordinalOf(
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
    );

VerseRef _verseAt(VersificationProfile profile, int ordinal) {
  final coordinate = profile.coordinateAt(ordinal);
  return VerseRef.checked(
    book: coordinate.book,
    chapter: coordinate.chapter,
    verse: coordinate.verse,
  );
}
