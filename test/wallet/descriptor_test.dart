@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() {
  group('Descriptor', () {
    group('Descriptor.forSingleSignature', () {
      test('Generate p2pkh wallet descriptor', () {
        Descriptor descriptor = Descriptor.forSingleSignature(
            "wpkh",
            "vpub5ZZ1q76vi2LR9PeQDoV13u8TZwsyqKa7yBfD3GnPPvBjVU9ZnBTMkwzCHCVBZaPHDKJNEdMKo8MTyrQ9234idzSG9nHFD6hsUB8HJ14NBg7",
            "84'/1'/0'",
            "98C7D774");

        String target =
            "wpkh([98C7D774/84'/1'/0']vpub5ZZ1q76vi2LR9PeQDoV13u8TZwsyqKa7yBfD3GnPPvBjVU9ZnBTMkwzCHCVBZaPHDKJNEdMKo8MTyrQ9234idzSG9nHFD6hsUB8HJ14NBg7/<0;1>/*)#7ra9g9d8";
        expect(descriptor.serialize(), target);
      });
    });
    group('Descriptor.forMultisignature', () {
      test('', () {});
    });
    group('Descriptor.parse(String descriptor)', () {
      test('', () {});
    });
    group('getDerivationPath', () {
      test('', () {});
    });
    group('getFingerprint', () {
      test('', () {});
    });
    group('getPublicKey', () {
      test('', () {});
    });
    group('serialize', () {
      test('', () {});
    });
  });
}
