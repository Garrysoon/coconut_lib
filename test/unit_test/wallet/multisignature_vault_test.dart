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
      test('Generate MuSig2 vault from key store list', () {
        KeyStore keyStore0 =
            KeyStore.fromEntropy(Hash.sha256("A"), AddressType.p2trMuSig2);
        KeyStore keyStore1 =
            KeyStore.fromEntropy(Hash.sha256("B"), AddressType.p2trMuSig2);
        KeyStore keyStore2 =
            KeyStore.fromEntropy(Hash.sha256("C"), AddressType.p2trMuSig2);
        List<KeyStore> keyStoreList_1 = [keyStore0, keyStore1, keyStore2];
        List<KeyStore> keyStoreList_2 = [keyStore1, keyStore0, keyStore2];
        MultisignatureVault targetVault_1 =
            MultisignatureVault.fromKeyStoreList(keyStoreList_1, 3,
                addressType: AddressType.p2trMuSig2);
        MultisignatureVault targetVault_2 =
            MultisignatureVault.fromKeyStoreList(keyStoreList_2, 3,
                addressType: AddressType.p2trMuSig2);

        expect(targetVault_1, isA<MultisignatureVault>());
        expect(targetVault_2, isA<MultisignatureVault>());
        expect(targetVault_1.descriptor, targetVault_2.descriptor);
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
