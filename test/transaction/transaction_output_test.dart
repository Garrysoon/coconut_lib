@Tags(['unit'])
import 'dart:math';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() {
  group('TransactionOutput', () {
    group('setAmount', () {
      test('', () {});
    });
    group('TransactionOutput.forPayment', () {
      test('', () {});
    });
    group('isDustOutput', () {
      //   p2wpkh 294;
      //   p2wsh 354;
      //   p2sh 888;
      //   p2wpkhInP2sh 273;
      test('Check dust in P2PKH (false)', () {
        TransactionOutput output = TransactionOutput.forPayment(
            1000, '1JDbm94jodpi7rek4p6oXYJMUEyA8zCJEG');
        expect(output.isDustOutput(AddressType.p2pkh.isSegwit), false);
      });
      test('Check dust in P2PKH (true)', () {
        int threshold = 546;
        TransactionOutput output = TransactionOutput.forPayment(
            threshold, '1JDbm94jodpi7rek4p6oXYJMUEyA8zCJEG');
        expect(output.isDustOutput(AddressType.p2pkh.isSegwit), true);
      });
      test('Check dust in P2WPKH (false)', () {
        TransactionOutput output = TransactionOutput.forPayment(
            1000, 'bc1qjkyj7gr5sr80lzqjvp000kj4zer8uv5348wxft');
        expect(output.isDustOutput(AddressType.p2wpkh.isSegwit), false);
      });
      test('Check dust in P2WPKH (true)', () {
        int threshold = 294;
        TransactionOutput output = TransactionOutput.forPayment(
            threshold, 'bc1qjkyj7gr5sr80lzqjvp000kj4zer8uv5348wxft');
        expect(output.isDustOutput(AddressType.p2wpkh.isSegwit), true);
      });
      test('Check in P2WSH (false)', () {
        TransactionOutput output = TransactionOutput.forPayment(1000,
            'bc1qwqdg6squsna38e46795at95yu9atm8azzmyvckulcc7kytlcckxswvvzej');
        expect(output.isDustOutput(AddressType.p2wsh.isSegwit), false);
      });
      test('Check in P2WSH (true)', () {
        int threshold = 330;
        TransactionOutput output = TransactionOutput.forPayment(threshold,
            'bc1qwqdg6squsna38e46795at95yu9atm8azzmyvckulcc7kytlcckxswvvzej');
        expect(output.isDustOutput(AddressType.p2wsh.isSegwit), true);
      });
    });
    group('', () {
      test('', () {});
    });
    group('', () {
      test('', () {});
    });
  });
}
