@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('KeyStore', () {
    late Seed seed;
    late KeyStore keyStore;
    setUpAll(() async {
      seed = Seed.fromMnemonic(
          "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about");
      keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh);
    });
    group('KeyStore.fromSeed', () {
      test('Generate key store from seed', () {
        expect(keyStore, isA<KeyStore>());
        expect(keyStore.seed, seed);
        expect(keyStore.extendedPublicKey.serialize(),
            'vpub5Y6cjg78GGuNLsaPhmYsiw4gYX3HoQiRBiSwDaBXKUafCt9bNwWQiitDk5VZ5BVxYnQdwoTyXSs2JHRPAgjAvtbBrf8ZhDYe2jWAqvZVnsc');
      });
    });
    group('KeyStore.fromMnemonic', () {
      test('Generate key store with mnemonic', () {
        KeyStore keyStore = KeyStore.fromMnemonic(
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            AddressType.p2wpkh);
        expect(keyStore, isA<KeyStore>());
        expect(keyStore.extendedPublicKey.serialize(),
            'vpub5Y6cjg78GGuNLsaPhmYsiw4gYX3HoQiRBiSwDaBXKUafCt9bNwWQiitDk5VZ5BVxYnQdwoTyXSs2JHRPAgjAvtbBrf8ZhDYe2jWAqvZVnsc');
      });
    });
    group('KeyStore.random', () {
      test('Generate random key store', () {
        KeyStore keyStore = KeyStore.random(AddressType.p2wpkh);
        expect(keyStore, isA<KeyStore>());
      });
    });
    group('KeyStore.fromEntropy', () {
      test('Generate key store from entropy', () {
        KeyStore keyStore = KeyStore.fromEntropy(
            "11111111111111111111111111111111", AddressType.p2wpkh);
        expect(keyStore, isA<KeyStore>());
        expect(keyStore.extendedPublicKey.serialize(),
            'vpub5ZdiLsDFtRYJRUx3ovW4FhpN4PVteQ5NYDCTPmCzndUas71bsVDRcuHh9VfJR9kAPXXyRoi2BZnqZdnMGTKM615fcwnu9YG28HmnCWEKjDq');
      });
    });
    group('KeyStore.fromSignerBsms', () {
      test('Generate key store from signer', () {
        String bsms =
            '''BSMS 1.0\n00\n[98C7D774/48'/1'/0'/2']Vpub5n3ihNrEwZjBFZ32N6STEsMaUPAJ42pjoVMgbZUAuPbuubQR5eDXUyB8nw6ASMmzpM4PjyVsx6BHGhZwufeyVzCHxwLcXW5RoQ5feCiE6Qm\nmy wallet''';
        KeyStore keyStore = KeyStore.fromSignerBsms(bsms);
        expect(keyStore, isA<KeyStore>());
        expect(keyStore.extendedPublicKey.serialize(),
            'Vpub5n3ihNrEwZjBFZ32N6STEsMaUPAJ42pjoVMgbZUAuPbuubQR5eDXUyB8nw6ASMmzpM4PjyVsx6BHGhZwufeyVzCHxwLcXW5RoQ5feCiE6Qm');
      });
    });
    group('getPrivateKey', () {
      test('Get private key (receive)', () {
        String privateKey = '3uhZVhK22HgcQQjun7Uysc2cTZGqLDuiSUXnJMUWtLQvo44';
        expect(keyStore.getPrivateKey(0), privateKey);
      });
      test('Get private key (change)', () {
        String privateKey = '3uDFZxBEWBcRjAMMzjbSmXiX869rUg26FnYN22RxtsP8ojE';
        expect(keyStore.getPrivateKey(0, isChange: true), privateKey);
      });
    });
    group('sign', () {
      test('No seed exception', () {
        String message = '1234567890ABCDEF';
        SingleSignatureWallet wallet = SingleSignatureWallet.fromDescriptor(
            MockFactory.createP2wpkhVault().descriptor);
        expect(
            () => wallet.keyStore.sign(message, 0), throwsA(isA<Exception>()));
      });
      test('Signature with recevie private key', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        expect(keyStore.sign(hashedMessage, 0),
            '30450221008381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd02205a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe01');
      });
      test('Signature with change private key', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        expect(keyStore.sign(hashedMessage, 0, isChange: true),
            '30440220525634740bc3fe58323e2eac200330e6f982ce8a410464040df07fe8b19a442c022003d6e3c369728f1553a17650192b064b77e2d16f4f43d852d455e03ead3e76ed01');
      });
      test('Signature to non DER', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        expect(keyStore.sign(hashedMessage, 0, isDer: false),
            '8381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd5a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe');
      });
    });
    group('signWithDerivationPath', () {
      test('Signature with derivation path', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        expect(
            keyStore.signWithDerivationPath(hashedMessage, "m/84'/1'/0'/0/0"),
            '30450221008381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd02205a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe01');
      });

      test('Signature with derivation path to non DER', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        expect(
            keyStore.signWithDerivationPath(hashedMessage, "m/84'/1'/0'/0/0",
                isDer: false),
            '8381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd5a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe');
      });
    });
    group('getPublicKey', () {
      test('Get public key', () {
        expect(keyStore.getPublicKey(0),
            '02e7ab2537b5d49e970309aae06e9e49f36ce1c9febbd44ec8e0d1cca0b4f9c319');
      });
      test('Get public key for change', () {
        expect(keyStore.getPublicKey(0, isChange: true),
            '035d49eccd54d0099e43676277c7a6d4625d611da88a5df49bf9517a7791a777a5');
      });
    });
    group('getPublicKeyWithDerivationPath', () {
      test('Get public key from derivation path', () {
        expect(keyStore.getPublicKeyWithDerivationPath("m/84'/1'/0'/0/0"),
            '02e7ab2537b5d49e970309aae06e9e49f36ce1c9febbd44ec8e0d1cca0b4f9c319');
      });
    });
    group('validateSignature', () {
      test('Validate signature', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        String signature =
            '30450221008381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd02205a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe01';
        expect(keyStore.validateSignature(signature, hashedMessage, 0), true);
      });

      test('Validate signature from non DER', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        String signature =
            '8381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd5a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe';
        expect(
            keyStore.validateSignature(signature, hashedMessage, 0,
                isDer: false),
            true);
      });
    });
    group('validateSignatureWithDerivationPath', () {
      test('Validate signature with derivation path', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        String signature =
            '30450221008381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd02205a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe01';
        expect(
            keyStore.validateSignatureWithDerivationPath(
                signature, hashedMessage, "m/84'/1'/0'/0/0"),
            true);
      });

      test('Validate signature with derivation path from non DER', () {
        String message = '1234567890ABCDEF';
        String hashedMessage = Hash.sha256(message);
        String signature =
            '8381590828444d6bb82cc7dcbbe64364cd12b16ced846643f369a2ee613b80bd5a2680bffe958c69dfac6feba5bef01e93b4c30a5819624b02965c906ca4abfe';
        expect(
            keyStore.validateSignatureWithDerivationPath(
                signature, hashedMessage, "m/84'/1'/0'/0/0",
                isDer: false),
            true);
      });
    });
    group('canSignToPsbt', () {
      test('Check sign possibility with wrong key store', () {
        PSBT psbt = MockFactory.createP2wpkhUnsignedPsbt();
        expect(keyStore.canSignToPsbt(psbt.serialize()), false);
      });
      test('Check sign possibility with right key store', () {
        PSBT psbt = MockFactory.createP2wpkhUnsignedPsbt();

        expect(
            MockFactory.createP2wpkhVault()
                .keyStore
                .canSignToPsbt(psbt.serialize()),
            true);
      });
    });
    group('addSignatureToPsbt', () {
      test('Sign to PSBT', () {
        PSBT unsignedPsbt = MockFactory.createP2wpkhUnsignedPsbt();
        String signedPsbtText = MockFactory.createP2wpkhVault()
            .addSignatureToPsbt(unsignedPsbt.serialize());
        print(signedPsbtText.hashCode);
        expect(signedPsbtText.hashCode, 862890113);
      });
    });
    group('toJson', () {
      test('Generate json', () {
        expect(keyStore.toJson().hashCode, 138507244);
      });
    });
    group('KeyStore.fromJson', () {
      test('Generate key store from json', () {
        String json = keyStore.toJson();
        KeyStore generatedKeyStore = KeyStore.fromJson(json);
        expect(generatedKeyStore, isA<KeyStore>());
        expect(generatedKeyStore.seed, keyStore.seed);
        expect(generatedKeyStore.extendedPublicKey.serialize(),
            keyStore.extendedPublicKey.serialize());
        expect(generatedKeyStore.masterFingerprint, keyStore.masterFingerprint);
      });
    });
    group('toString', () {
      test('Generate to String', () {
        expect(keyStore.toString().hashCode, 1018029796);
      });
    });
    group('operator ==', () {
      test('Check equal', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        SingleSignatureWallet wallet =
            SingleSignatureWallet.fromDescriptor(vault.descriptor);

        expect(wallet.keyStore == vault.keyStore, false);
        expect(wallet.keyStore.extendedPublicKey.serialize(),
            vault.keyStore.extendedPublicKey.serialize());
      });

      test('Check unequal', () {
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();
        expect(keyStore == vault.keyStore, false);
      });
    });
    group('get hashCode', () {
      test('Hash code test', () {
        expect(keyStore.hashCode, 128267478);
      });
    });
  });
}
