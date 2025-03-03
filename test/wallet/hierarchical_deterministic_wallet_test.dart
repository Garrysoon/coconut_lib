@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';
import 'package:test/test.dart';

void main() {
  group('HDWallet', () {
    late HDWallet hdWallet;
    setUpAll(() {
      Uint8List privateKey = Encoder.decodeHex(
          '6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41');
      Uint8List chainCode = Encoder.decodeHex(
          '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
      hdWallet = HDWallet.fromPrivateKey(privateKey, chainCode);
    });
    group('neutered', () {
      test('Check neutered', () {
        expect(hdWallet.neutered().isNeutered(), true);
      });
    });
    group('toBase58', () {
      test('Get base58 key', () {
        expect(hdWallet.toBase58(AddressType.p2wpkh.versionForMainnet),
            'zpub6jftahH18ngZwuGabgXECcQVvPVjLqpLALZsyK3Gexy7iYxePR2NdHwkdDFeagvzZzRLXhj8bMwrwZdTDNxtVgzt6jhEBCyoSbDx5tZffFh');
        expect(
            hdWallet.neutered().toBase58(AddressType.p2wpkh.versionForMainnet),
            'zpub6jftahH18ngZwuGabgXECcQVvPVjLqpLALZsyK3Gexy7iYxePR2NdHwkdLAc81Q2icgnPBPhYf33M1gQf1XqeDX3vR25MPf7LMjbf9F3aX8');
      });
    });
    group('getMasterPrivateKey', () {
      test('Get WIF master private key', () {
        expect(
            () => hdWallet.neutered().getMasterPrivateKey(), throwsException);
        expect(hdWallet.getMasterPrivateKey(),
            '3uNnGw4JgsA7hujrSBWqqXCWYQigfK22MSbeoHg6zniQP9J');
      });
    });
    group('derive', () {
      test('Derive path', () {
        expect(hdWallet.derive(1).getMasterPrivateKey(),
            '3ua7HWmDyPmia6kvJuDdwd2wTAnpA1os4uH5MgiVP1zuK6g');
      });
    });
    group('deriveHardened', () {
      test('Derive Hardened without private key exception', () {
        expect(() => hdWallet.neutered().deriveHardened(1), throwsException);
      });
      test('Derive Hardened', () {
        expect(hdWallet.deriveHardened(1).getMasterPrivateKey(),
            '3uR1RgfpE7B7TmV32C2M2Cy4yQg32op9NUQH37A4cxCxQkY');
      });
    });
    group('derivePath', () {
      test('Invalid path exception', () {
        expect(() => hdWallet.derivePath("/0/0/1"), throwsException);
      });
      test('Derive from child exception', () {
        expect(() => hdWallet.derive(1).derivePath("m/84'/1'/0'"),
            throwsException);
      });
      test('Derive from child', () {
        Seed seed = Seed.fromMnemonic(
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about");
        HDWallet rootWallet = HDWallet.fromRootSeed(seed.rootSeed);
        expect(rootWallet.derivePath("m/84'/1'/0'/1").getMasterPrivateKey(),
            '3twVhJJ3ecUjpz9uQk3wbQ6mU5MBMkWxxRXrsJSvRpvh5cL');
      });
    });
    group('sign', () {
      test('Get signature with ecdsa', () {
        String hex = Hash.sha256("Message");
        expect(Encoder.encodeHex(hdWallet.sign(Encoder.decodeHex(hex))),
            'ea10cba17d4603d90deeb5bee645ac362d2e88da75aff555a66db12df132939b73c0e4d7e78ae921fc3e929cec58b70fed71166618bea91c81c64df652dac028');
      });
      //Test vector from : https://github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
      test('Get signature with schnorr', () {
        //TODO : Check this test
        //secret key = 'C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9'
        //public key = 'DD308AFEC5777E13121FA72B9CC1B7CC0139715309B086C960E18FD969774EB8'
        //random = 'C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906'
        //message = '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C'
        //signature = '5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7'
        // Uint8List internalPrivateKey = Encoder.decodeHex(
        //     'C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9');
        // Uint8List hash = Encoder.decodeHex(
        //     '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C');
        // Uint8List rand = Encoder.decodeHex(
        //     'C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906');
        // HDWallet hdWallet =
        //     HDWallet(internalPrivateKey, null, Uint8List.fromList([]));
        // // print(Encoder.encodeHex(hdWallet.publicKey));
        // Uint8List signature =
        //     hdWallet.sign(hash, isShnorr: true, auxRand: rand);
        // expect(Encoder.encodeHex(signature),
        //     '5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7');
      });
      test('Get signature with schnorr (case 2 : negate)', () {
        //TODO : Check this test
        //secret key = '0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710'
        //public key = '25D1DFF95105F5253C4022F628A996AD3A0D95FBF21D468A1B33F8C160D8F517' //odd public key
        //random = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
        //message = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
        //signature = '7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3'

        // Uint8List internalPrivateKey = Encoder.decodeHex(
        //     '0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710');
        // Uint8List hash = Encoder.decodeHex(
        //     'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
        // Uint8List rand = Encoder.decodeHex(
        //     'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
        // HDWallet hdWallet =
        //     HDWallet(internalPrivateKey, null, Uint8List.fromList([]));
        // Uint8List signature =
        //     hdWallet.sign(hash, isShnorr: true, auxRand: rand);
      });
    });
    group('getTweakedPrivateKey', () {
      // Test vector from : https://github.com/bitcoin/bips/blob/master/bip-0341/wallet-test-vectors.json
      //TODO: check this test (not work)
      test('Get tweak private key (case 1 : only private key)', () {
        // Uint8List matcherTweakPrivateKey = Encoder.decodeHex(
        //     '2405b971772ad26915c8dcdf10f238753a9b837e5f8e6a86fd7c0cce5b7296d9');
        // Uint8List internalPrivKey = Encoder.decodeHex(
        //     '6b973d88838f27366ed61c9ad6367663045cb456e28335c109e30717ae0c6baa');
        // HDWallet hdWallet =
        //     HDWallet(internalPrivKey, null, Uint8List.fromList([]));
        // expect(hdWallet.getTweakedPrivateKey(), matcherTweakPrivateKey);
      });
      //TODO: check this test (not work)
      test('Get tweak private key (case 2 : with merkle root)', () {
        // Uint8List matcherTweakPrivateKey = Encoder.decodeHex(
        //     'ea260c3b10e60f6de018455cd0278f2f5b7e454be1999572789e6a9565d26080');
        // Uint8List internalPrivKey = Encoder.decodeHex(
        //     '1e4da49f6aaf4e5cd175fe08a32bb5cb4863d963921255f33d3bc31e1343907f');
        // Uint8List merkelRoot = Encoder.decodeHex(
        //     '5b75adecf53548f3ec6ad7d78383bf84cc57b55a3127c72b9a2481752dd88b21');
        // HDWallet hdWallet =
        //     HDWallet(internalPrivKey, null, Uint8List.fromList([]));
        // expect(hdWallet.getTweakedPrivateKey(merkleRoot: merkelRoot),
        //     matcherTweakPrivateKey);
      });
      test('Get tweak private key (case 3 : negate)', () {
        Uint8List internalPrivKey = Encoder.decodeHex(
            'd3c7af07da2d54f7a7735d3d0fc4f0a73164db638b2f2f7c43f711f6d4aa7e64');
        Uint8List merkelRoot = Encoder.decodeHex(
            'c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b');
        HDWallet hdWallet =
            HDWallet(internalPrivKey, null, Uint8List.fromList([]));
        Uint8List matcherTweakPrivateKey = Encoder.decodeHex(
            '97323385e57015b75b0339a549c56a948eb961555973f0951f555ae6039ef00d');
        Uint8List targetTweakPrivateKey =
            hdWallet.getTweakedPrivateKey(merkleRoot: merkelRoot);
        expect(targetTweakPrivateKey, matcherTweakPrivateKey);
      });
      test('Get tweak private key (case 4)', () {
        Uint8List matcherTweakPrivateKey = Encoder.decodeHex(
            'a8e7aa924f0d58854185a490e6c41f6efb7b675c0f3331b7f14b549400b4d501');
        Uint8List internalPrivKey = Encoder.decodeHex(
            'f36bb07a11e469ce941d16b63b11b9b9120a84d9d87cff2c84a8d4affb438f4e');
        Uint8List merkelRoot = Encoder.decodeHex(
            'ccbd66c6f7e8fdab47b3a486f59d28262be857f30d4773f2d5ea47f7761ce0e2');
        HDWallet hdWallet =
            HDWallet(internalPrivKey, null, Uint8List.fromList([]));
        expect(hdWallet.getTweakedPrivateKey(merkleRoot: merkelRoot),
            matcherTweakPrivateKey);
      });
    });
    group('getTweakedPublicKey', () {
      //Test vector from : https://github.com/bitcoin/bips/blob/master/bip-0341/wallet-test-vectors.json
      test('Get tweak public key (case 1 : normal)', () {
        String internalPubKey =
            '02d6889cb081036e0faefa3a35157ad71086b123b2b144b649798b494c300a961d';
        String matcherTweakPublicKey =
            '53a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343';

        HDWallet hdWallet = HDWallet(
            null, Encoder.decodeHex(internalPubKey), Uint8List.fromList([]));
        expect(hdWallet.getTweakedPublicKey(),
            Encoder.decodeHex(matcherTweakPublicKey));
      });
      test('Get tweak public key (case 2 : negate & merkleRoot)', () {
        String internalPubKey =
            '0393478e9488f956df2396be2ce6c5cced75f900dfa18e7dabd2428aae78451820';
        String matcherTweakPublicKey =
            'e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e';
        String merkelRoot =
            'c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b';

        HDWallet hdWallet = HDWallet(
            null, Encoder.decodeHex(internalPubKey), Uint8List.fromList([]));

        expect(
            hdWallet.getTweakedPublicKey(
                merkleRoot: Encoder.decodeHex(merkelRoot)),
            Encoder.decodeHex(matcherTweakPublicKey));
      });
    });
    group('verify', () {
      test('Verify success', () {
        String hex = Hash.sha256("Message");
        expect(
            hdWallet.verify(
                Encoder.decodeHex(hex),
                Encoder.decodeHex(
                    'ea10cba17d4603d90deeb5bee645ac362d2e88da75aff555a66db12df132939b73c0e4d7e78ae921fc3e929cec58b70fed71166618bea91c81c64df652dac028')),
            true);
      });
      test('Verify failed', () {
        String hex = Hash.sha256("Message");
        expect(
            hdWallet.verify(
                Encoder.decodeHex(hex),
                Encoder.decodeHex(
                    'ea10cba17d4603d90deeb5bee645ac362d2e88da75aff555a66db12df132939b73c0e4d7e78ae921fc3e929cec58b70fed71166618bea91c81c64df652dac027')),
            false);
      });

      //Test vector from https://github.com/bitcoin/bips/blob/master/bip-0341/wallet-test-vectors.json
      test('Verify schnorr signature (bip341 - lline 276)', () {
        String internalPrivateKey =
            '6b973d88838f27366ed61c9ad6367663045cb456e28335c109e30717ae0c6baa';
        String tweakedPrivateKey =
            '2405b971772ad26915c8dcdf10f238753a9b837e5f8e6a86fd7c0cce5b7296d9';
        Uint8List sigHash = Encoder.decodeHex(
            '2514a6272f85cfa0f45eb907fcb0d121b808ed37c6ea160a5a9046ed5526d555');
        Uint8List signature = Encoder.decodeHex(
            'ed7c1647cb97379e76892be0cacff57ec4a7102aa24296ca39af7541246d8ff14d38958d4cc1e2e478e4d4a764bbfd835b16d4e314b72937b29833060b87276c');

        HDWallet hdWallet =
            HDWallet(Encoder.decodeHex(internalPrivateKey), null, Uint8List(0));
        // expect(Encoder.encodeHex(hdWallet.getTweakedPrivateKey()),
        //     tweakedPrivateKey);
        expect(hdWallet.verify(sigHash, signature, isSchnorr: true), isTrue);
      });
      test('Verify schnorr signature (bip341 - lline 302)', () {
        String internalPrivateKey =
            '1e4da49f6aaf4e5cd175fe08a32bb5cb4863d963921255f33d3bc31e1343907f';
        Uint8List merkleRoot = Encoder.decodeHex(
            "5b75adecf53548f3ec6ad7d78383bf84cc57b55a3127c72b9a2481752dd88b21");
        String tweakedPrivateKey =
            'ea260c3b10e60f6de018455cd0278f2f5b7e454be1999572789e6a9565d26080';
        Uint8List sigHash = Encoder.decodeHex(
            '325a644af47e8a5a2591cda0ab0723978537318f10e6a63d4eed783b96a71a4d');
        Uint8List signature = Encoder.decodeHex(
            '052aedffc554b41f52b521071793a6b88d6dbca9dba94cf34c83696de0c1ec35ca9c5ed4ab28059bd606a4f3a657eec0bb96661d42921b5f50a95ad33675b54f');

        HDWallet hdWallet =
            HDWallet(Encoder.decodeHex(internalPrivateKey), null, Uint8List(0));
        // expect(
        //     Encoder.encodeHex(
        //         hdWallet.getTweakedPrivateKey(merkleRoot: merkleRoot)),
        //     tweakedPrivateKey);
        expect(
            hdWallet.verify(sigHash, signature,
                isSchnorr: true, merkleRoot: merkleRoot),
            isTrue);
      });
      test('Verify schnorr signature (bip341 - lline 323)', () {
        String internalPrivateKey =
            'd3c7af07da2d54f7a7735d3d0fc4f0a73164db638b2f2f7c43f711f6d4aa7e64';
        Uint8List merkleRoot = Encoder.decodeHex(
            "c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b");
        String tweakedPrivateKey =
            '97323385e57015b75b0339a549c56a948eb961555973f0951f555ae6039ef00d';
        Uint8List sigHash = Encoder.decodeHex(
            'bf013ea93474aa67815b1b6cc441d23b64fa310911d991e713cd34c7f5d46669');
        Uint8List signature = Encoder.decodeHex(
            'ff45f742a876139946a149ab4d9185574b98dc919d2eb6754f8abaa59d18b025637a3aa043b91817739554f4ed2026cf8022dbd83e351ce1fabc272841d2510a');

        HDWallet hdWallet =
            HDWallet(Encoder.decodeHex(internalPrivateKey), null, Uint8List(0));
        expect(
            Encoder.encodeHex(
                hdWallet.getTweakedPrivateKey(merkleRoot: merkleRoot)),
            tweakedPrivateKey);
        expect(
            hdWallet.verify(sigHash, signature,
                isSchnorr: true, merkleRoot: merkleRoot),
            isTrue);
      });
      test('Verify schnorr signature (bip341 - lline 350)', () {
        String internalPrivateKey =
            'f36bb07a11e469ce941d16b63b11b9b9120a84d9d87cff2c84a8d4affb438f4e';
        Uint8List merkleRoot = Encoder.decodeHex(
            "ccbd66c6f7e8fdab47b3a486f59d28262be857f30d4773f2d5ea47f7761ce0e2");
        String tweakedPrivateKey =
            'a8e7aa924f0d58854185a490e6c41f6efb7b675c0f3331b7f14b549400b4d501';
        Uint8List sigHash = Encoder.decodeHex(
            '4f900a0bae3f1446fd48490c2958b5a023228f01661cda3496a11da502a7f7ef');
        Uint8List signature = Encoder.decodeHex(
            'b4010dd48a617db09926f729e79c33ae0b4e94b79f04a1ae93ede6315eb3669de185a17d2b0ac9ee09fd4c64b678a0b61a0a86fa888a273c8511be83bfd6810f');

        HDWallet hdWallet =
            HDWallet(Encoder.decodeHex(internalPrivateKey), null, Uint8List(0));
        expect(
            Encoder.encodeHex(
                hdWallet.getTweakedPrivateKey(merkleRoot: merkleRoot)),
            tweakedPrivateKey);
        expect(
            hdWallet.verify(sigHash, signature,
                isSchnorr: true, merkleRoot: merkleRoot),
            isTrue);
      });
    });

    group('HDWallet.fromPublicKey', () {
      test('Generate HDWallet from public key', () {
        Uint8List publicKey = Encoder.decodeHex(
            '03f8f8a1412b9e56dd9576f49ae0a6499757ea592bd491f910c8f519ef0ea7cf3c');
        Uint8List chainCode = Encoder.decodeHex(
            '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
        expect(
            Encoder.encodeHex(
                HDWallet.fromPublicKey(publicKey, chainCode).fingerprint),
            'a56d9844');
      });
    });
    group('HDWallet.fromPrivateKey', () {
      test('Generate HDwallet from private key', () {
        Uint8List privateKey = Encoder.decodeHex(
            '6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41');
        Uint8List chainCode = Encoder.decodeHex(
            '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
        HDWallet.fromPrivateKey(privateKey, chainCode);
        expect(
            Encoder.encodeHex(
                HDWallet.fromPrivateKey(privateKey, chainCode).fingerprint),
            'a56d9844');
      });

      test('Private key length exception', () {
        Uint8List privateKey = Encoder.decodeHex(
            '6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41');
        List<int> removedList = privateKey.toList();
        removedList.removeLast();
        Uint8List removedPrivateKey = Uint8List.fromList(removedList);
        Uint8List chainCode = Encoder.decodeHex(
            '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
        expect(() => HDWallet.fromPrivateKey(removedPrivateKey, chainCode),
            throwsException);
      });
    });
    group('HDWallet.fromRootSeed', () {
      test('Generate HDwallet from root seed', () {
        String rootSeed =
            'ae6a87214c18fb91824b34b4e027f46d51061fdece2b3042ca51bf9b80f5d075fddb304fd9857ff1e147f9d0147bdc3116572657d9e2232540e6fc962a11a254';
        expect(Encoder.encodeHex(HDWallet.fromRootSeed(rootSeed).fingerprint),
            '98c7d774');
      });
      test('Too long Root seed length exception', () {
        String rootSeed =
            'ae6a87214c18fb91824b34b4e027f46d51061fdece2b3042ca51bf9b80f5d075fddb304fd9857ff1e147f9d0147bdc3116572657d9e2232540e6fc962a11a2525';
        expect(() => HDWallet.fromRootSeed(rootSeed), throwsException);
      });

      test('Too short Root seed length exception', () {
        String rootSeed = 'ae6a87214c18';
        expect(() => HDWallet.fromRootSeed(rootSeed), throwsException);
      });
    });
    group('toJson', () {
      test('Generate Json with private key', () {
        HDWallet target = HDWallet.fromJson(hdWallet.toJson());
        expect(hdWallet.fingerprint, target.fingerprint);
        expect(hdWallet.chainCode, target.chainCode);
        expect(hdWallet.privateKey, target.privateKey);
        expect(hdWallet.publicKey, target.publicKey);
      });
      test('Generate Json with public key', () {
        HDWallet target = HDWallet.fromJson(hdWallet.neutered().toJson());
        expect(hdWallet.neutered().fingerprint, target.fingerprint);
        expect(hdWallet.neutered().chainCode, target.chainCode);
        expect(hdWallet.neutered().publicKey, target.publicKey);
      });
    });
    group('HDWallet.fromJson', () {
      test('Generate HDwallet with private key from json', () {
        String json =
            '''{"privateKey":"6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41","publicKey":"03f8f8a1412b9e56dd9576f49ae0a6499757ea592bd491f910c8f519ef0ea7cf3c","chainCode":"4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b"}''';
        HDWallet target = HDWallet.fromJson(json);
        expect(Encoder.encodeHex(target.fingerprint), 'a56d9844');
      });
      test('Generate HDwallet with public key from json', () {
        String json =
            '''{"publicKey":"03f8f8a1412b9e56dd9576f49ae0a6499757ea592bd491f910c8f519ef0ea7cf3c","chainCode":"4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b"}''';
        HDWallet target = HDWallet.fromJson(json);
        expect(Encoder.encodeHex(target.fingerprint), 'a56d9844');
      });
    });
  });
}
