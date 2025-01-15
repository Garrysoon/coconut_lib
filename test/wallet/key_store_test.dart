@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/utils/converter.dart';
import 'package:coconut_lib/src/utils/hash.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() {
  group('KeyStore', () {
    group('KeyStore.fromSeed', () {
      test('Generate key store from seed', () {
        Seed seed = Seed.fromMnemonic(
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about");
        KeyStore keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh);

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
      test('', () {});
    });
    group('sign', () {
      test('', () {});
    });
    group('signWithDerivationPath', () {
      test('', () {});
    });
    group('canSignToPsbt', () {
      test('', () {});
    });
    group('addSignatureToPsbt', () {
      test('', () {});
    });
    group('getPublicKey', () {
      test('', () {});
    });
    group('getPublicKeyWithDerivationPath', () {
      test('', () {});
    });
    group('validateSignature', () {
      test('', () {});
    });
    group('validateSignatureWithDerivationPath', () {
      test('', () {});
    });
    group('toJson', () {
      test('', () {});
    });
    group('KeyStore.fromJson', () {
      test('', () {});
    });
    group('toString', () {
      test('', () {});
    });
    group('operator ==', () {
      test('', () {});
    });
    group('get hashCode', () {
      test('', () {});
    });
  });
}
