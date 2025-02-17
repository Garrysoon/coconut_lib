@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:test/test.dart';

void main() {
  group('MultisignatureScript', () {
    group('MultisignatureScript.parse', () {
      test('Generate multisignature script from parse', () {
        String witnessScriptText =
            '695221028106e5b5449e0b78e7e06c6435f724b9797db0926ed3ba59b01d6e3dee8fd74b2102869102bed3322707dfebeaf06f9e0f89b5d133e48ee481bcd624dfc1fa1b18802102d6481c1e9ead3f86508ec5d4b515089ae40505f642901e078824184e910d336353ae';
        MultisignatureScript witnessScript =
            MultisignatureScript.parse(witnessScriptText);
        expect(witnessScript.getPublicKeys().length, 3);
      });
    });
    group('factory MultisignatureScript.forP2wsh', () {
      test('Generate multisignature script for p2wsh', () {
        List<Uint8List> publicKeys = [
          Encoder.decodeHex(
              '028106e5b5449e0b78e7e06c6435f724b9797db0926ed3ba59b01d6e3dee8fd74b'),
          Encoder.decodeHex(
              '02869102bed3322707dfebeaf06f9e0f89b5d133e48ee481bcd624dfc1fa1b1880'),
          Encoder.decodeHex(
              '02d6481c1e9ead3f86508ec5d4b515089ae40505f642901e078824184e910d3363')
        ];
        MultisignatureScript multisignatureScript =
            MultisignatureScript.forP2wsh(2, 3, publicKeys);
        expect(multisignatureScript.commands[0], 0x52);
        // expect(Converter.bytesToHex(multisignatureScript.commands[1]),
        //     publicKeys[0]);
        // expect(Converter.bytesToHex(multisignatureScript.commands[2]),
        //     publicKeys[1]);
        expect(multisignatureScript.commands[1], publicKeys[0]);
        expect(multisignatureScript.commands[2], publicKeys[1]);
        expect(multisignatureScript.commands[3], publicKeys[2]);
        expect(multisignatureScript.commands[4], 0x53);
        expect(multisignatureScript.commands[5], 0xae);
      });
    });
    group('getRequiredSignature', () {
      test('Get reqruied signature', () {
        List<Uint8List> publicKeys = [
          Encoder.decodeHex(
              '028106e5b5449e0b78e7e06c6435f724b9797db0926ed3ba59b01d6e3dee8fd74b'),
          Encoder.decodeHex(
              '02869102bed3322707dfebeaf06f9e0f89b5d133e48ee481bcd624dfc1fa1b1880'),
          Encoder.decodeHex(
              '02d6481c1e9ead3f86508ec5d4b515089ae40505f642901e078824184e910d3363')
        ];
        MultisignatureScript multisignatureScript =
            MultisignatureScript.forP2wsh(2, 3, publicKeys);
        expect(multisignatureScript.getRequiredSignature(), 2);
      });
    });
    group('getPublicKeys', () {
      test('Get public key list', () {
        List<Uint8List> publicKeys = [
          Encoder.decodeHex(
              '028106e5b5449e0b78e7e06c6435f724b9797db0926ed3ba59b01d6e3dee8fd74b'),
          Encoder.decodeHex(
              '02869102bed3322707dfebeaf06f9e0f89b5d133e48ee481bcd624dfc1fa1b1880'),
          Encoder.decodeHex(
              '02d6481c1e9ead3f86508ec5d4b515089ae40505f642901e078824184e910d3363')
        ];
        MultisignatureScript multisignatureScript =
            MultisignatureScript.forP2wsh(2, 3, publicKeys);
        expect(multisignatureScript.getPublicKeys(), publicKeys);
      });
    });
  });
}
