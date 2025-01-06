@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/utils/converter.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() {
  group('ExtendedPublicKey', () {
    group('ExtendedPublicKey.fromHdWallet', () {
      test('Generate ExtendedPublicKey', () {
        SingleSignatureVault vault =
            getMockSingleVault(TestWalletType.forNormal);
        HDWallet hdWallet = vault.keyStore.hdWallet;
        ExtendedPublicKey extendedPublicKey = ExtendedPublicKey.fromHdWallet(
            hdWallet,
            AddressType.p2wpkh.versionForTestnet,
            Uint8List.fromList(hdWallet.parentFingerprint));

        expect(extendedPublicKey.serialize(),
            vault.keyStore.extendedPublicKey.serialize());
      });
    });
    group('ExtendedPublicKey.parse', () {
      test('', () {});
    });
    group('serialize', () {
      test('', () {});
    });
    group('', () {
      test('', () {});
    });
  });
}
