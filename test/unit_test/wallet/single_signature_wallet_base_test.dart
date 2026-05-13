@Tags(['unit'])
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('SingleSignatureWalletBase', () {
    late SingleSignatureVault vault;
    late SingleSignatureWallet wallet;
    setUp(() {
      vault = MockFactory.createP2wpkhVault();
      wallet = SingleSignatureWallet.fromDescriptor(vault.descriptor);
    });
    group('get isVault', () {
      test('Check the object is vault', () {
        expect(wallet.isVault, false);
        expect(vault.isVault, true);
      });
    });
    group('get keyStore', () {
      test('Get key store from wallet base', () {
        expect(vault.keyStore.masterFingerprint,
            wallet.keyStore.masterFingerprint);
      });
    });
    group('getAddress', () {
      test('Get address of wallet base', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            wallet.getAddress(0), 'tb1qk4z5ysfc2k72pz2ws4dhskxdq772s7uqc35dp9');
        expect(wallet.getAddress(0, isChange: true),
            'tb1qyg29ghzqe5fweer9tyga4dtccxhnx4yqudfygp');
      });
    });
    group('getAddressWithDerivationPath', () {
      test('Get addresss with derivation path', () {
        expect(wallet.getAddressWithDerivationPath("m/84'/1'/0'/0/0"),
            "tb1qk4z5ysfc2k72pz2ws4dhskxdq772s7uqc35dp9");
        expect(wallet.getAddressWithDerivationPath("m/84'/1'/0'/1/0"),
            "tb1qyg29ghzqe5fweer9tyga4dtccxhnx4yqudfygp");
      });
    });
    group('getKeyOriginExpression', () {
      test('Get key origin expression', () {
        expect(wallet.getKeyOriginExpression().isNotEmpty, true);
      });
    });
    group('hasPublicKeyInPsbt', () {
      test('Can right vault can sign', () {
        Psbt psbt = MockFactory.createP2wpkhUnsignedPsbt();
        expect(vault.hasPublicKeyInPsbt(psbt.serialize()), true);

        SingleSignatureVault targetVault = SingleSignatureVault.random();
        expect(targetVault.hasPublicKeyInPsbt(psbt.serialize()), false);
      });
    });
    group('addSignatureToPsbt', () {
      test('Sign to psbt', () {
        Psbt psbt = MockFactory.createP2wpkhUnsignedPsbt();
        String signedPsbt = vault.addSignatureToPsbt(psbt.serialize());
        expect(signedPsbt.hashCode, 222298681);
      });

      test('throws when psbt address type mismatches', () {
        Psbt psbt = MockFactory.createP2wshUnsignedPsbt();
        expect(
            () => vault.addSignatureToPsbt(psbt.serialize()), throwsException);
      });
    });

    group('constructor guards via SingleSignatureVault.fromJson', () {
      test('throws on key network mismatch', () {
        NetworkType.setNetworkType(NetworkType.mainnet);
        final mainnetKeyStore =
            KeyStore.fromSeed(MockFactory.getCommonSeed(), AddressType.p2wpkh);
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(() => SingleSignatureVault.fromKeyStore(mainnetKeyStore),
            throwsException);
      });

      test('throws on invalid derivation path format', () {
        final keyStore = KeyStore.fromExtendedPublicKey(
          vault.keyStore.extendedPublicKey.serialize(),
          vault.keyStore.masterFingerprint,
        );
        final json = '{"keyStore":${jsonEncode(keyStore.toJson())},'
            '"addressTypeName":"p2wpkh","derivationPath":"x/84\'/1\'/0\'"}';
        expect(() => SingleSignatureVault.fromJson(json), throwsException);
      });

      test('throws on coin type mismatch in derivation path', () {
        final keyStore = KeyStore.fromExtendedPublicKey(
          vault.keyStore.extendedPublicKey.serialize(),
          vault.keyStore.masterFingerprint,
        );
        final json = '{"keyStore":${jsonEncode(keyStore.toJson())},'
            '"addressTypeName":"p2wpkh","derivationPath":"m/84\'/0\'/0\'"}';
        expect(() => SingleSignatureVault.fromJson(json), throwsException);
      });

      test('throws on network mismatch', () {
        final keyStore = KeyStore.fromExtendedPublicKey(
          vault.keyStore.extendedPublicKey.serialize(),
          vault.keyStore.masterFingerprint,
        );
        final json = '{"keyStore":${jsonEncode(keyStore.toJson())},'
            '"addressTypeName":"p2wpkh","derivationPath":"m/84\'/1\'/0\'"}';
        NetworkType.setNetworkType(NetworkType.mainnet);
        try {
          expect(() => SingleSignatureVault.fromJson(json), throwsException);
        } finally {
          NetworkType.setNetworkType(NetworkType.testnet);
        }
      });
    });
  });
}
