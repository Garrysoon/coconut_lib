import 'dart:typed_data';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:coconut_lib/src/cryptography/elliptic_curve_cryptography.dart';
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
        expect(isPrivate(validPrivateKey), isTrue);
      });

      test('Valid private key near EC_GROUP_ORDER', () {
        Uint8List validPrivateKey =
            bigIntToUint8List(EC_GROUP_ORDER - BigInt.one); // ✅ FIXED
        expect(isPrivate(validPrivateKey), isTrue);
      });

      test('Private key is zero (invalid)', () {
        Uint8List zeroKey = Uint8List(32); // 0x000000...0000
        expect(isPrivate(zeroKey), isFalse);
      });

      test('Private key is exactly EC_GROUP_ORDER (invalid)', () {
        Uint8List ecGroupKey = bigIntToUint8List(EC_GROUP_ORDER);
        expect(isPrivate(ecGroupKey), isFalse);
      });

      test('Private key is greater than EC_GROUP_ORDER (invalid)', () {
        Uint8List overKey = bigIntToUint8List(EC_GROUP_ORDER + BigInt.one);
        expect(isPrivate(overKey), isFalse);
      });

      test('Private key has wrong length (invalid)', () {
        Uint8List shortKey = Uint8List(31); // Too short
        expect(isPrivate(shortKey), isFalse);

        Uint8List longKey = Uint8List(33); // Too long
        expect(isPrivate(longKey), isFalse);
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
        expect(isPoint(validCompressedKey), isTrue);
      });

      test('Valid compressed public key (0x03 prefix)', () {
        Uint8List validCompressedKey =
            Uint8List.fromList([0x03] + List.filled(32, 0x01));
        expect(isPoint(validCompressedKey), isTrue);
      });

      test('Valid uncompressed public key (0x04 prefix)', () {
        Uint8List validUncompressedKey =
            Uint8List.fromList([0x04] + List.filled(64, 0x01));
        expect(isPoint(validUncompressedKey), isTrue);
      });

      test('Invalid: Too short (32 bytes)', () {
        Uint8List shortKey = Uint8List.fromList(List.filled(31, 0x01));
        expect(isPoint(shortKey), isFalse);
      });

      test('Invalid: Wrong prefix (not 0x02, 0x03, 0x04)', () {
        Uint8List wrongPrefixKey =
            Uint8List.fromList([0x01] + List.filled(32, 0x01));
        expect(isPoint(wrongPrefixKey), isFalse);
      });

      test('Invalid: Compressed key but length is wrong', () {
        Uint8List wrongLengthKey =
            Uint8List.fromList([0x02] + List.filled(30, 0x01));
        expect(isPoint(wrongLengthKey), isFalse);
      });

      test('Invalid: Uncompressed key but length is wrong', () {
        Uint8List wrongLengthUncompressedKey =
            Uint8List.fromList([0x04] + List.filled(63, 0x01));
        expect(isPoint(wrongLengthUncompressedKey), isFalse);
      });

      test('Invalid: x coordinate is zero', () {
        Uint8List zeroXKey = Uint8List.fromList([0x02] + List.filled(32, 0x00));
        expect(isPoint(zeroXKey), isFalse);
      });

      test('Invalid: y coordinate is zero in uncompressed key', () {
        Uint8List zeroYKey = Uint8List.fromList(
            [0x04] + List.filled(32, 0x01) + List.filled(32, 0x00));
        expect(isPoint(zeroYKey), isFalse);
      });

      test('Invalid: y coordinate exceeds EC_P in uncompressed key', () {
        Uint8List bigYKey = Uint8List.fromList([0x04] +
            List.filled(32, 0x01) +
            bigIntToUint8List(EC_P + BigInt.one));
        expect(isPoint(bigYKey), isFalse);
      });

      test('Invalid: Malformed point should trigger _decodeFrom exception', () {
        Uint8List malformedKey = Uint8List.fromList(
            [0x04] + List.filled(62, 0x01)); // Incorrect length
        expect(isPoint(malformedKey), isFalse);
      });
    });
    group('isSignature', () {
      test('Valid signature', () {
        Uint8List validSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one) +
              bigIntToUint8List(EC_GROUP_ORDER - BigInt.one),
        );
        expect(isSignature(validSignature), isTrue);
      });

      test('Invalid: Signature too short', () {
        Uint8List shortSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one), // Only 32 bytes (missing s)
        );
        expect(() => isSignature(shortSignature), throwsRangeError);
      });

      test('Invalid: Signature too long', () {
        Uint8List longSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one) +
              bigIntToUint8List(BigInt.one) +
              [0x00], // 65 bytes
        );
        expect(isSignature(longSignature), isFalse);
      });

      test('Invalid: r is too large (>= EC_GROUP_ORDER)', () {
        Uint8List invalidRSignature = Uint8List.fromList(
          bigIntToUint8List(EC_GROUP_ORDER) + bigIntToUint8List(BigInt.one),
        );
        expect(isSignature(invalidRSignature), isFalse);
      });

      test('Invalid: s is too large (>= EC_GROUP_ORDER)', () {
        Uint8List invalidSSignature = Uint8List.fromList(
          bigIntToUint8List(BigInt.one) + bigIntToUint8List(EC_GROUP_ORDER),
        );
        expect(isSignature(invalidSSignature), isFalse);
      });
    });
    group('pointFromScalar', () {
      test('Valid scalar with compressed output', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(2));
        Uint8List? pubKey = pointFromScalar(privateKey, true);
        expect(pubKey, isNotNull);
        expect(pubKey!.length, equals(33));
        expect(pubKey[0], anyOf(0x02, 0x03)); // Compressed prefix
      });

      test('Valid scalar with uncompressed output', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(2));
        Uint8List? pubKey = pointFromScalar(privateKey, false);
        expect(pubKey, isNotNull);
        expect(pubKey!.length, equals(65));
        expect(pubKey[0], equals(0x04)); // Uncompressed prefix
      });

      test('Invalid: Zero private key (should throw ArgumentError)', () {
        Uint8List zeroPrivateKey = Uint8List(32);
        expect(
            () => pointFromScalar(zeroPrivateKey, true), throwsArgumentError);
      });

      test('Invalid: Private key too large (should throw ArgumentError)', () {
        Uint8List tooLargePrivateKey = bigIntToUint8List(EC_GROUP_ORDER);
        expect(() => pointFromScalar(tooLargePrivateKey, true),
            throwsArgumentError);
      });

      test('Invalid: Infinity point should return null', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.zero);
        expect(() => pointFromScalar(privateKey, true), throwsArgumentError);
      });

      test('Invalid: Malformed private key length', () {
        Uint8List shortKey = Uint8List(31);
        expect(() => pointFromScalar(shortKey, true), throwsArgumentError);

        Uint8List longKey = Uint8List(33);
        expect(() => pointFromScalar(longKey, true), throwsArgumentError);
      });
    });
    group('pointAddScalar', () {
      test('Valid point and valid tweak (compressed)', () {
        Uint8List point = Uint8List.fromList([0x02] + List.filled(32, 0x01));
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        Uint8List? result = pointAddScalar(point, tweak, true);
        expect(result, isNotNull);
        expect(result!.length, equals(33));
        expect(result[0], anyOf(0x02, 0x03)); // Compressed prefix
      });

      test('Valid point and valid tweak (uncompressed)', () {
        Uint8List point = Uint8List.fromList([0x04] + List.filled(64, 0x01));
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        Uint8List? result = pointAddScalar(point, tweak, false);
        expect(result, isNotNull);
        expect(result!.length, equals(65));
        expect(result[0], equals(0x04)); // Uncompressed prefix
      });

      test('Invalid: Non-point input should throw ArgumentError', () {
        Uint8List invalidPoint = Uint8List.fromList(List.filled(31, 0x01));
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        expect(() => pointAddScalar(invalidPoint, tweak, true),
            throwsArgumentError);
      });

      test('Tweak is zero (should return original point)', () {
        Uint8List point = Uint8List.fromList([0x02] + List.filled(32, 0x01));
        Uint8List zeroTweak = Uint8List(32);
        Uint8List? result = pointAddScalar(point, zeroTweak, true);
        expect(result, equals(point));
      });
    });
    group('privateAdd', () {
      test('Valid private key and valid tweak', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List tweak = bigIntToUint8List(BigInt.from(10));
        Uint8List? result = privateAdd(privateKey, tweak);
        expect(result, isNotNull);
        expect(fromBuffer(result!), equals(BigInt.from(15) % n));
      });

      test('Tweak is zero (should return original private key)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List zeroTweak = Uint8List(32);
        Uint8List? result = privateAdd(privateKey, zeroTweak);
        expect(result, equals(privateKey));
      });

      test('Invalid: Private key is zero (should throw ArgumentError)', () {
        Uint8List zeroPrivateKey = Uint8List(32);
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        expect(() => privateAdd(zeroPrivateKey, tweak), throwsArgumentError);
      });

      test('Invalid: Private key too large (should throw ArgumentError)', () {
        Uint8List tooLargePrivateKey = bigIntToUint8List(n);
        Uint8List tweak = bigIntToUint8List(BigInt.from(5));
        expect(
            () => privateAdd(tooLargePrivateKey, tweak), throwsArgumentError);
      });

      test('Invalid: Tweak too large (should throw ArgumentError)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List tooLargeTweak = bigIntToUint8List(n);
        expect(
            () => privateAdd(privateKey, tooLargeTweak), throwsArgumentError);
      });

      test('Sum of private key and tweak equals n (should return null)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(5));
        Uint8List tweak = bigIntToUint8List(n - BigInt.from(5));
        Uint8List? result = privateAdd(privateKey, tweak);
        expect(result, isNull);
      });

      test('Result requires padding (should still be 32 bytes)', () {
        Uint8List privateKey = bigIntToUint8List(BigInt.from(1));
        Uint8List tweak = bigIntToUint8List(BigInt.from(255));
        Uint8List? result = privateAdd(privateKey, tweak);
        expect(result, isNotNull);
        expect(result!.length, equals(32));
      });
    });
    group('sign', () {
      test('Valid hash and private key', () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List privateKey = Uint8List.fromList(List.filled(32, 0x02));
        Uint8List signature = sign(hash, privateKey);

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

        expect(() => sign(invalidHash, privateKey), throwsArgumentError);
      });

      test(
          'Invalid: Private key length not 32 bytes (should throw ArgumentError)',
          () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List invalidPrivateKey = Uint8List(31); // Too short

        expect(() => sign(hash, invalidPrivateKey), throwsArgumentError);
      });

      test('Invalid: Private key is zero (should throw ArgumentError)', () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List zeroPrivateKey = Uint8List(32); // Zero private key

        expect(() => sign(hash, zeroPrivateKey), throwsArgumentError);
      });

      test('Invalid: Private key too large (should throw ArgumentError)', () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List tooLargePrivateKey = encodeBigInt(n);

        expect(() => sign(hash, tooLargePrivateKey), throwsArgumentError);
      });

      test('Sign schnorr signature (case 1)', () {
        Uint8List hash = Encoder.decodeHex(
            '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C');
        Uint8List privateKey = Encoder.decodeHex(
            'C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9');
        Uint8List auxRand = Encoder.decodeHex(
            'C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906');

        String signature =
            '5831aaeed7b44bb74e5eab94ba9d4294c49bcf2a60728d8b4c200f50dd313c1bab745879a5ad954a72c45a91c3a51d3c7adea98d82f8481e0e1e03674a6f3fb7';

        expect(
            Encoder.encodeHex(
                sign(hash, privateKey, isSchnorr: true, auxRand: auxRand)),
            signature);
      });

      test('Sign schnorr signature (case 2)', () {
        Uint8List hash = Encoder.decodeHex(
            '243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89');
        Uint8List privateKey = Encoder.decodeHex(
            'B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF');
        Uint8List auxRand = Encoder.decodeHex(
            '0000000000000000000000000000000000000000000000000000000000000001');

        String signature =
            '6896bd60eeae296db48a229ff71dfe071bde413e6d43f917dc8dcf8c78de33418906d11ac976abccb20b091292bff4ea897efcb639ea871cfa95f6de339e4b0a';

        expect(
            Encoder.encodeHex(
                sign(hash, privateKey, isSchnorr: true, auxRand: auxRand)),
            signature);
      });
    });

    group('verify', () {
      test('Valid hash, public key, and signature', () {
        Uint8List hash = Encoder.decodeHex(
            '9f990c2cd1b7655c411450d01611b79070f50e1f01e18d59eb55e16f4433a1a6');
        Uint8List q = Encoder.decodeHex(
            '0246c18ea7c5624b87e5f65a60842c9a22b27ae7e3630a95abeb35455259761824');
        Uint8List signature = Encoder.decodeHex(
            'de494cd0a05a5621d8303a024130fc43550af2ec456de026174c542dfb1706e537f358ddba9025abc70d19693014304158eda80877e00f4b9cea86d18d4fad98');
        expect(
            verify(Uint8List.fromList(hash), Uint8List.fromList(q),
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

        expect(() => verify(invalidHash, publicKey, signature),
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

        expect(() => verify(hash, invalidPublicKey, signature),
            throwsArgumentError);
      });

      test(
          'Invalid: Signature length not 64 bytes (should throw ArgumentError)',
          () {
        Uint8List hash = Uint8List.fromList(List.filled(32, 0x01));
        Uint8List publicKey =
            Uint8List.fromList([0x02] + List.filled(32, 0x02));
        Uint8List invalidSignature = Uint8List(63); // Too short

        expect(() => verify(hash, publicKey, invalidSignature),
            throwsArgumentError);
      });

      test('Invalid: Incorrect signature should return false', () {
        Uint8List hash = Encoder.decodeHex(
            '9f990c2cd1b7655c411450d01611b79070f50e1f01e18d59eb55e16f4433a1a6');
        Uint8List q = Encoder.decodeHex(
            '0246c18ea7c5624b87e5f65a60842c9a22b27ae7e3630a95abeb35455259761824');
        Uint8List signature = Encoder.decodeHex(
            'de494cd0a05a5621d8303a024130fc43550af2ec456de026174c542dfb1706e537f358ddba9025abc70d19693014304158eda80877e00f4b9cea86d18d4fad23');
        expect(
            verify(Uint8List.fromList(hash), Uint8List.fromList(q),
                Uint8List.fromList(signature)),
            isFalse);
      });

      test('Invalid: Incorrect public key should return false', () {
        Uint8List hash = Encoder.decodeHex(
            '9f990c2cd1b7655c411450d01611b79070f50e1f01e18d59eb55e16f4433a1a6');
        Uint8List q = Uint8List.fromList([0x02] + List.filled(32, 0x01));
        Uint8List signature = Encoder.decodeHex(
            'de494cd0a05a5621d8303a024130fc43550af2ec456de026174c542dfb1706e537f358ddba9025abc70d19693014304158eda80877e00f4b9cea86d18d4fad98');
        expect(
            verify(Uint8List.fromList(hash), q, Uint8List.fromList(signature)),
            isFalse);
      });

      test('Verify schnorr signature', () {
        Uint8List hash = Encoder.decodeHex(
            '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C');
        Uint8List publicKey = Encoder.decodeHex(
            'DD308AFEC5777E13121FA72B9CC1B7CC0139715309B086C960E18FD969774EB8');
        Uint8List signature = Encoder.decodeHex(
            '5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7');

        expect(verify(hash, publicKey, signature, isSchnorr: true, parity: 0),
            isTrue);
      });
      test('Verify schnorr signature (Case 2)', () {
        Uint8List hash = Encoder.decodeHex(
            '0d1079255571a05a742a22b0e544bd3888dd7e91ce04b5595167c6cda6e72927');
        Uint8List publicKey = Encoder.decodeHex(
            '45b451a396cbf8c3c94f8e9e871401bdbd4f38e8cf238165cb198d15c5093743');
        Uint8List signature = Encoder.decodeHex(
            '271500428ba10d1a3193eae8cd502071e65ee028bae9480dca50bb845be2e74523bcac026dabeabf808d734995a0b8eae73546a6588201444d729fd7ae1f5589');

        expect(verify(hash, publicKey, signature, isSchnorr: true, parity: 0),
            isTrue);
      });
    });
  });
}
