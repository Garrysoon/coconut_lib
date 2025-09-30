@Tags(['unit'])
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('KeyStore', () {
    late Seed seed;
    late KeyStore keyStore;
    setUpAll(() async {
      seed = Seed.fromMnemonic(utf8.encode(
          "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"));
      keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh);
    });
    group('KeyStore.fromSeed', () {
      test('Generate key store from seed', () {
        expect(keyStore, isA<KeyStore>());
        expect(keyStore.seed, seed);
        expect(keyStore.extendedPublicKey.serialize(),
            'vpub5Y6cjg78GGuNLsaPhmYsiw4gYX3HoQiRBiSwDaBXKUafCt9bNwWQiitDk5VZ5BVxYnQdwoTyXSs2JHRPAgjAvtbBrf8ZhDYe2jWAqvZVnsc');
      });
      test('Generate key store from seed with passphrase', () {
        Seed seedWithPassphrase = Seed.fromMnemonic(
            utf8.encode(
                "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"),
            passphrase: utf8.encode('passphrase'));
        KeyStore keyStoreWithPassphrase =
            KeyStore.fromSeed(seedWithPassphrase, AddressType.p2wpkh);
        expect(keyStoreWithPassphrase.seed, seedWithPassphrase);
        expect(keyStoreWithPassphrase.extendedPublicKey.serialize(),
            'vpub5ZKwzd8dsRkgfWuhHHxC1gv8KqJSGks821gx5sKBVAHco8TccsdMh6X4jiWjeTGW4SpkK77dP3HPEpZjgxzpGGq1G53NU7ftHhRfbijqxvf');
      });
    });
    group('KeyStore.fromMnemonic', () {
      test('Generate key store with mnemonic', () {
        KeyStore keyStore = KeyStore.fromMnemonic(
            utf8.encode(
                "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"),
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
        NetworkType.setNetworkType(NetworkType.mainnet);
        KeyStore keyStore = KeyStore.fromEntropy(
            Codec.decodeHex("00000000000000000000000000000000"),
            AddressType.p2wpkh);
        print(utf8.decode(keyStore.seed.mnemonic));
        expect(keyStore, isA<KeyStore>());
        expect(keyStore.extendedPublicKey.serialize(),
            'zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNfE3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs');
      });
    });
    group('KeyStore.fromExtendedPublicKey', () {
      test('Generate key store from extended public key', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        String exPub =
            'Vpub5n3ihNrEwZjBFZ32N6STEsMaUPAJ42pjoVMgbZUAuPbuubQR5eDXUyB8nw6ASMmzpM4PjyVsx6BHGhZwufeyVzCHxwLcXW5RoQ5feCiE6Qm';
        KeyStore keyStore = KeyStore.fromExtendedPublicKey(exPub, 'ae2e1224');
        expect(keyStore.extendedPublicKey.serialize(), exPub);
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
            utf8.encode(
                "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"),
            addressType: AddressType.p2trKeyPathSpending);
        expect(
            vault.keyStore.getPublicKey(0,
                isChange: false, applyTweak: true, isXOnly: true),
            'a60869f0dbcf1dc659c9cecbaf8050135ea9e8cdc487053f1dc6880949dc684c');
      });
    });

    group('hasPublicKeyInPsbt', () {
      test('Check sign possibility with wrong key store', () {
        Psbt psbt = MockFactory.createP2wpkhUnsignedPsbt();
        expect(keyStore.hasPublicKeyInPsbt(psbt.serialize()), false);
      });
      test('Check sign possibility with right key store', () {
        Psbt psbt = MockFactory.createP2wpkhUnsignedPsbt();

        expect(
            MockFactory.createP2wpkhVault()
                .keyStore
                .hasPublicKeyInPsbt(psbt.serialize()),
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

        expect(signedPsbtText.hashCode, 21710574);
      });
      test('Sign to PSBT (MuSig2)', () {
        String psbt =
            'cHNidP8BAIkCAAAAAe6MtxPAYSTxkQOQmRhczfCliWawRnEFLehdr+PMFTwVAAAAAAD/////AqCGAQAAAAAAIlEgDy036tJxPD6GiZvifcUpzL40adHBgOY4eyrwGwk7TwTWWfQFAAAAACJRIAMz3fdx21W1Qb1RXvGXvdTANUPPSPaDxxLZ5K55/Q17AAAAAE8BBDWHzwN0QKodgAAAAGSDetZp3KbsbOtiv7YRtD6HPVvk5bovKcMbkHJIWsKZA+Kr7P96Wz1xNDt2JeuvWywUCCquQV/xkPui3Hz313DvEBS3eQpWAACAAQAAgAAAAIBPAQQ1h88DAwXxBoAAAACQQH3tvyPzkLBzZQeBbW9osGa+dqHlRZOoeM0ok59/qQMocdeF8lzP1U+72HlL7FlwriXTmlwschGLye/KyK7NARA7YUJIVgAAgAEAAIAAAACATwEENYfPAxrzLCiAAAAAN1y5BnspfGLnG6LztYWO4/tMOc7M9op5FwhaafoIAnID93rLidjVZ3lta8YIbuzlWb9P/GjZ9SLw1OEMy3ObjNIQhAeQWVYAAIABAACAAAAAgAABASsA4fUFAAAAACJRIHyT+XJSTLrVaCEbaASn5MjVqnVC61RKzU+/iiiO+GUcAQMEAQAAACEWpJYFf53a8RWIlvqVDOakw/8fS96ON85wCC2acRsc5/sYFLd5ClYAAIABAACAAAAAgAAAAAAAAAAAIRYjsAvgs/sFvnqeKpFQTGvFh9ikYTainS7SoX44CWxoexg7YUJIVgAAgAEAAIAAAACAAAAAAAAAAAAhFjxxvrXu6a5nCdMdtmWZVqdXT4ldk06pIoBgyY/+qRoiGIQHkFlWAACAAQAAgAAAAIAAAAAAAAAAACEafJP5clJMutVoIRtoBKfkyNWqdULrVErNT7+KKI74ZRxgpJYFf53a8RWIlvqVDOakw/8fS96ON85wCC2acRsc5/sjsAvgs/sFvnqeKpFQTGvFh9ikYTainS7SoX44CWxoezxxvrXu6a5nCdMdtmWZVqdXT4ldk06pIoBgyY/+qRoiIRuklgV/ndrxFYiW+pUM5qTD/x9L3o43znAILZpxGxzn+0IDIXFcyRJHJnJwskEUxbA6ljUMXYDNcPJM1NePJKKxxtMD4VEhGYBJj7VyIxCS6PPXxngS7WMCKX7maZJ5JEObvy4hGyOwC+Cz+wW+ep4qkVBMa8WH2KRhNqKdLtKhfjgJbGh7QgLcg2852K2/525p/+iNi3wdVn13uM7FteftIU8ZuXLRBgM4Td0uBNE4OL/yDWE5K55VJ+wIRqo0W7BsrDHEf7GA6yEbPHG+te7prmcJ0x22ZZlWp1dPiV2TTqkigGDJj/6pGiJCAtxUK5Vtb5WdCqmVdSFpJL1pa5mybSkABYg6Y/mmvv0SAmlkplWrIxanjLjliOv2bEBwK5CyF0Vd1NFrZecSpwx0AAAiAgNfzZAGT7L554APmYWb7ldKsCVEMKC4mB0JoGm6RWS72RgUt3kKVgAAgAEAAIAAAACAAQAAAAAAAAAiAgKHOaCTQbZnKQlxga5nnfAEy7PSFpGUODCsNGuTRuEw7hg7YUJIVgAAgAEAAIAAAACAAQAAAAAAAAAiAgMPeM4eBC0IkxqSvm/AMtJBv1An+looIH/oCIxL4tYl7BiEB5BZVgAAgAEAAIAAAACAAQAAAAAAAAAA';
        KeyStore keyStore = KeyStore.fromSeed(
            Seed.fromEntropy(Hash.sha256('도이')), AddressType.p2trMuSig2);
        String signedPsbtText =
            keyStore.addSignatureToPsbt(psbt, AddressType.p2trMuSig2);
        Psbt signedPsbt = Psbt.parse(signedPsbtText);
        expect(signedPsbt.isSigned(keyStore), true);
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
        expect(keyStore.hashCode, 39299120);
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

  group('addMuSig2PublicNonceToPsbt', () {
    test('Add public nonce to PSBT', () {
      SingleSignatureVault vault =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      KeyStore keyStore =
          KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2trMuSig2);
      String psbtText =
          'cHNidP8BAIkCAAAAAfNQVSxA8DG4n4i3H1s1j2RJpIkpZ3X5bZoBEPlWLTo5AAAAAAD/////Apg6AAAAAAAAIlEgM6IxC1MyiIZ565iVprcpfW/ZRiBpXzirmL6xfIsXDRRqSgEAAAAAACJRIH8GqA0WxCZYjRtIb96vbTPQ02u79Shp5eMyw+OTL4HUAAAAAE8BBDWHzwNKf/0HgAAAAHQBq4/P5Lh6nth2zROUOhndNh8EzdvBdOz4Eb/nWLA2Ag0iw70nAucn8utVVikF4OVQ3EcLdxUezM+27Pw69mOPEJYUnjRWAACAAQAAgAAAAIBPAQQ1h88DluhlQIAAAAApQBEvlRdrJSrQlEQ5iMO4aTEhyzP+MWtPmUCwAYAv1AKipfmGJaMK++faV8gq1TnvoB5nqoScvv5kNikJqQHwpBA2CSPJVgAAgAEAAIAAAACATwEENYfPAyc4Kl+AAAAAJf4kPmAdg5vi1/dyXhLX5RThtuQd5T78uPOZU2UOlTYDBhSO9/+VK1RZuuNQEKFUwKRlcet3a5MJoCnLurUQp14Qm8nmW1YAAIABAACAAAAAgAABASughgEAAAAAACJRIETBi+hDIr0FF0Pp2sONipRy/B451m6jlR2kGXR6T5brAQMEAQAAACEWMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI8YlhSeNFYAAIABAACAAAAAgAAAAAAAAAAAIRY23196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJBg2CSPJVgAAgAEAAIAAAACAAAAAAAAAAAAhFunuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdGJvJ5ltWAACAAQAAgAAAAIAAAAAAAAAAACEaRMGL6EMivQUXQ+naw42KlHL8HjnWbqOVHaQZdHpPlutgMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI823196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJOnuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdAAAiAgM6ylrfcTDkOFTXsBCh+3J4BxAl++8cgHzKjcNU+y3jWBiWFJ40VgAAgAEAAIAAAACAAQAAAAEAAAAiAgJOno6t9nHmMxQ/iiZeJLzZVZOF5omBwtGpw5Y9kPxIdhg2CSPJVgAAgAEAAIAAAACAAQAAAAEAAAAiAgOncekf6Zdp960okZPS+O8Vn2HW6Zg6pR5dCrkeAFjdshibyeZbVgAAgAEAAIAAAACAAQAAAAEAAAAA';
      String targetPsbtText =
          'cHNidP8BAIkCAAAAAfNQVSxA8DG4n4i3H1s1j2RJpIkpZ3X5bZoBEPlWLTo5AAAAAAD/////Apg6AAAAAAAAIlEgM6IxC1MyiIZ565iVprcpfW/ZRiBpXzirmL6xfIsXDRRqSgEAAAAAACJRIH8GqA0WxCZYjRtIb96vbTPQ02u79Shp5eMyw+OTL4HUAAAAAE8BBDWHzwNKf/0HgAAAAHQBq4/P5Lh6nth2zROUOhndNh8EzdvBdOz4Eb/nWLA2Ag0iw70nAucn8utVVikF4OVQ3EcLdxUezM+27Pw69mOPEJYUnjRWAACAAQAAgAAAAIBPAQQ1h88DluhlQIAAAAApQBEvlRdrJSrQlEQ5iMO4aTEhyzP+MWtPmUCwAYAv1AKipfmGJaMK++faV8gq1TnvoB5nqoScvv5kNikJqQHwpBA2CSPJVgAAgAEAAIAAAACATwEENYfPAyc4Kl+AAAAAJf4kPmAdg5vi1/dyXhLX5RThtuQd5T78uPOZU2UOlTYDBhSO9/+VK1RZuuNQEKFUwKRlcet3a5MJoCnLurUQp14Qm8nmW1YAAIABAACAAAAAgAABASughgEAAAAAACJRIETBi+hDIr0FF0Pp2sONipRy/B451m6jlR2kGXR6T5brAQMEAQAAACEWMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI8YlhSeNFYAAIABAACAAAAAgAAAAAAAAAAAIRY23196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJBg2CSPJVgAAgAEAAIAAAACAAAAAAAAAAAAhFunuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdGJvJ5ltWAACAAQAAgAAAAIAAAAAAAAAAACEaRMGL6EMivQUXQ+naw42KlHL8HjnWbqOVHaQZdHpPlutgMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI823196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJOnuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdIRsxzVMWk6xvhF4ECvutAfwTgWhpQ21buqA2erw4CbiEj0ICMANfK4J0F3y/xjUyP75zeOza8eiSDiF6T0Nf0pSyeDMDtrOuvmi2WBIIT9aQ52l0MTd7YRWTzXHyLV7deu5K+/YAACICAzrKWt9xMOQ4VNewEKH7cngHECX77xyAfMqNw1T7LeNYGJYUnjRWAACAAQAAgAAAAIABAAAAAQAAACICAk6ejq32ceYzFD+KJl4kvNlVk4XmiYHC0anDlj2Q/Eh2GDYJI8lWAACAAQAAgAAAAIABAAAAAQAAACICA6dx6R/pl2n3rSiRk9L47xWfYdbpmDqlHl0KuR4AWN2yGJvJ5ltWAACAAQAAgAAAAIABAAAAAQAAAAA=';
      String nonceAddedPsbtText = keyStore.addMuSig2PublicNonceToPsbt(psbtText);
      expect(nonceAddedPsbtText, targetPsbtText);
    });
  });

  group('addMuSig2PublicNonceToPsbtInput', () {
    test('Add public nonce to PSBT input', () {
      SingleSignatureVault vault =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      KeyStore keyStore =
          KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2trMuSig2);
      String psbtText =
          'cHNidP8BAIkCAAAAAfNQVSxA8DG4n4i3H1s1j2RJpIkpZ3X5bZoBEPlWLTo5AAAAAAD/////Apg6AAAAAAAAIlEgM6IxC1MyiIZ565iVprcpfW/ZRiBpXzirmL6xfIsXDRRqSgEAAAAAACJRIH8GqA0WxCZYjRtIb96vbTPQ02u79Shp5eMyw+OTL4HUAAAAAE8BBDWHzwNKf/0HgAAAAHQBq4/P5Lh6nth2zROUOhndNh8EzdvBdOz4Eb/nWLA2Ag0iw70nAucn8utVVikF4OVQ3EcLdxUezM+27Pw69mOPEJYUnjRWAACAAQAAgAAAAIBPAQQ1h88DluhlQIAAAAApQBEvlRdrJSrQlEQ5iMO4aTEhyzP+MWtPmUCwAYAv1AKipfmGJaMK++faV8gq1TnvoB5nqoScvv5kNikJqQHwpBA2CSPJVgAAgAEAAIAAAACATwEENYfPAyc4Kl+AAAAAJf4kPmAdg5vi1/dyXhLX5RThtuQd5T78uPOZU2UOlTYDBhSO9/+VK1RZuuNQEKFUwKRlcet3a5MJoCnLurUQp14Qm8nmW1YAAIABAACAAAAAgAABASughgEAAAAAACJRIETBi+hDIr0FF0Pp2sONipRy/B451m6jlR2kGXR6T5brAQMEAQAAACEWMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI8YlhSeNFYAAIABAACAAAAAgAAAAAAAAAAAIRY23196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJBg2CSPJVgAAgAEAAIAAAACAAAAAAAAAAAAhFunuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdGJvJ5ltWAACAAQAAgAAAAIAAAAAAAAAAACEaRMGL6EMivQUXQ+naw42KlHL8HjnWbqOVHaQZdHpPlutgMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI823196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJOnuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdAAAiAgM6ylrfcTDkOFTXsBCh+3J4BxAl++8cgHzKjcNU+y3jWBiWFJ40VgAAgAEAAIAAAACAAQAAAAEAAAAiAgJOno6t9nHmMxQ/iiZeJLzZVZOF5omBwtGpw5Y9kPxIdhg2CSPJVgAAgAEAAIAAAACAAQAAAAEAAAAiAgOncekf6Zdp960okZPS+O8Vn2HW6Zg6pR5dCrkeAFjdshibyeZbVgAAgAEAAIAAAACAAQAAAAEAAAAA';
      String targetPsbtText =
          'cHNidP8BAIkCAAAAAfNQVSxA8DG4n4i3H1s1j2RJpIkpZ3X5bZoBEPlWLTo5AAAAAAD/////Apg6AAAAAAAAIlEgM6IxC1MyiIZ565iVprcpfW/ZRiBpXzirmL6xfIsXDRRqSgEAAAAAACJRIH8GqA0WxCZYjRtIb96vbTPQ02u79Shp5eMyw+OTL4HUAAAAAE8BBDWHzwNKf/0HgAAAAHQBq4/P5Lh6nth2zROUOhndNh8EzdvBdOz4Eb/nWLA2Ag0iw70nAucn8utVVikF4OVQ3EcLdxUezM+27Pw69mOPEJYUnjRWAACAAQAAgAAAAIBPAQQ1h88DluhlQIAAAAApQBEvlRdrJSrQlEQ5iMO4aTEhyzP+MWtPmUCwAYAv1AKipfmGJaMK++faV8gq1TnvoB5nqoScvv5kNikJqQHwpBA2CSPJVgAAgAEAAIAAAACATwEENYfPAyc4Kl+AAAAAJf4kPmAdg5vi1/dyXhLX5RThtuQd5T78uPOZU2UOlTYDBhSO9/+VK1RZuuNQEKFUwKRlcet3a5MJoCnLurUQp14Qm8nmW1YAAIABAACAAAAAgAABASughgEAAAAAACJRIETBi+hDIr0FF0Pp2sONipRy/B451m6jlR2kGXR6T5brAQMEAQAAACEWMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI8YlhSeNFYAAIABAACAAAAAgAAAAAAAAAAAIRY23196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJBg2CSPJVgAAgAEAAIAAAACAAAAAAAAAAAAhFunuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdGJvJ5ltWAACAAQAAgAAAAIAAAAAAAAAAACEaRMGL6EMivQUXQ+naw42KlHL8HjnWbqOVHaQZdHpPlutgMc1TFpOsb4ReBAr7rQH8E4FoaUNtW7qgNnq8OAm4hI823196wTkAvvP6l8ZhEDlzRK9SJQFjCnSQzYjpH/8eJOnuJnpL1dDfIcxkm92jdbtVENFz7UEnsV2pPwcXsfmdIRsxzVMWk6xvhF4ECvutAfwTgWhpQ21buqA2erw4CbiEj0ICMANfK4J0F3y/xjUyP75zeOza8eiSDiF6T0Nf0pSyeDMDtrOuvmi2WBIIT9aQ52l0MTd7YRWTzXHyLV7deu5K+/YAACICAzrKWt9xMOQ4VNewEKH7cngHECX77xyAfMqNw1T7LeNYGJYUnjRWAACAAQAAgAAAAIABAAAAAQAAACICAk6ejq32ceYzFD+KJl4kvNlVk4XmiYHC0anDlj2Q/Eh2GDYJI8lWAACAAQAAgAAAAIABAAAAAQAAACICA6dx6R/pl2n3rSiRk9L47xWfYdbpmDqlHl0KuR4AWN2yGJvJ5ltWAACAAQAAgAAAAIABAAAAAQAAAAA=';
      Psbt psbt = Psbt.parse(psbtText);
      keyStore.addMuSig2PublicNonceToPsbtInput(
          psbt.inputs[0],
          "m/86'/1'/0'/0/0",
          "d4e30f674d5fa34fd625fa30edb90d7463458a72532ff25f3a9857f85b20e1dc");
      expect(psbt.serialize(), targetPsbtText);
    });
  });
}
