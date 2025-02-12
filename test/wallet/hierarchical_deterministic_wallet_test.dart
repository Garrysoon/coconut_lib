@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';
import 'package:test/test.dart';

void main() {
  group('HDWallet', () {
    late HDWallet hdWallet;
    setUpAll(() {
      Uint8List privateKey = Converter.hexToBytes(
          '6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41');
      Uint8List chainCode = Converter.hexToBytes(
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
      test('Get signature', () {
        String hex = Hash.sha256("Message");
        expect(Converter.bytesToHex(hdWallet.sign(Converter.hexToBytes(hex))),
            'ea10cba17d4603d90deeb5bee645ac362d2e88da75aff555a66db12df132939b73c0e4d7e78ae921fc3e929cec58b70fed71166618bea91c81c64df652dac028');
      });
    });
    group('verify', () {
      test('Verify success', () {
        String hex = Hash.sha256("Message");
        expect(
            hdWallet.verify(
                Converter.hexToBytes(hex),
                Converter.hexToBytes(
                    'ea10cba17d4603d90deeb5bee645ac362d2e88da75aff555a66db12df132939b73c0e4d7e78ae921fc3e929cec58b70fed71166618bea91c81c64df652dac028')),
            true);
      });
      test('Verify failed', () {
        String hex = Hash.sha256("Message");
        expect(
            hdWallet.verify(
                Converter.hexToBytes(hex),
                Converter.hexToBytes(
                    'ea10cba17d4603d90deeb5bee645ac362d2e88da75aff555a66db12df132939b73c0e4d7e78ae921fc3e929cec58b70fed71166618bea91c81c64df652dac027')),
            false);
      });
    });

    group('HDWallet.fromPublicKey', () {
      test('Generate HDWallet from public key', () {
        Uint8List publicKey = Converter.hexToBytes(
            '03f8f8a1412b9e56dd9576f49ae0a6499757ea592bd491f910c8f519ef0ea7cf3c');
        Uint8List chainCode = Converter.hexToBytes(
            '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
        expect(
            Converter.bytesToHex(
                HDWallet.fromPublicKey(publicKey, chainCode).fingerprint),
            'a56d9844');
      });
    });
    group('HDWallet.fromPrivateKey', () {
      test('Generate HDwallet from private key', () {
        Uint8List privateKey = Converter.hexToBytes(
            '6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41');
        Uint8List chainCode = Converter.hexToBytes(
            '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
        HDWallet.fromPrivateKey(privateKey, chainCode);
        expect(
            Converter.bytesToHex(
                HDWallet.fromPrivateKey(privateKey, chainCode).fingerprint),
            'a56d9844');
      });

      test('Private key length exception', () {
        Uint8List privateKey = Converter.hexToBytes(
            '6a8c473974ffabbf2bac36adadd328baabf8b6d7a269b69bb808d80d64f17f41');
        List<int> removedList = privateKey.toList();
        removedList.removeLast();
        Uint8List removedPrivateKey = Uint8List.fromList(removedList);
        Uint8List chainCode = Converter.hexToBytes(
            '4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b');
        expect(() => HDWallet.fromPrivateKey(removedPrivateKey, chainCode),
            throwsException);
      });
    });
    group('HDWallet.fromRootSeed', () {
      test('Generate HDwallet from root seed', () {
        String rootSeed =
            'ae6a87214c18fb91824b34b4e027f46d51061fdece2b3042ca51bf9b80f5d075fddb304fd9857ff1e147f9d0147bdc3116572657d9e2232540e6fc962a11a254';
        expect(
            Converter.bytesToHex(HDWallet.fromRootSeed(rootSeed).fingerprint),
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
        expect(Converter.bytesToHex(target.fingerprint), 'a56d9844');
      });
      test('Generate HDwallet with public key from json', () {
        String json =
            '''{"publicKey":"03f8f8a1412b9e56dd9576f49ae0a6499757ea592bd491f910c8f519ef0ea7cf3c","chainCode":"4cfac59caf9be1428410291697177b2efc8373a29f7ad4a34694163686a4d20b"}''';
        HDWallet target = HDWallet.fromJson(json);
        expect(Converter.bytesToHex(target.fingerprint), 'a56d9844');
      });
    });
  });
}
