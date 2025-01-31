@Tags(['unit'])

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('Seed', () {
    late Seed seed;
    setUpAll(() {
      seed = MockFactory.createP2wpkhVault().keyStore.seed;
    });
    group('get mnemonic', () {
      test('Get mnemonic from seed', () {
        expect(seed.hashCode, 287424639);
      });
    });
    group('get passphrase', () {
      test('Get passphrase from seed', () {
        Seed targetSeed = Seed.fromHexadecimalEntropy(
            '000102030405060708090a0b0c0d0e0f',
            passphrase: 'passphrase');
        expect(targetSeed.passphrase, 'passphrase');
      });
    });
    group('get rootSeed', () {
      test('Get root seed from seed', () {
        expect(seed.rootSeed.hashCode, 431800215);
      });
    });
    group('Seed.random', () {
      test('Generate random seed', () {
        Seed seed1 = Seed.random(mnemonicLength: 24, passphrase: 'passphrase');
        Seed seed2 = Seed.random(mnemonicLength: 24, passphrase: 'passphrase');
        expect(seed1 != seed2, true);
      });

      test('Generate random seed with invalid mnemonic length exception', () {
        expect(() => Seed.random(mnemonicLength: 11, passphrase: 'passphrase'),
            throwsException);
        expect(() => Seed.random(mnemonicLength: 25, passphrase: 'passphrase'),
            throwsException);
        expect(() => Seed.random(mnemonicLength: 16, passphrase: 'passphrase'),
            throwsException);
      });
    });
    group('Seed.fromHexadecimalEntropy', () {
      test('Generate seed from hex entropy', () {
        Seed targetSeed = Seed.fromHexadecimalEntropy(
            '000102030405060708090a0b0c0d0e0f',
            passphrase: 'passphrase');
        expect(targetSeed.passphrase, 'passphrase');
      });
      test('Generate seed from hex entropy with invalid length exception', () {
        expect(
            () => Seed.fromHexadecimalEntropy(
                '000102030405060708090a0b0c0d0e0fa',
                passphrase: 'passphrase'),
            throwsException);
        expect(
            () => Seed.fromHexadecimalEntropy(
                '000102030405060708090a0b0c0d0e0fa000102030405060708090a0b0c0d0e0fa',
                passphrase: 'passphrase'),
            throwsException);
      });
    });
    group('Seed.fromBinaryEntropy', () {
      test('Generate seed from binary', () {
        Seed targetSeed = Seed.fromBinaryEntropy(
            '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000');
        expect(targetSeed.rootSeed.hashCode, 224017974);
      });
      test('Generate seed from binary with invalid length exception', () {
        expect(
            () => Seed.fromBinaryEntropy(
                '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'),
            throwsException);
      });
    });
    group('Seed.fromMnemonic', () {
      test('Generate seed from mnemonic', () {
        Seed targetSeed = Seed.fromMnemonic(
            'machine crack daughter fish credit glare raven fever tunnel delay fish record');
        expect(seed, targetSeed);
      });

      test('Invalid mnemonic exception', () {
        expect(
            () => Seed.fromMnemonic(
                'machine crack daughter fish credit glare raven fever tunnel delay fish abandon'),
            throwsException);
      });
    });
    group('toJson', () {
      test('Get json text from seed', () {
        expect(seed.toJson().hashCode, 1031440946);
      });
    });
    group('Seed.fromJson', () {
      test('Generate seed from json text', () {
        String jsonText = seed.toJson();
        Seed targetSeed = Seed.fromJson(jsonText);
        expect(targetSeed, seed);
      });
    });
    group('operator ==', () {
      test('Check equal', () {
        Seed seed1 = Seed.fromMnemonic(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');
        Seed seed2 = Seed.fromMnemonic(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');
        expect(seed1 == seed2, true);
      });
    });
    group('get hashCode', () {
      test('Get hash code', () {
        expect(seed.hashCode, 287424639);
      });
    });
  });
}
