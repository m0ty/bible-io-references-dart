import 'package:bible_io_references/bible_book_enum.dart';
import 'package:bible_io_references/bible_profile.dart';
import 'package:bible_io_references/canon_profile.dart';
import 'package:bible_io_references/references.dart';
import 'package:bible_io_references/versification_profile.dart';
import 'package:test/test.dart';

void main() {
  final kjv = VersificationProfile.kingJames;

  group('opt-in parser validation', () {
    final parser = ReferenceParser(versificationProfile: kjv);

    test('keeps the standard parser backward-compatible and permissive', () {
      expect(Reference.parse('John 3:99'), isA<VerseRef>());
      expect(Reference.parse('Tobit 1:1'), isA<VerseRef>());
    });

    test('accepts coordinates at real KJV boundaries', () {
      expect(parser.parse('John 3:36'), Reference.parse('John 3:36'));
      expect(parser.parse('Revelation 12:17'), isA<VerseRef>());
      expect(parser.parse('3 John 1:14'), isA<VerseRef>());
    });

    test('returns typed chapter, verse, and canon failures', () {
      expect(
        parser.parseResult('John 22:1').errorOrNull?.errorCode,
        ReferenceParseErrorCode.chapterOutOfRange,
      );
      expect(
        parser.parseResult('John 3:37').errorOrNull?.errorCode,
        ReferenceParseErrorCode.verseOutOfRange,
      );
      expect(
        parser.parseResult('Tobit 1:1').errorOrNull?.errorCode,
        ReferenceParseErrorCode.bookNotInCanon,
      );
    });

    test('validates both endpoints of ranges', () {
      expect(parser.parse('John 3:35-4:2'), isA<VerseRangeRef>());
      expect(
        parser.parseResult('John 3:36-37').errorOrNull?.errorCode,
        ReferenceParseErrorCode.verseOutOfRange,
      );
      expect(
        parser.parseResult('John 3:36-22:1').errorOrNull?.errorCode,
        ReferenceParseErrorCode.chapterOutOfRange,
      );
    });
  });

  group('passage validation', () {
    final parser = PassageParser(
      referenceParser: ReferenceParser(versificationProfile: kjv),
    );

    test('validates books, chapters, shorthand, and every list selection', () {
      expect(parser.parse('John 21'), isA<ChapterPassage>());
      expect(parser.parse('Jude 25'), isA<VersePassage>());

      expect(
        parser.parseResult('Tobit').errorOrNull?.errorCode,
        ReferenceParseErrorCode.bookNotInCanon,
      );
      expect(
        parser.parseResult('John 22').errorOrNull?.errorCode,
        ReferenceParseErrorCode.chapterOutOfRange,
      );
      expect(
        parser.parseResult('Jude 26').errorOrNull?.errorCode,
        ReferenceParseErrorCode.verseOutOfRange,
      );
      expect(
        parser.parseResult('John 3:16,37').errorOrNull?.errorCode,
        ReferenceParseErrorCode.verseOutOfRange,
      );
    });

    test('validates chapter ranges and later list chapters', () {
      expect(parser.parse('John 20-21'), isA<ChapterPassage>());
      expect(parser.parse('John 3:16,4:1'), isA<VersePassage>());
      expect(
        parser.parseResult('John 21-22').errorOrNull?.errorCode,
        ReferenceParseErrorCode.chapterOutOfRange,
      );
      expect(
        parser.parseResult('John 3:16,22:1').errorOrNull?.errorCode,
        ReferenceParseErrorCode.chapterOutOfRange,
      );
    });
  });

  group('profile-aware ordering', () {
    final catholicParser = ReferenceParser(
      canonProfile: CanonProfile.catholic,
    );

    test('uses Catholic order instead of enum declaration order', () {
      final range = catholicParser.parseRange(
        'Tobit 1:1-Matthew 1:1',
      );

      expect(range.start.book, BibleBookEnum.tobit);
      expect(range.end.book, BibleBookEnum.matthew);
      expect(
        catholicParser
            .parseRangeResult('Matthew 1:1-Tobit 1:1')
            .errorOrNull
            ?.errorCode,
        ReferenceParseErrorCode.crossBookRangeNotAscending,
      );
    });

    test('checked factories and JSON can use the same canon order', () {
      final range = VerseRangeRef.checked(
        start: const VerseRef(
          book: BibleBookEnum.tobit,
          chapter: 1,
          verse: 1,
        ),
        end: const VerseRef(
          book: BibleBookEnum.matthew,
          chapter: 1,
          verse: 1,
        ),
        canonProfile: CanonProfile.catholic,
      );

      expect(
        Reference.fromJson(
          range.toJson(),
          canonProfile: CanonProfile.catholic,
        ),
        range,
      );
      expect(
        range.copyWith(canonProfile: CanonProfile.catholic),
        range,
      );
    });
  });

  group('profile-aware checked construction and JSON', () {
    test('checked reference factories enforce the supplied profile', () {
      expect(
        () => VerseRef.checked(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 37,
          versificationProfile: kjv,
        ),
        _throwsValidation(ReferenceValidationErrorCode.verseOutOfRange),
      );
      expect(
        () => VerseRef.checked(
          book: BibleBookEnum.tobit,
          chapter: 1,
          verse: 1,
          canonProfile: CanonProfile.protestant,
        ),
        _throwsValidation(ReferenceValidationErrorCode.bookNotInCanon),
      );
    });

    test('copies and JSON restoration can apply real validation', () {
      final verse = Reference.parse('John 3:16') as VerseRef;

      expect(
        () => verse.copyWith(verse: 37, versificationProfile: kjv),
        _throwsValidation(ReferenceValidationErrorCode.verseOutOfRange),
      );
      expect(
        () => Reference.fromJson(
          {'type': 'verse', 'book': 'jo', 'chapter': 3, 'verse': 37},
          versificationProfile: kjv,
        ),
        _throwsValidation(ReferenceValidationErrorCode.verseOutOfRange),
      );
      expect(
        () => ChapterPassage.checked(
          book: BibleBookEnum.john,
          startChapter: 22,
          versificationProfile: kjv,
        ),
        _throwsValidation(ReferenceValidationErrorCode.chapterOutOfRange),
      );
      expect(
        () => Passage.fromJson(
          {
            'type': 'chapter',
            'book': 'jo',
            'startChapter': 22,
            'endChapter': null,
          },
          versificationProfile: kjv,
        ),
        _throwsValidation(ReferenceValidationErrorCode.chapterOutOfRange),
      );
      expect(
        () => Passage.fromJson(
          {'type': 'book', 'book': 'tb'},
          versificationProfile: kjv,
        ),
        _throwsValidation(ReferenceValidationErrorCode.bookNotInCanon),
      );
    });

    test('rejects incompatible canon and versification combinations', () {
      expect(
        () => ReferenceParser(
          canonProfile: CanonProfile.catholic,
          versificationProfile: kjv,
        ),
        throwsArgumentError,
      );
    });
  });

  group('composite Bible profiles', () {
    final profile = BibleProfile.protestantKingJames;

    test('configure reference and passage parsers as one exact edition', () {
      final referenceParser = ReferenceParser(profile: profile);
      final referenceResult = referenceParser.parseResult('John 3:36');
      final passageResult = PassageParser(referenceParser: referenceParser)
          .parseResult('John 3:16,18-20');

      expect(referenceResult.isSuccess, isTrue);
      expect(referenceParser.profile, same(profile));
      expect(referenceParser.canonProfile, same(profile.canon));
      expect(
        referenceParser.versificationProfile,
        same(profile.versification),
      );
      expect(referenceResult.metadataOrNull?.profileId, 'protestant-kjv');
      expect(referenceResult.metadataOrNull?.canonProfileId, 'protestant');
      expect(referenceResult.metadataOrNull?.versificationProfileId, 'kjv');
      expect(passageResult.metadataOrNull?.profileId, 'protestant-kjv');
      expect(
        referenceParser.parseResult('John 3:37').errorOrNull?.errorCode,
        ReferenceParseErrorCode.verseOutOfRange,
      );
    });

    test('serializes validation context only when configured', () {
      final configured = ReferenceParser(profile: profile)
          .parseResult('John 3:16')
          .metadataOrNull!;
      final componentConfigured = ReferenceParser(
        canonProfile: CanonProfile.protestant,
        versificationProfile: kjv,
      ).parseResult('John 3:16').metadataOrNull!;
      final permissive = Reference.parseResult('John 3:16').metadataOrNull!;

      expect(configured.toJson()['validation'], {
        'profile': 'protestant-kjv',
        'canon': 'protestant',
        'versification': 'kjv',
      });
      expect(componentConfigured.toJson()['validation'], {
        'canon': 'protestant',
        'versification': 'kjv',
      });
      expect(permissive.toJson(), isNot(contains('validation')));
      expect(configured, isNot(permissive));
    });

    test('checked, copy, and JSON APIs accept the composite profile', () {
      expect(
        () => VerseRef.checked(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 37,
          profile: profile,
        ),
        _throwsValidation(ReferenceValidationErrorCode.verseOutOfRange),
      );

      final verse = Reference.parse('John 3:16') as VerseRef;
      expect(verse.copyWith(profile: profile), verse);
      expect(
        Reference.fromJson(verse.toJson(), profile: profile),
        verse,
      );
      expect(
        Passage.fromJson(
          const {
            'type': 'chapter',
            'book': 'jo',
            'startChapter': 21,
            'endChapter': null,
          },
          profile: profile,
        ),
        ChapterPassage(BibleBookEnum.john, 21),
      );
    });

    test('rejects mixing composite and component configuration', () {
      expect(
        () => ReferenceParser(
          profile: profile,
          canonProfile: CanonProfile.protestant,
        ),
        throwsArgumentError,
      );
      expect(
        () => VerseRef.checked(
          book: BibleBookEnum.john,
          chapter: 3,
          verse: 16,
          profile: profile,
          versificationProfile: kjv,
        ),
        throwsArgumentError,
      );
      expect(
        () => Reference.fromJson(
          const {'type': 'verse', 'book': 'jo', 'chapter': 3, 'verse': 16},
          profile: profile,
          canonProfile: CanonProfile.protestant,
        ),
        throwsArgumentError,
      );
    });
  });
}

Matcher _throwsValidation(ReferenceValidationErrorCode code) => throwsA(
      isA<ReferenceValidationException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );
