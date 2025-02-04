@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() async {
  group('MultisignatureWallet', () {
    late MultisignatureVault vault;
    setUpAll(() async {
      NetworkType.setNetworkType(NetworkType.regtest);
      vault = MockFactory.createP2wshVault();
    });
    group('MultisignatureWallet.fromDescriptor', () {
      test('Generate multisignature wallet from descriptor', () {
        String descriptor = vault.descriptor;
        MultisignatureWallet wallet =
            MultisignatureWallet.fromDescriptor(descriptor);
        expect(wallet.requiredSignature, vault.requiredSignature);
        expect(wallet.addressType, vault.addressType);
        expect(wallet.derivationPath, vault.derivationPath);
        expect(wallet.keyStoreList.length, vault.keyStoreList.length);
        for (int i = 0; i < wallet.keyStoreList.length; i++) {
          expect(wallet.keyStoreList[i].extendedPublicKey.serialize(),
              vault.keyStoreList[i].extendedPublicKey.serialize());
        }
      });

      test('Single signature address type exception', () {
        SingleSignatureVault singleSignatureVault =
            MockFactory.createP2wpkhVault();
        expect(
            () => MultisignatureWallet.fromDescriptor(
                singleSignatureVault.descriptor),
            throwsException);
      });

      test('Different derivation exception', () {
        String differentPathDescriptor =
            "wsh(sortedmulti(1,[8EFC895E/48'/1'/0'/2']Vpub5nN5Zc3xDWKyXMbg2mzzAAQ8XgYrh1oaatFMHKv8f2gGcKMaA58YwKZBgarEQKvjs4ZnQ5BoHsLkdvqGRvvP4nLzKHREETB1YnNiMVbyDVa/<0;1>/*,[9DBECA1F/48'/1'/1'/2']Vpub5mKNm4dPgX1USP4jz38ASU7iVdB2XKoafgMKVQz6ZsQt4WoDnyvgMPSicFNDWybjQhohqgpyuHpA7duHRf6Yvx558oSU5g7upR9qffNnQRJ/<0;1>/*))#n3j32yxq";
        expect(
            () => MultisignatureWallet.fromDescriptor(differentPathDescriptor),
            throwsException);
      });
    });

    group('toJson', () {
      test('Get json text from multisignature wallet', () {
        MultisignatureWallet wallet =
            MultisignatureWallet.fromDescriptor(vault.descriptor);
        String json = wallet.toJson();
        expect(json.hashCode, 1028603620);
      });
    });
    group('MultisignatureWallet.fromJson', () {
      test('MultisignatureWallet.fromJson', () {
        MultisignatureWallet wallet =
            MultisignatureWallet.fromDescriptor(vault.descriptor);
        String json = wallet.toJson();
        MultisignatureWallet targetWallet = MultisignatureWallet.fromJson(json);

        expect(targetWallet.requiredSignature, wallet.requiredSignature);
        expect(targetWallet.addressType, wallet.addressType);
        expect(targetWallet.derivationPath, wallet.derivationPath);
        expect(targetWallet.keyStoreList.length, wallet.keyStoreList.length);
        for (int i = 0; i < targetWallet.keyStoreList.length; i++) {
          expect(targetWallet.keyStoreList[i].extendedPublicKey.serialize(),
              wallet.keyStoreList[i].extendedPublicKey.serialize());
        }
      });
    });
  });
}
