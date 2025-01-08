@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
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
      test('Parse extended public key', () {
        String exPubText =
            'zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNfE3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs';
        ExtendedPublicKey extendedPublicKey =
            ExtendedPublicKey.parse(exPubText);

        expect(extendedPublicKey.parentFingerprint, '7ef32bdb');
      });
    });
    group('serialize', () {
      test('Serialise extended public key', () {
        SingleSignatureVault vault =
            getMockSingleVault(TestWalletType.forNormal);
        expect(vault.keyStore.extendedPublicKey.serialize(),
            'vpub5ZZ1q76vi2LR9PeQDoV13u8TZwsyqKa7yBfD3GnPPvBjVU9ZnBTMkwzCHCVBZaPHDKJNEdMKo8MTyrQ9234idzSG9nHFD6hsUB8HJ14NBg7');
      });
    });
  });
}
