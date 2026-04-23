@Tags(['unit'])

import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('SingleSignatureVault', () {
    late SingleSignatureVault vault;
    setUpAll(() {
      vault = MockFactory.createP2wpkhVault();
    });
    group('SingleSignatureVault.fromKeyStore', () {
      test('Generate single signature vault from key store', () {
        KeyStore keyStore = vault.keyStore;
        SingleSignatureVault targetVault =
            SingleSignatureVault.fromKeyStore(keyStore);
        expect(
            targetVault.keyStore.masterFingerprint, keyStore.masterFingerprint);
        expect(targetVault.keyStore.extendedPublicKey.serialize(),
            keyStore.extendedPublicKey.serialize());
      });

      test('throws for multisig-only address types', () {
        KeyStore keyStore = vault.keyStore;
        expect(
            () => SingleSignatureVault.fromKeyStore(keyStore,
                addressType: AddressType.p2sh),
            throwsException);
        expect(
            () => SingleSignatureVault.fromKeyStore(keyStore,
                addressType: AddressType.p2wsh),
            throwsException);
      });
    });
    group('SingleSignatureVault.random', () {
      test('Generate random single signature vault', () {
        SingleSignatureVault targetVault = SingleSignatureVault.random(
            mnemonicLength: 24, passphrase: utf8.encode('passphrase'));
        SingleSignatureVault matcherVault = SingleSignatureVault.random(
            mnemonicLength: 24, passphrase: utf8.encode('passphrase'));
        expect(
            targetVault.keyStore.masterFingerprint ==
                matcherVault.keyStore.masterFingerprint,
            false);
      });
    });
    group('SingleSignatureVault.fromMnemonic', () {
      test('Generate singla signature vault from mnemonic', () {
        SingleSignatureVault targetVault =
            SingleSignatureVault.fromMnemonic(vault.keyStore.seed.mnemonic);
        expect(targetVault.keyStore.masterFingerprint,
            vault.keyStore.masterFingerprint);
      });
    });
    group('SingleSignatureVault.fromSeed', () {
      test('Generate single signature vault from seed', () {
        SingleSignatureVault targetVault =
            SingleSignatureVault.fromSeed(vault.keyStore.seed);
        expect(targetVault.keyStore.masterFingerprint,
            vault.keyStore.masterFingerprint);
      });
    });
    group('SingleSignatureVault.fromEntropy', () {
      test('Generate single signature vault from entropy', () {
        SingleSignatureVault targetVault = SingleSignatureVault.fromEntropy(
            utf8.encode("11111111111111111111111111111111"));
        expect(targetVault, isA<SingleSignatureVault>());
      });
    });
    group('getSignerBsms', () {
      test('Get signer bsms', () {
        expect(vault.getSignerBsms(AddressType.p2wsh, "").hashCode, 380644378);
      });

      test('throws when keyStore has no seed', () {
        final source = vault.keyStore;
        final seedless = SingleSignatureVault.fromKeyStore(
          KeyStore.fromExtendedPublicKey(
            source.extendedPublicKey.serialize(),
            source.masterFingerprint,
          ),
        );
        expect(() => seedless.getSignerBsms(AddressType.p2wsh, ''), throwsException);
      });

      test('throws when target address type is not multisig/p2tr', () {
        expect(() => vault.getSignerBsms(AddressType.p2wpkh, ''), throwsException);
      });
    });

    group('json', () {
      test('toJson/fromJson roundtrip', () {
        final source = vault.keyStore;
        final seedlessVault = SingleSignatureVault.fromKeyStore(
          KeyStore.fromExtendedPublicKey(
            source.extendedPublicKey.serialize(),
            source.masterFingerprint,
          ),
          addressType: vault.addressType,
        );
        final json = seedlessVault.toJson();
        final restored = SingleSignatureVault.fromJson(json);
        expect(restored.addressType, seedlessVault.addressType);
        expect(restored.derivationPath, seedlessVault.derivationPath);
        expect(restored.keyStore.masterFingerprint,
            seedlessVault.keyStore.masterFingerprint);
      });
    });
  });
}
