import 'package:bible_io_references/bible_io_references.dart';
import 'package:test/test.dart';

void main() {
  group('built-in Bible profiles', () {
    test('pair an exact canon and versification', () {
      final kjv = BibleProfile.protestantKingJames;

      expect(kjv, same(BibleProfile.kingJames));
      expect(kjv, same(BibleProfile.protestantKjv));
      expect(kjv.id, 'protestant-kjv');
      expect(kjv.canon, same(CanonProfile.protestant));
      expect(kjv.canonProfile, same(kjv.canon));
      expect(kjv.versification, same(VersificationProfile.kingJames));
      expect(kjv.versificationProfile, same(kjv.versification));
      expect(BibleProfile.values, hasLength(1));
      expect(() => BibleProfile.values.add(kjv), throwsUnsupportedError);
    });

    test('resolve stable IDs and friendly aliases', () {
      expect(
        BibleProfile.lookup('protestant-kjv'),
        same(BibleProfile.protestantKingJames),
      );
      expect(
        BibleProfile.lookup(' KJV '),
        same(BibleProfile.protestantKingJames),
      );
      expect(BibleProfile.lookup('catholic'), isNull);
      expect(BibleProfile.lookup('unknown'), isNull);
      expect(() => BibleProfile.require('unknown'), throwsArgumentError);
    });

    test('serialize stable configuration identifiers', () {
      final json = BibleProfile.protestantKingJames.toJson();

      expect(json, {
        'id': 'protestant-kjv',
        'displayName': 'Protestant / King James Version',
        'canonProfileId': 'protestant',
        'versificationProfileId': 'kjv',
      });
      expect(
        BibleProfile.fromJson(json),
        same(BibleProfile.protestantKingJames),
      );
      expect(
        () => BibleProfile.fromJson(const {'id': 'not-registered'}),
        throwsFormatException,
      );
      expect(
        () => BibleProfile.fromJson(
          const {
            'id': 'protestant-kjv',
            'versificationProfileId': 'not-kjv',
          },
        ),
        throwsFormatException,
      );
    });
  });

  group('custom Bible profiles', () {
    final canon = CanonProfile(
      id: 'tiny-canon',
      displayName: 'Tiny Canon',
      books: const [BibleBookEnum.john],
    );
    final versification = VersificationProfile(
      id: 'tiny-versification',
      displayName: 'Tiny Versification',
      canon: canon,
      verseCountsByBook: const {
        BibleBookEnum.john: [2],
      },
    );

    test('have value equality and validate canon compatibility', () {
      final first = BibleProfile(
        id: 'tiny-edition',
        displayName: 'Tiny Edition',
        canon: canon,
        versification: versification,
      );
      final equal = BibleProfile(
        id: 'tiny-edition',
        displayName: 'Tiny Edition',
        canon: canon,
        versification: versification,
      );

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(
        () => BibleProfile(
          id: 'bad-combination',
          displayName: 'Bad Combination',
          canon: CanonProfile.protestant,
          versification: versification,
        ),
        throwsArgumentError,
      );
    });

    test('require stable IDs and clean display names', () {
      expect(
        () => BibleProfile(
          id: 'Not Stable',
          displayName: 'Invalid',
          canon: canon,
          versification: versification,
        ),
        throwsArgumentError,
      );
      expect(
        () => BibleProfile(
          id: 'valid-id',
          displayName: ' Padded ',
          canon: canon,
          versification: versification,
        ),
        throwsArgumentError,
      );
    });

    test('custom registries are immutable and validate aliases', () {
      final custom = BibleProfile(
        id: 'tiny-edition',
        displayName: 'Tiny Edition',
        canon: canon,
        versification: versification,
      );
      final sourceProfiles = [custom];
      final sourceAliases = {'tiny': 'tiny-edition'};
      final registry = BibleProfileRegistry(
        profiles: sourceProfiles,
        aliases: sourceAliases,
      );

      sourceProfiles.clear();
      sourceAliases.clear();

      expect(registry.lookup('tiny'), custom);
      expect(registry.require('TINY-EDITION'), custom);
      expect(registry.aliases, {'tiny': 'tiny-edition'});
      expect(() => registry.profiles.add(custom), throwsUnsupportedError);
      expect(
        () => registry.aliases['other'] = 'tiny-edition',
        throwsUnsupportedError,
      );
      expect(
        BibleProfile.fromJson(custom.toJson(), registry: registry),
        custom,
      );
      expect(
        () => BibleProfile.fromJson(custom.toJson()),
        throwsFormatException,
      );
      expect(
        () => BibleProfileRegistry(profiles: [custom, custom]),
        throwsArgumentError,
      );
      expect(
        () => BibleProfileRegistry(
          profiles: [custom],
          aliases: const {'missing': 'not-registered'},
        ),
        throwsArgumentError,
      );
      expect(
        () => BibleProfileRegistry(
          profiles: [custom],
          aliases: const {'tiny-edition': 'tiny-edition'},
        ),
        throwsArgumentError,
      );
    });

    test('supports several editions within the same canon family', () {
      final alternateVersification = VersificationProfile(
        id: 'tiny-versification-b',
        displayName: 'Tiny Versification B',
        canon: canon,
        verseCountsByBook: const {
          BibleBookEnum.john: [3],
        },
      );
      final editionA = BibleProfile(
        id: 'tiny-edition-a',
        displayName: 'Tiny Edition A',
        canon: canon,
        versification: versification,
      );
      final editionB = BibleProfile(
        id: 'tiny-edition-b',
        displayName: 'Tiny Edition B',
        canon: canon,
        versification: alternateVersification,
      );
      final registry = BibleProfileRegistry(
        profiles: [editionA, editionB],
      );

      expect(registry.resolve('tiny-edition-a').canon, same(canon));
      expect(registry.resolve('tiny-edition-b').canon, same(canon));
      expect(
        registry.resolve('tiny-edition-a').versification.verseCount(
              BibleBookEnum.john,
              1,
            ),
        2,
      );
      expect(
        registry.resolve('tiny-edition-b').versification.verseCount(
              BibleBookEnum.john,
              1,
            ),
        3,
      );
    });
  });
}
