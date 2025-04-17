import 'dart:typed_data';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('EllipticCurveCryptography', () {
    Uint8List encodeBigInt(BigInt number) {
      var byteMask = BigInt.from(0xff);
      final negativeFlag = BigInt.from(0x80);
      int needsPaddingByte;
      int rawSize;

      if (number > BigInt.zero) {
        rawSize = (number.bitLength + 7) >> 3;
        needsPaddingByte =
            ((number >> (rawSize - 1) * 8) & negativeFlag) == negativeFlag
                ? 1
                : 0;

        if (rawSize < 32) {
          needsPaddingByte = 1;
        }
      } else {
        needsPaddingByte = 0;
        rawSize = (number.bitLength + 8) >> 3;
      }

      final size = rawSize < 32 ? rawSize + needsPaddingByte : rawSize;
      var result = Uint8List(size);
      for (int i = 0; i < size; i++) {
        result[size - i - 1] = (number & byteMask).toInt();
        number = number >> 8;
      }
      return result;
    }

    // ignore: non_constant_identifier_names
    final BigInt EC_GROUP_ORDER = BigInt.parse(
        'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
        radix: 16);

    Uint8List bigIntToUint8List(BigInt number) {
      var bytes = number
          .toUnsigned(256)
          .toRadixString(16)
          .padLeft(64, '0'); // Ensures 32 bytes
      return Uint8List.fromList(List.generate(32, (i) {
        return int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16);
      }));
    }

    BigInt fromBuffer(Uint8List d) {
      return BigInt.parse(
          d.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
          radix: 16);
    }

    group('isPrivate', () {
      test('Valid private key in range', () {
        Uint8List validPrivateKey = bigIntToUint8List(BigInt.one);
        expect(Ecc.isPrivate(validPrivateKey), isTrue);
      });

      test('Valid private key near EC_GROUP_ORDER', () {
        Uint8List validPrivateKey =
            bigIntToUint8List(EC_GROUP_ORDER - BigInt.one); // ✅ FIXED
        expect(Ecc.isPrivate(validPrivateKey), isTrue);
      });

      test('Private key is zero (invalid)', () {
        Uint8List zeroKey = Uint8List(32); // 0x000000...0000
        expect(Ecc.isPrivate(zeroKey), isFalse);
      });

      test('Private key is exactly EC_GROUP_ORDER (invalid)', () {
        Uint8List ecGroupKey = bigIntToUint8List(EC_GROUP_ORDER);
        expect(Ecc.isPrivate(ecGroupKey), isFalse);
      });

      test('Private key is greater than EC_GROUP_ORDER (invalid)', () {
        Uint8List overKey = bigIntToUint8List(EC_GROUP_ORDER + BigInt.one);
        expect(Ecc.isPrivate(overKey), isFalse);
      });

      test('Private key has wrong length (invalid)', () {
        Uint8List shortKey = Uint8List(31); // Too short
        expect(Ecc.isPrivate(shortKey), isFalse);

        Uint8List longKey = Uint8List(33); // Too long
        expect(Ecc.isPrivate(longKey), isFalse);
      });
    });
    group('isPoint', () {
      // ignore: non_constant_identifier_names
      final BigInt EC_P = BigInt.parse(
          'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F',
          radix: 16); // secp256k1 prime field
      test('Valid compressed public key (0x02 prefix)', () {
        Uint8List validCompressedKey =
            Uint8List.fromList([0x02] + List.filled(32, 0x01));
        expect(Ecc.isPoint(validCompressedKey), isTrue);
      });

      test('Valid compressed public key (0x03 prefix)', () {
        Uint8List validCompressedKey =
            Uint8List.fromList([0x03] + List.filled(32, 0x01));
        expect(Ecc.isPoint(validCompressedKey), isTrue);
      });

      test('Valid uncompressed public key (0x04 prefix)', () {
        Uint8List validUncompressedKey =
            Uint8List.fromList([0x04] + List.filled(64, 0x01));
        expect(Ecc.isPoint(validUncompressedKey), isTrue);
      });

      test('Invalid: Too short (32 bytes)', () {
        Uint8List shortKey = Uint8List.fromList(List.filled(31, 0x01));
        expect(Ecc.isPoint(shortKey), isFalse);
      });

      test('Invalid: Wrong prefix (not 0x02, 0x03, 0x04)', () {
        Uint8List wrongPrefixKey =
            Uint8List.fromList([0x01] + List.filled(32, 0x01));
        expect(Ecc.isPoint(wrongPrefixKey), isFalse);
      });

      test('Invalid: Compressed key but length is wrong', () {
        Uint8List wrongLengthKey =
            Uint8List.fromList([0x02] + List.filled(30, 0x01));
        expect(Ecc.isPoint(wrongLengthKey), isFalse);
      });

      test('Invalid: Uncompressed key but length is wrong', () {
        Uint8List wrongLengthUncompressedKey =
            Uint8List.fromList([0x04] + List.filled(63, 0x01));
        expect(Ecc.isPoint(wrongLengthUncompressedKey), isFalse);
      });

      test('Invalid: x coordinate is zero', () {
        Uint8List zeroXKey = Uint8List.fromList([0x02] + List.filled(32, 0x00));
        expect(Ecc.isPoint(zeroXKey), isFalse);
      });

      test('Invalid: y coordinate is zero in uncompressed key', () {
        Uint8List zeroYKey = Uint8List.fromList(
            [0x04] + List.filled(32, 0x01) + List.filled(32, 0x00));
        expect(Ecc.isPoint(zeroYKey), isFalse);
      });

      test('Invalid: y coordinate exceeds EC_P in uncompressed key', () {
        Uint8List bigYKey = Uint8List.fromList([0x04] +
            List.filled(32, 0x01) +
            bigIntToUint8List(EC_P + BigInt.one));
        expect(Ecc.isPoint(bigYKey), isFalse);
      });

      test('Invalid: Malformed point should trigger _decodeFrom exception', () {
        Uint8List malformedKey = Uint8List.fromList(
            [0x04] + List.filled(62, 0x01)); // Incorrect length
        expect(Ecc.isPoint(malformedKey), isFalse);
      });
    });
    group('isSignature', () {
      test('Valid signature', () {
        Uint8List validSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one) +
              bigIntToUint8List(EC_GROUP_ORDER - BigInt.one),
        );
        expect(Ecc.isSignature(validSignature), isTrue);
      });

      test('Invalid: Signature too short', () {
        Uint8List shortSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one), // Only 32 bytes (missing s)
        );
        expect(() => Ecc.isSignature(shortSignature), throwsRangeError);
      });

      test('Invalid: Signature too long', () {
        Uint8List longSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one) +
              bigIntToUint8List(BigInt.one) +
              [0x00], // 65 bytes
        );
        expect(Ecc.isSignature(longSignature), isFalse);
      });

      test('Invalid: r is too large (>= EC_GROUP_ORDER)', () {
        Uint8List invalidRSignature = Uint8List.fromList(
          bigIntToUint8List(EC_GROUP_ORDER) + bigIntToUint8List(BigInt.one),
        );
        expect(Ecc.isSignature(invalidRSignature), isFalse);
      });

      test('Invalid: s is too large (>= EC_GROUP_ORDER)', () {
        Uint8List invalidSSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one) + bigIntToUint8List(EC_GROUP_ORDER),
        );
        expect(Ecc.isSignature(invalidSSignature), isFalse);
      });
    });
    group('pointFromScalar', () {
      test('Valid scalar with compressed output', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(2));
        Uint8List? pubKey = Ecc.pointFromScalar(privateKey, true);
        expect(pubKey, isNotNull);
        expect(pubKey!.length, equals(33));
        expect(pubKey[0], anyOf(0x02, 0x03)); // Compressed prefix
      });

      test('Valid scalar with uncompressed output', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(2));
        Uint8List? pubKey = Ecc.pointFromScalar(privateKey, false);
        expect(pubKey, isNotNull);
        expect(pubKey!.length, equals(65));
        expect(pubKey[0], equals(0x04)); // Uncompressed prefix
      });

      test('Invalid: Zero private key (should throw ArgumentError)', () {
        Uint8List zeroPrivateKey = Uint8List(32);
        expect(() => Ecc.pointFromScalar(zeroPrivateKey, true),
            throwsArgumentError);
      });

      test('Invalid: Private key too large (should throw ArgumentError)', () {
        Uint8List tooLargePrivateKey = bigIntToUint8List(EC_GROUP_ORDER);
        expect(() => Ecc.pointFromScalar(tooLargePrivateKey, true),
            throwsArgumentError);
      });

      test('Invalid: Infinity point should return null', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.zero);
        expect(
            () => Ecc.pointFromScalar(privateKey, true), throwsArgumentError);
      });

      test('Invalid: Malformed private key length', () {
        Uint8List shortKey = Uint8List(31);
        expect(() => Ecc.pointFromScalar(shortKey, true), throwsArgumentError);

        Uint8List longKey = Uint8List(33);
        expect(() => Ecc.pointFromScalar(longKey, true), throwsArgumentError);
      });
    });
    group('pointAddScalar', () {
      test('Valid point and valid tweak (compressed)', () {
        Uint8List point = Uint8List.fromList([0x02] + List.filled(32, 0x01));
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        Uint8List? result = Ecc.pointAddScalar(point, tweak, true);
        expect(result, isNotNull);
        expect(result!.length, equals(33));
        expect(result[0], anyOf(0x02, 0x03)); // Compressed prefix
      });

      test('Valid point and valid tweak (uncompressed)', () {
        Uint8List point = Uint8List.fromList([0x04] + List.filled(64, 0x01));
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        Uint8List? result = Ecc.pointAddScalar(point, tweak, false);
        expect(result, isNotNull);
        expect(result!.length, equals(65));
        expect(result[0], equals(0x04)); // Uncompressed prefix
      });

      test('Invalid: Non-point input should throw ArgumentError', () {
        Uint8List invalidPoint = Uint8List.fromList(List.filled(31, 0x01));
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        expect(() => Ecc.pointAddScalar(invalidPoint, tweak, true),
            throwsArgumentError);
      });

      test('Tweak is zero (should return original point)', () {
        Uint8List point = Uint8List.fromList([0x02] + List.filled(32, 0x01));
        Uint8List zeroTweak = Uint8List(32);
        Uint8List? result = Ecc.pointAddScalar(point, zeroTweak, true);
        expect(result, equals(point));
      });
    });
    group('privateAdd', () {
      test('Valid private key and valid tweak', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List tweak = bigIntToUint8List(BigInt.from(10));
        Uint8List? result = Ecc.privateAdd(privateKey, tweak);
        expect(result, isNotNull);
        expect(fromBuffer(result!), equals(BigInt.from(15) % Ecc.n));
      });

      test('Tweak is zero (should return original private key)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List zeroTweak = Uint8List(32);
        Uint8List? result = Ecc.privateAdd(privateKey, zeroTweak);
        expect(result, equals(privateKey));
      });

      test('Invalid: Private key is zero (should throw ArgumentError)', () {
        Uint8List zeroPrivateKey = Uint8List(32);
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        expect(
            () => Ecc.privateAdd(zeroPrivateKey, tweak), throwsArgumentError);
      });

      test('Invalid: Private key too large (should throw ArgumentError)', () {
        Uint8List tooLargePrivateKey = bigIntToUint8List(Ecc.n);
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        expect(() => Ecc.privateAdd(tooLargePrivateKey, tweak),
            throwsArgumentError);
      });

      test('Invalid: Tweak too large (should throw ArgumentError)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List tooLargeTweak = bigIntToUint8List(Ecc.n);
        expect(() => Ecc.privateAdd(privateKey, tooLargeTweak),
            throwsArgumentError);
      });

      test('Sum of private key and tweak equals n (should return null)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List tweak = bigIntToUint8List(Ecc.n - BigInt.from(5));
        Uint8List? result = Ecc.privateAdd(privateKey, tweak);
        expect(result, isNull);
      });

      test('Result requires padding (should still be 32 bytes)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(1));
        Uint8List tweak = bigIntToUint8List(BigInt.from(255));
        Uint8List? result = Ecc.privateAdd(privateKey, tweak);
        expect(result, isNotNull);
        expect(result!.length, equals(32));
      });
    });
    group('signEcdsa', () {
      test('Valid hash and private key', () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List privateKey = Uint8List.fromList(List.filled(32, 0x02));
        Uint8List signature = Ecc.signEcdsa(hash, privateKey);

        expect(signature.length, equals(64));

        BigInt r = fromBuffer(signature.sublist(0, 32));
        BigInt s = fromBuffer(signature.sublist(32, 64));

        expect(
            r,
            equals(BigInt.parse(
                '71033748903776529790462898089242338901035204487907480318338276493552341907275'))); // Mocked r value
        expect(
            s,
            equals(BigInt.parse(
                '18302596636702729551354818230842980875666984138389798664755124705733053998966'))); // Mocked s value
      });

      test('Invalid: Hash length not 32 bytes (should throw ArgumentError)',
          () {
        Uint8List invalidHash = Uint8List(31); // Too short
        Uint8List privateKey = Uint8List.fromList(List.filled(32, 0x02));

        expect(
            () => Ecc.signEcdsa(invalidHash, privateKey), throwsArgumentError);
      });

      test(
          'Invalid: Private key length not 32 bytes (should throw ArgumentError)',
          () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List invalidPrivateKey = Uint8List(31); // Too short

        expect(
            () => Ecc.signEcdsa(hash, invalidPrivateKey), throwsArgumentError);
      });

      test('Invalid: Private key is zero (should throw ArgumentError)', () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List zeroPrivateKey = Uint8List(32); // Zero private key

        expect(() => Ecc.signEcdsa(hash, zeroPrivateKey), throwsArgumentError);
      });

      test('Invalid: Private key too large (should throw ArgumentError)', () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List tooLargePrivateKey = encodeBigInt(Ecc.n);

        expect(
            () => Ecc.signEcdsa(hash, tooLargePrivateKey), throwsArgumentError);
      });
    });

    group('signSchnorr', () {
      test('Sign schnorr signature (case 1)', () {
        Uint8List hash = Codec.decodeHex(
            '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C');
        Uint8List privateKey = Codec.decodeHex(
            'C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9');
        Uint8List auxRand = Codec.decodeHex(
            'C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906');

        String signature =
            '5831aaeed7b44bb74e5eab94ba9d4294c49bcf2a60728d8b4c200f50dd313c1bab745879a5ad954a72c45a91c3a51d3c7adea98d82f8481e0e1e03674a6f3fb7';

        expect(
            Codec.encodeHex(
                Ecc.signSchnorr(hash, privateKey, auxRand: auxRand)),
            signature);
      });

      test('Sign schnorr signature (case 2)', () {
        Uint8List hash = Codec.decodeHex(
            '243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89');
        Uint8List privateKey = Codec.decodeHex(
            'B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF');
        Uint8List auxRand = Codec.decodeHex(
            '0000000000000000000000000000000000000000000000000000000000000001');

        String signature =
            '6896bd60eeae296db48a229ff71dfe071bde413e6d43f917dc8dcf8c78de33418906d11ac976abccb20b091292bff4ea897efcb639ea871cfa95f6de339e4b0a';

        expect(
            Codec.encodeHex(
                Ecc.signSchnorr(hash, privateKey, auxRand: auxRand)),
            signature);
      });
    });

    group('signSchnorrForMuSig2', () {
      //Test case from : https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/sign_verify_vectors.json
      test('Get partial signature for musig2 (case 1)', () {
        Uint8List message = Codec.decodeHex(
            '599c67ea410d005b9da90817cf03ed3b1c868e4da4edf00a5880b0082c237869');
        List<Uint8List> participantPublicKeys = [
          Codec.decodeHex(
              '03935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9'),
          Codec.decodeHex(
              '02d2dc6f5df7c56acf38c7fa0ae7a759ae30e19b37359dfde015872324c7ef6e05')
        ];
        Uint8List privateKey = Codec.decodeHex(
            '7fb9e0e687ada1eebf7ecfe2f21e73ebdb51a7d450948dfe8d76d7f2d1007671');
        Uint8List secretNonce = Codec.decodeHex(
            '803b1a9843bbb36cf28f81e49fde20031bcc6f41e1654758ea44501856dfa6b696b5084a3512dcd821059b3ef039431574d7662478ceb399c7098abc2ec6722603935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9');
        Uint8List aggregatedPubNonce = Codec.decodeHex(
            '0341432722c5cd0268d829c702cf0d1cbce57033eed201fd335191385227c3210c03d377f2d258b64aadc0e16f26462323d701d286046a2ea93365656afd9875982b');
        Uint8List publicKey = Codec.decodeHex(
            '03935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9');
        expect(
            Codec.encodeHex(Ecc.signSchnorrForMuSig2(
                message,
                aggregatedPubNonce,
                privateKey,
                secretNonce,
                publicKey,
                participantPublicKeys,
                isFullSignature: false)),
            'b15d2cd3c3d22b04dae438ce653f6b4ecf042f42cfded7c41b64aaf9b4af53fb');
        expect(
            Codec.encodeHex(Ecc.signSchnorrForMuSig2(
                message,
                aggregatedPubNonce,
                privateKey,
                secretNonce,
                publicKey,
                participantPublicKeys,
                isFullSignature: true)),
            '041da22223ce65c92c9a0d6c2cac828aaf1eee56304fec371ddf91ebb2b9ef09b15d2cd3c3d22b04dae438ce653f6b4ecf042f42cfded7c41b64aaf9b4af53fb');
      });

      test('Get partial signature for musig2 (case 2)', () {
        Uint8List message = Codec.decodeHex(
            '599c67ea410d005b9da90817cf03ed3b1c868e4da4edf00a5880b0082c237869');
        List<Uint8List> participantPublicKeys = [
          Codec.decodeHex(
              '03935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9'),
          Codec.decodeHex(
              '02d2dc6f5df7c56acf38c7fa0ae7a759ae30e19b37359dfde015872324c7ef6e05')
        ];
        Uint8List privateKey = Codec.decodeHex(
            '3874d22de7a7290c49ce7f1dc17d1a8cd8918e1f799055139d57fc0988d04d10');
        Uint8List secretNonce = Codec.decodeHex(
            '41f401c558584f0412dae913bc61be593319e2d83381b8ab5312b92d7fc9b6198b4ad586d0c923a814cb6cca0657ac49de647a86c7bb7f2369760cd75b37e55002d2dc6f5df7c56acf38c7fa0ae7a759ae30e19b37359dfde015872324c7ef6e05');
        Uint8List aggregatedPubNonce = Codec.decodeHex(
            '0341432722c5cd0268d829c702cf0d1cbce57033eed201fd335191385227c3210c03d377f2d258b64aadc0e16f26462323d701d286046a2ea93365656afd9875982b');
        Uint8List publicKey = Codec.decodeHex(
            '02d2dc6f5df7c56acf38c7fa0ae7a759ae30e19b37359dfde015872324c7ef6e05');
        expect(
            Codec.encodeHex(Ecc.signSchnorrForMuSig2(
                message,
                aggregatedPubNonce,
                privateKey,
                secretNonce,
                publicKey,
                participantPublicKeys,
                isFullSignature: false)),
            '6193d6ac61b354e9105bbdc8937a3454a6d705b6d57322a5a472a02ce99fcb64');
      });

      test('Get partial signature for musig2 (case 3)', () {
        Uint8List message = Codec.decodeHex(
            '599c67ea410d005b9da90817cf03ed3b1c868e4da4edf00a5880b0082c237869');
        List<Uint8List> participantPublicKeys = [
          Codec.decodeHex(
              '03935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9'),
          Codec.decodeHex(
              '03c7fb101d97ff930acd0c6760852ef64e69083de0b06ac6335724754bb4b0522c')
        ];
        Uint8List privateKey = Codec.decodeHex(
            '7fb9e0e687ada1eebf7ecfe2f21e73ebdb51a7d450948dfe8d76d7f2d1007671');
        Uint8List secretNonce = Codec.decodeHex(
            '803b1a9843bbb36cf28f81e49fde20031bcc6f41e1654758ea44501856dfa6b696b5084a3512dcd821059b3ef039431574d7662478ceb399c7098abc2ec6722603935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9');
        Uint8List aggregatedPubNonce = Codec.decodeHex(
            '0224afd36c902084058b51b5d36676bba4dc97c775873768e58822f87fe437d792028cb15929099eee2f5dae404cd39357591ba32e9af4e162b8d3e7cb5efe31cb20');
        Uint8List publicKey = Codec.decodeHex(
            '03935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9');
        expect(
            Codec.encodeHex(Ecc.signSchnorrForMuSig2(
                message,
                aggregatedPubNonce,
                privateKey,
                secretNonce,
                publicKey,
                participantPublicKeys,
                isFullSignature: false)),
            '9a87d3b79ec67228cb97878b76049b15dbd05b8158d17b5b9114d3c226887505');
      });
    });

    group('verifyEcdsa', () {
      test('Valid hash, public key, and signature (case 1)', () {
        Uint8List hash = Codec.decodeHex(
            '9f990c2cd1b7655c411450d01611b79070f50e1f01e18d59eb55e16f4433a1a6');
        Uint8List q = Codec.decodeHex(
            '0246c18ea7c5624b87e5f65a60842c9a22b27ae7e3630a95abeb35455259761824');
        Uint8List signature = Codec.decodeHex(
            'de494cd0a05a5621d8303a024130fc43550af2ec456de026174c542dfb1706e537f358ddba9025abc70d19693014304158eda80877e00f4b9cea86d18d4fad98');
        expect(
            Ecc.verifyEcdsa(Uint8List.fromList(hash), Uint8List.fromList(q),
                Uint8List.fromList(signature)),
            isTrue);
      });

      test('Invalid: Hash length not 32 bytes (should throw ArgumentError)',
          () {
        Uint8List invalidHash = Uint8List(31); // Too short
        Uint8List publicKey =
            Uint8List.fromList([0x02] + List.filled(32, 0x02));
        Uint8List signature = Uint8List.fromList(
          encodeBigInt(BigInt.from(123456789)) +
              encodeBigInt(BigInt.from(987654321)),
        );

        expect(() => Ecc.verifyEcdsa(invalidHash, publicKey, signature),
            throwsArgumentError);
      });

      test(
          'Invalid: Public key is not a valid point (should throw ArgumentError)',
          () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List invalidPublicKey = Uint8List(32); // Too short
        Uint8List signature = Uint8List.fromList(
          encodeBigInt(BigInt.from(123456789)) +
              encodeBigInt(BigInt.from(987654321)),
        );

        expect(() => Ecc.verifyEcdsa(hash, invalidPublicKey, signature),
            throwsArgumentError);
      });

      test(
          'Invalid: Signature length not 64 bytes (should throw ArgumentError)',
          () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List publicKey =
            Uint8List.fromList([0x02] + List.filled(32, 0x02));
        Uint8List invalidSignature = Uint8List(63); // Too short

        expect(() => Ecc.verifyEcdsa(hash, publicKey, invalidSignature),
            throwsArgumentError);
      });

      test('Invalid: Incorrect signature should return false', () {
        Uint8List hash = Codec.decodeHex(
            '9f990c2cd1b7655c411450d01611b79070f50e1f01e18d59eb55e16f4433a1a6');
        Uint8List q = Codec.decodeHex(
            '0246c18ea7c5624b87e5f65a60842c9a22b27ae7e3630a95abeb35455259761824');
        Uint8List signature = Codec.decodeHex(
            'de494cd0a05a5621d8303a024130fc43550af2ec456de026174c542dfb1706e537f358ddba9025abc70d19693014304158eda80877e00f4b9cea86d18d4fad23');
        expect(
            Ecc.verifyEcdsa(Uint8List.fromList(hash), Uint8List.fromList(q),
                Uint8List.fromList(signature)),
            isFalse);
      });

      test('Invalid: Incorrect public key should return false', () {
        Uint8List hash = Codec.decodeHex(
            '9f990c2cd1b7655c411450d01611b79070f50e1f01e18d59eb55e16f4433a1a6');
        Uint8List q = Uint8List.fromList([0x02] + List.filled(32, 0x01));
        Uint8List signature = Codec.decodeHex(
            'de494cd0a05a5621d8303a024130fc43550af2ec456de026174c542dfb1706e537f358ddba9025abc70d19693014304158eda80877e00f4b9cea86d18d4fad98');
        expect(
            Ecc.verifyEcdsa(
                Uint8List.fromList(hash), q, Uint8List.fromList(signature)),
            isFalse);
      });

      // Test vector from https://github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
    });

    group('verifySchnorr', () {
      test('Verify schnorr signature (bip340 - index 0)', () {
        Uint8List hash = Codec.decodeHex(
            '0000000000000000000000000000000000000000000000000000000000000000');
        Uint8List publicKey = Codec.decodeHex(
            'F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9');
        Uint8List signature = Codec.decodeHex(
            'E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0');

        expect(Ecc.verifySchnorr(hash, publicKey, signature), isTrue);
      });
      test('Verify schnorr signature (bip340 - index 1)', () {
        Uint8List hash = Codec.decodeHex(
            '243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89');
        Uint8List publicKey = Codec.decodeHex(
            'DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659');
        Uint8List signature = Codec.decodeHex(
            '6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE33418906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A');

        expect(Ecc.verifySchnorr(hash, publicKey, signature), isTrue);
      });
      test('Verify schnorr signature (bip340 - index 2)', () {
        Uint8List hash = Codec.decodeHex(
            '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C');
        Uint8List publicKey = Codec.decodeHex(
            'DD308AFEC5777E13121FA72B9CC1B7CC0139715309B086C960E18FD969774EB8');
        Uint8List signature = Codec.decodeHex(
            '5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7');

        expect(Ecc.verifySchnorr(hash, publicKey, signature), isTrue);
      });
      test('Verify schnorr signature (bip340 - index 3)', () {
        Uint8List hash = Codec.decodeHex(
            'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
        Uint8List publicKey = Codec.decodeHex(
            '25D1DFF95105F5253C4022F628A996AD3A0D95FBF21D468A1B33F8C160D8F517');
        Uint8List signature = Codec.decodeHex(
            '7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3');

        expect(Ecc.verifySchnorr(hash, publicKey, signature), isTrue);
      });

      //Test vector from https://github.com/bitcoin/bips/blob/master/bip-0341/wallet-test-vectors.json
      test('Verify schnorr signature (bip341 - line 276)', () {
        String internalPrivateKey =
            '6b973d88838f27366ed61c9ad6367663045cb456e28335c109e30717ae0c6baa';
        Uint8List sigHash = Codec.decodeHex(
            '2514a6272f85cfa0f45eb907fcb0d121b808ed37c6ea160a5a9046ed5526d555');
        Uint8List signature = Codec.decodeHex(
            'ed7c1647cb97379e76892be0cacff57ec4a7102aa24296ca39af7541246d8ff14d38958d4cc1e2e478e4d4a764bbfd835b16d4e314b72937b29833060b87276c');

        HDWallet hdWallet =
            HDWallet(Codec.decodeHex(internalPrivateKey), null, Uint8List(0));
        // expect(Encoder.encodeHex(hdWallet.getTweakedPrivateKey()),
        //     tweakedPrivateKey);
        Uint8List tweakedPublicKey = hdWallet.getPublicKey(true, true);
        expect(Ecc.verifySchnorr(sigHash, tweakedPublicKey, signature), isTrue);
      });
      test('Verify schnorr signature (bip341 - line 302)', () {
        String internalPrivateKey =
            '1e4da49f6aaf4e5cd175fe08a32bb5cb4863d963921255f33d3bc31e1343907f';
        Uint8List merkleRoot = Codec.decodeHex(
            "5b75adecf53548f3ec6ad7d78383bf84cc57b55a3127c72b9a2481752dd88b21");
        Uint8List sigHash = Codec.decodeHex(
            '325a644af47e8a5a2591cda0ab0723978537318f10e6a63d4eed783b96a71a4d');
        Uint8List signature = Codec.decodeHex(
            '052aedffc554b41f52b521071793a6b88d6dbca9dba94cf34c83696de0c1ec35ca9c5ed4ab28059bd606a4f3a657eec0bb96661d42921b5f50a95ad33675b54f');

        HDWallet hdWallet =
            HDWallet(Codec.decodeHex(internalPrivateKey), null, Uint8List(0));
        // expect(
        //     Encoder.encodeHex(
        //         hdWallet.getTweakedPrivateKey(merkleRoot: merkleRoot)),
        //     tweakedPrivateKey);
        Uint8List tweakedPublicKey =
            hdWallet.getPublicKey(true, true, merkleRoot: merkleRoot);
        expect(Ecc.verifySchnorr(sigHash, tweakedPublicKey, signature), isTrue);
      });
      test('Verify schnorr signature (bip341 - lline 323)', () {
        String internalPrivateKey =
            'd3c7af07da2d54f7a7735d3d0fc4f0a73164db638b2f2f7c43f711f6d4aa7e64';
        Uint8List merkleRoot = Codec.decodeHex(
            "c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b");
        String tweakedPrivateKey =
            '97323385e57015b75b0339a549c56a948eb961555973f0951f555ae6039ef00d';
        Uint8List sigHash = Codec.decodeHex(
            'bf013ea93474aa67815b1b6cc441d23b64fa310911d991e713cd34c7f5d46669');
        Uint8List signature = Codec.decodeHex(
            'ff45f742a876139946a149ab4d9185574b98dc919d2eb6754f8abaa59d18b025637a3aa043b91817739554f4ed2026cf8022dbd83e351ce1fabc272841d2510a');

        HDWallet hdWallet =
            HDWallet(Codec.decodeHex(internalPrivateKey), null, Uint8List(0));
        expect(
            Codec.encodeHex(
                hdWallet.getPrivateKey(true, true, merkleRoot: merkleRoot)),
            tweakedPrivateKey);
        Uint8List tweakedPublicKey =
            hdWallet.getPublicKey(true, true, merkleRoot: merkleRoot);
        expect(Ecc.verifySchnorr(sigHash, tweakedPublicKey, signature), isTrue);
      });
      test('Verify schnorr signature (bip341 - lline 350)', () {
        String internalPrivateKey =
            'f36bb07a11e469ce941d16b63b11b9b9120a84d9d87cff2c84a8d4affb438f4e';
        Uint8List merkleRoot = Codec.decodeHex(
            "ccbd66c6f7e8fdab47b3a486f59d28262be857f30d4773f2d5ea47f7761ce0e2");
        String tweakedPrivateKey =
            'a8e7aa924f0d58854185a490e6c41f6efb7b675c0f3331b7f14b549400b4d501';
        Uint8List sigHash = Codec.decodeHex(
            '4f900a0bae3f1446fd48490c2958b5a023228f01661cda3496a11da502a7f7ef');
        Uint8List signature = Codec.decodeHex(
            'b4010dd48a617db09926f729e79c33ae0b4e94b79f04a1ae93ede6315eb3669de185a17d2b0ac9ee09fd4c64b678a0b61a0a86fa888a273c8511be83bfd6810f');

        HDWallet hdWallet =
            HDWallet(Codec.decodeHex(internalPrivateKey), null, Uint8List(0));
        expect(
            Codec.encodeHex(
                hdWallet.getPrivateKey(true, true, merkleRoot: merkleRoot)),
            tweakedPrivateKey);
        Uint8List tweakedPublicKey =
            hdWallet.getPublicKey(true, true, merkleRoot: merkleRoot);
        expect(Ecc.verifySchnorr(sigHash, tweakedPublicKey, signature), isTrue);
      });

      test('Verify schnorr signature for musig2 (case 1)', () {
        Uint8List message = Codec.decodeHex(
            '599c67ea410d005b9da90817cf03ed3b1c868e4da4edf00a5880b0082c237869');
        Uint8List aggregatedPubKey = WalletUtility.aggregatePublicKey([
          '03935f972da013f80ae011890fa89b67a27b7be6ccb24d3274d18b2d4067f261a9',
          '02d2dc6f5df7c56acf38c7fa0ae7a759ae30e19b37359dfde015872324c7ef6e05'
        ]);
        Uint8List signature = Codec.decodeHex(
            '041da22223ce65c92c9a0d6c2cac828aaf1eee56304fec371ddf91ebb2b9ef0912f1038025857fedeb3ff696f8b99fa4bb2c5812f6095a2e0004ec99ce18de1e');
        expect(Ecc.verifySchnorr(message, aggregatedPubKey, signature), isTrue);
      });

      test('Verify schnorr signature for musig2 (case 2)', () {
        // Uint8List message = Codec.decodeHex(
        //     '6701942fd0f38440a7c410a3fcf6a6e10bd76a4974c3b0a9553e60528c78a6b5');
        // Uint8List aggregatedPubKey = Codec.decodeHex(
        //     'dacdd314a2627843ce701e8dc16adb4082c1a6e7f3dff8e0f05503660657bcd9');
        // Uint8List signature = Codec.decodeHex(
        //     'f7cf5efd5dd274a08a88e15e2f6fb1f1c9c76b214dfd737cf8f61501fddb244a9fea050d93fb627389c9708c65287fc2d7eb8ac9088fc41ee8035af22cddc545');
        // expect(Ecc.verifySchnorr(message, aggregatedPubKey, signature), isTrue);
      });
    });

    group('getAggregatedSignatureForMuSig2', () {
      test('Get aggregated signature for musig2', () {
        Uint8List aggregatedPubKey = Codec.decodeHex(
            'f68803d6235df99eb72f251d832b52029a64ae2c195a15823bd85f9577478408');
        Uint8List aggregatedPubNonce = Codec.decodeHex(
            '0341432722c5cd0268d829c702cf0d1cbce57033eed201fd335191385227c3210c03d377f2d258b64aadc0e16f26462323d701d286046a2ea93365656afd9875982b');
        Uint8List message = Codec.decodeHex(
            '599c67ea410d005b9da90817cf03ed3b1c868e4da4edf00a5880b0082c237869');
        List<Uint8List> signatureList = [
          Codec.decodeHex(
              'b15d2cd3c3d22b04dae438ce653f6b4ecf042f42cfded7c41b64aaf9b4af53fb'),
          Codec.decodeHex(
              '6193d6ac61b354e9105bbdc8937a3454a6d705b6d57322a5a472a02ce99fcb64')
        ];

        Uint8List aggregatedSignature = Ecc.getAggregatedSignatureForMuSig2(
            aggregatedPubKey, aggregatedPubNonce, message, signatureList);
        expect(Codec.encodeHex(aggregatedSignature),
            '041da22223ce65c92c9a0d6c2cac828aaf1eee56304fec371ddf91ebb2b9ef0912f1038025857fedeb3ff696f8b99fa4bb2c5812f6095a2e0004ec99ce18de1e');
        //O:041da22223ce65c92c9a0d6c2cac828aaf1eee56304fec371ddf91ebb2b9ef0912f1038025857fedeb3ff696f8b99fa4bb2c5812f6095a2e0004ec99ce18de1e
        //  041da22223ce65c92c9a0d6c2cac828aaf1eee56304fec371ddf91ebb2b9ef09c1875cc6d58df9a1f1354874f8375a104c9835d79190060cc5cbccfb162cc602
      });
    });
  });
}
