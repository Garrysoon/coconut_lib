@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('MultisignatureVault', () {
    late MultisignatureVault vault;
    setUpAll(() {
      vault = MockFactory.createP2wshVault();
    });
    group('MultisignatureVault.fromKeyStoreList', () {
      test('Generate multisignature vault from key store list', () {
        List<KeyStore> keyStoreList = vault.keyStoreList;
        MultisignatureVault targetVault =
            MultisignatureVault.fromKeyStoreList(keyStoreList, 2);

        expect(targetVault, isA<MultisignatureVault>());
        expect(vault.descriptor, targetVault.descriptor);
        expect(() => MultisignatureVault.fromKeyStoreList(keyStoreList, 4),
            throwsException);
      });
    });
    group('MultisignatureVault.fromSeedList', () {
      test('Generate multisignature vault from seed list', () {
        List<Seed> seedList = [];
        for (int i = 0; i < 3; i++) {
          seedList.add(vault.keyStoreList[i].seed);
        }
        MultisignatureVault targetVault =
            MultisignatureVault.fromSeedList(seedList, 2);

        expect(targetVault, isA<MultisignatureVault>());
        expect(vault.descriptor, targetVault.descriptor);
      });
    });
    group('MultisignatureVault.fromCoordinatorBsms', () {
      test('Generate multisignature vault from BSMS coordinator', () {
        MultisignatureVault targetVault =
            MultisignatureVault.fromCoordinatorBsms(vault.getCoordinatorBsms(),
                addressType: AddressType.p2wsh);

        expect(targetVault, isA<MultisignatureVault>());
        expect(vault.descriptor, targetVault.descriptor);
      });
    });
    group('bindSeedToKeyStore', () {
      test('Bind seed to vault', () {
        MultisignatureVault targetVault =
            MultisignatureVault.fromCoordinatorBsms(vault.getCoordinatorBsms(),
                addressType: AddressType.p2wsh);
        for (int i = 0; i < targetVault.keyStoreList.length; i++) {
          targetVault.bindSeedToKeyStore(vault.keyStoreList[i].seed);
        }
        for (int i = 0; i < targetVault.keyStoreList.length; i++) {
          expect(vault.keyStoreList[i].seed, targetVault.keyStoreList[i].seed);
        }
      });
    });
    group('toJson', () {
      test('Get json text', () {
        int hash = vault.toJson().hashCode;
        expect(hash, 1025753301);
      });
    });
    group('MultisignatureVault.fromJson', () {
      test('Generate multisignature vault from json', () {
        String json = vault.toJson();
        MultisignatureVault targetVault = MultisignatureVault.fromJson(json);
        expect(vault.descriptor, targetVault.descriptor);
        for (int i = 0; i < targetVault.keyStoreList.length; i++) {
          expect(vault.keyStoreList[i].seed, targetVault.keyStoreList[i].seed);
        }
      });
    });
  });
}
