@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

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
    group('KeyStore.fromExtendedPublicKey', () {
      test('Generate key store from extended public key', () {
        String exPub =
            'Vpub5n3ihNrEwZjBFZ32N6STEsMaUPAJ42pjoVMgbZUAuPbuubQR5eDXUyB8nw6ASMmzpM4PjyVsx6BHGhZwufeyVzCHxwLcXW5RoQ5feCiE6Qm';
        KeyStore keyStore = KeyStore.fromExtendedPublicKey(exPub);
        expect(keyStore.masterFingerprint, 'ae2e1224');
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
        // String privateKey = '3uhZVhK22HgcQQjun7Uysc2cTZGqLDuiSUXnJMUWtLQvo44';
        expect(keyStore.getPrivateKey(0),
            'a9c4134b73560f43fc5c081e5c1daa7ce068adc806d80e1f37cb658e0fea4c8d');
      });
      test('Get private key (change)', () {
        // String privateKey = '3uDFZxBEWBcRjAMMzjbSmXiX869rUg26FnYN22RxtsP8ojE';
        expect(keyStore.getPrivateKey(0, isChange: true),
            '4a78147e621966ebca7185d7567a5db3c91af2d45455dba8e350b34f66187d64');
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
      test('Get public key for schnorr', () {
        NetworkType.setNetworkType(NetworkType.mainnet);
        SingleSignatureVault vault = SingleSignatureVault.fromMnemonic(
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            addressType: AddressType.p2trKeyPathSpending);
        expect(
            vault.keyStore.getPublicKey(0,
                isChange: false, applyTweak: true, isXOnly: true),
            'a60869f0dbcf1dc659c9cecbaf8050135ea9e8cdc487053f1dc6880949dc684c');
      });
    });

    group('canSignToPsbt', () {
      test('Check sign possibility with wrong key store', () {
        Psbt psbt = MockFactory.createP2wpkhUnsignedPsbt();
        expect(keyStore.canSignToPsbt(psbt.serialize()), false);
      });
      test('Check sign possibility with right key store', () {
        Psbt psbt = MockFactory.createP2wpkhUnsignedPsbt();

        expect(
            MockFactory.createP2wpkhVault()
                .keyStore
                .canSignToPsbt(psbt.serialize()),
            true);
      });
    });
    group('addSignatureToPsbt', () {
      test('Sign to PSBT (single signature)', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        Psbt unsignedPsbt = MockFactory.createP2wpkhUnsignedPsbt();
        SingleSignatureVault vault = MockFactory.createP2wpkhVault();

        String signedPsbtText = vault.keyStore
            .addSignatureToPsbt(unsignedPsbt.serialize(), vault.addressType);
        expect(signedPsbtText.hashCode, 222298681);
      });
      test('Sign to PSBT (multisignature)', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        Psbt unsignedPsbt = MockFactory.createP2wshUnsignedPsbt();
        MultisignatureVault vault = MockFactory.createP2wshVault();
        String partialSignedPsbtText = vault.keyStoreList[0]
            .addSignatureToPsbt(unsignedPsbt.serialize(), vault.addressType);
        String signedPsbtText = vault.keyStoreList[1]
            .addSignatureToPsbt(partialSignedPsbtText, vault.addressType);

        print(signedPsbtText);
        expect(signedPsbtText.hashCode, 21710574);
      });
    });

    group('calculateSecretNonce', () {
      //Test vector from https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/nonce_gen_vectors.json
      test('Generate secret nonce (deterministic case)', () {
        Uint8List rand = Codec.decodeHex(
            '659da54c7b484598ba29fb2600b9e400a8e4536de1f69906fec3549156f4223f');
        Uint8List secretKey = Codec.decodeHex(
            '0202020202020202020202020202020202020202020202020202020202020202');
        Uint8List publicKey = Codec.decodeHex(
            "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766");
        Uint8List aggPubkey = Codec.decodeHex(
            "0707070707070707070707070707070707070707070707070707070707070707");
        Uint8List message = Codec.decodeHex(
            "0101010101010101010101010101010101010101010101010101010101010101");
        Uint8List extraInput = Codec.decodeHex(
            "0808080808080808080808080808080808080808080808080808080808080808");

        String secretNonce = Codec.encodeHex(KeyStore.calculateSecretNonce(
            rand, secretKey, publicKey, aggPubkey, message, extraInput));
        expect(secretNonce.toUpperCase(),
            'B114E502BEAA4E301DD08A50264172C84E41650E6CB726B410C0694D59EFFB6495B5CAF28D045B973D63E3C99A44B807BDE375FD6CB39E46DC4A511708D0E9D2024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');
      });

      test('Generate secret nonce (non deterministic case 1)', () {
        Uint8List rand = Codec.decodeHex(
            '0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F');
        Uint8List secretKey = Codec.decodeHex(
            '0202020202020202020202020202020202020202020202020202020202020202');
        Uint8List publicKey = Codec.decodeHex(
            "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766");
        Uint8List aggPubkey = Codec.decodeHex(
            "0707070707070707070707070707070707070707070707070707070707070707");
        Uint8List message = Codec.decodeHex(
            "0101010101010101010101010101010101010101010101010101010101010101");
        Uint8List extraInput = Codec.decodeHex(
            "0808080808080808080808080808080808080808080808080808080808080808");

        String secretNonce = Codec.encodeHex(KeyStore.calculateSecretNonce(
            rand, secretKey, publicKey, aggPubkey, message, extraInput,
            isDeterministic: false));
        expect(secretNonce.toUpperCase(),
            'B114E502BEAA4E301DD08A50264172C84E41650E6CB726B410C0694D59EFFB6495B5CAF28D045B973D63E3C99A44B807BDE375FD6CB39E46DC4A511708D0E9D2024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');
      });

      test('Generate secret nonce (non deterministic case 2)', () {
        Uint8List rand = Codec.decodeHex(
            '0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F');
        Uint8List secretKey = Codec.decodeHex(
            '0202020202020202020202020202020202020202020202020202020202020202');
        Uint8List publicKey = Codec.decodeHex(
            "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766");
        Uint8List aggPubkey = Codec.decodeHex(
            "0707070707070707070707070707070707070707070707070707070707070707");
        Uint8List message = Codec.decodeHex("");
        Uint8List extraInput = Codec.decodeHex(
            "0808080808080808080808080808080808080808080808080808080808080808");

        String secretNonce = Codec.encodeHex(KeyStore.calculateSecretNonce(
            rand, secretKey, publicKey, aggPubkey, message, extraInput,
            isDeterministic: false));
        expect(secretNonce.toUpperCase(),
            'E862B068500320088138468D47E0E6F147E01B6024244AE45EAC40ACE5929B9F0789E051170B9E705D0B9EB49049A323BBBBB206D8E05C19F46C6228742AA7A9024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');
      });
      test('Generate secret nonce (non deterministic case 3)', () {
        Uint8List rand = Codec.decodeHex(
            '0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F');
        Uint8List secretKey = Codec.decodeHex(
            '0202020202020202020202020202020202020202020202020202020202020202');
        Uint8List publicKey = Codec.decodeHex(
            "024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766");
        Uint8List aggPubkey = Codec.decodeHex(
            "0707070707070707070707070707070707070707070707070707070707070707");
        Uint8List message = Codec.decodeHex(
            "2626262626262626262626262626262626262626262626262626262626262626262626262626");
        Uint8List extraInput = Codec.decodeHex(
            "0808080808080808080808080808080808080808080808080808080808080808");

        String secretNonce = Codec.encodeHex(KeyStore.calculateSecretNonce(
            rand, secretKey, publicKey, aggPubkey, message, extraInput,
            isDeterministic: false));
        expect(secretNonce.toUpperCase(),
            '3221975ACBDEA6820EABF02A02B7F27D3A8EF68EE42787B88CBEFD9AA06AF3632EE85B1A61D8EF31126D4663A00DD96E9D1D4959E72D70FE5EBB6E7696EBA66F024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');
      });
      test('Generate secret nonce (for scenario test)', () {
        Uint8List rand =
            Codec.decodeHex('3acc65ba29db1bdfb9d0af9c87525ee5df2205ee');
        Uint8List secretKey = Codec.decodeHex(
            '53758e643751e3c23fd15b1c08a80179c8a6a78fed51c6e5961e2ea9d381925a');
        Uint8List publicKey = Codec.decodeHex(
            "0231cd531693ac6f845e040afbad01fc13816869436d5bbaa0367abc3809b8848f");
        Uint8List aggPubkey = Codec.decodeHex(
            "5c6bc6c83ac710fa23c806e3744d90cbd54899f38cfdb2f6310e9d664f79b5b9");
        Uint8List message = Codec.decodeHex(
            "90e6bcf20fccc52e974ecd7e9fa2b7e7af5832d9b8285078095b8b5dfb8d045c");
        Uint8List extraInput = Codec.decodeHex("");

        String secretNonce = Codec.encodeHex(KeyStore.calculateSecretNonce(
            rand, secretKey, publicKey, aggPubkey, message, extraInput,
            isDeterministic: false));
        expect(secretNonce,
            'c931cdfc4c763bfec9404394cac7a5fe73d5a1c0f7c0ba106d24d7c8c4a141e63a74c366130dba7e587d9ca78a116751b9c98beb2388e2db53ae083e436e2e5b0231cd531693ac6f845e040afbad01fc13816869436d5bbaa0367abc3809b8848f');
      });
    });

    group('calculatePublicNonce', () {
      //Test vector from https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/nonce_gen_vectors.json
      test('Generate public nonce (case 1)', () {
        Uint8List secretNonce = Codec.decodeHex(
            'B114E502BEAA4E301DD08A50264172C84E41650E6CB726B410C0694D59EFFB6495B5CAF28D045B973D63E3C99A44B807BDE375FD6CB39E46DC4A511708D0E9D2024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');

        String publicNonce =
            Codec.encodeHex(KeyStore.calculatePublicNonce(secretNonce));
        expect(publicNonce.toUpperCase(),
            '02F7BE7089E8376EB355272368766B17E88E7DB72047D05E56AA881EA52B3B35DF02C29C8046FDD0DED4C7E55869137200FBDBFE2EB654267B6D7013602CAED3115A');
      });
      test('Generate public nonce (case 2)', () {
        Uint8List secretNonce = Codec.decodeHex(
            'E862B068500320088138468D47E0E6F147E01B6024244AE45EAC40ACE5929B9F0789E051170B9E705D0B9EB49049A323BBBBB206D8E05C19F46C6228742AA7A9024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');

        String publicNonce =
            Codec.encodeHex(KeyStore.calculatePublicNonce(secretNonce));
        expect(publicNonce.toUpperCase(),
            '023034FA5E2679F01EE66E12225882A7A48CC66719B1B9D3B6C4DBD743EFEDA2C503F3FD6F01EB3A8E9CB315D73F1F3D287CAFBB44AB321153C6287F407600205109');
      });
      test('Generate public nonce (case 3)', () {
        Uint8List secretNonce = Codec.decodeHex(
            '3221975ACBDEA6820EABF02A02B7F27D3A8EF68EE42787B88CBEFD9AA06AF3632EE85B1A61D8EF31126D4663A00DD96E9D1D4959E72D70FE5EBB6E7696EBA66F024D4B6CD1361032CA9BD2AEB9D900AA4D45D9EAD80AC9423374C451A7254D0766');

        String publicNonce =
            Codec.encodeHex(KeyStore.calculatePublicNonce(secretNonce));
        expect(publicNonce.toUpperCase(),
            '02E5BBC21C69270F59BD634FCBFA281BE9D76601295345112C58954625BF23793A021307511C79F95D38ACACFF1B4DA98228B77E65AA216AD075E9673286EFB4EAF3');
      });
    });
    group('toJson', () {
      test('Generate json', () {
        expect(keyStore.toJson().hashCode, 301565750);
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

  group('MuSigSessionContext', () {
    group('getMuSig2PublicNonce', () {
      test('Generate session context', () {
        Uint8List message = Codec.decodeHex(
            '6701942fd0f38440a7c410a3fcf6a6e10bd76a4974c3b0a9553e60528c78a6b5');
        List<Uint8List> participantPublicKeys = [
          Codec.decodeHex(
              '0231cd531693ac6f845e040afbad01fc13816869436d5bbaa0367abc3809b8848f'),
          Codec.decodeHex(
              '0236df5f7ac13900bef3fa97c66110397344af522501630a7490cd88e91fff1e24'),
          Codec.decodeHex(
              '02e9ee267a4bd5d0df21cc649bdda375bb5510d173ed4127b15da93f0717b1f99d')
        ];
        Uint8List aggregatedPubNonce = Codec.decodeHex(
            '03ddffdfd8f613ca697f313579e80adbf34564fac6ce5808b6d0dde9d09327c1b002cfa39d381c6366ebdd7019641dba6dd453f9d38f56d38b0d7e33b51cfbfe95ef');
        MuSig2SessionContext sessionContext = MuSig2SessionContext(
            aggregatedPubNonce, participantPublicKeys, message);
        expect(Codec.encodeHex(Ecc.getEncoded(sessionContext.Q, true)),
            '0244c18be84322bd051743e9dac38d8a9472fc1e39d66ea3951da419747a4f96eb');
        expect(sessionContext.b.toString(),
            '42452304263695163620196203845095753431190306116738962141428713186034786858279');
        expect(sessionContext.R.x.toString(),
            '60143870298663942742991689092797257507829257715383491360440278844229307818615');
        expect(sessionContext.e.toString(),
            '75550762600552793952557687225983707197539317791023912703967559988774299150629');
      });
    });
  });
}
