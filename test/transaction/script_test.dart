@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:test/test.dart';

main() {
  group('Script', () {
    group('get length', () {
      test('Get length of script', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Encoder.decodeHex(scriptText);
        expect(Script(Script.parseToCommand(script)).length, 23);
      });
    });
    group('parseToCommand', () {
      test('Generate scrip from script text', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Encoder.decodeHex(scriptText);
        expect(Script(Script.parseToCommand(script)), isA<Script>());
      });
      test('Single-byte push', () {
        Uint8List script =
            Uint8List.fromList([2, 0xab, 0xcd]); // Length 2, Data: [0xab, 0xcd]
        expect(Script.parseToCommand(script), equals([171, 205]));
      });

      test('OP_PUSHDATA1', () {
        Uint8List script = Uint8List.fromList(
            [4, 76, 2, 0xab, 0xcd]); // OP_PUSHDATA1 (76) with 2-byte data
        expect(
            Script.parseToCommand(script),
            equals([
              Uint8List.fromList([0xab, 0xcd])
            ]));
      });

      test('OP_PUSHDATA2', () {
        Uint8List script = Uint8List.fromList(
            [5, 77, 2, 0, 0xab, 0xcd]); // OP_PUSHDATA2 (77) with 2-byte data
        expect(
            Script.parseToCommand(script),
            equals([
              Uint8List.fromList([0xab, 0xcd])
            ]));
      });

      test('Multiple opcodes', () {
        Uint8List script = Uint8List.fromList(
            [3, 0x51, 0x52, 0x53]); // OP_1 (0x51), OP_2 (0x52), OP_3 (0x53)
        expect(Script.parseToCommand(script), equals([0x51, 0x52, 0x53]));
      });

      test('Invalid parsing length should throw an exception', () {
        Uint8List script = Uint8List.fromList(
            [5, 0x51, 0x52, 0x53]); // Declared length is 5, but only 3 bytes
        expect(() => Script.parseToCommand(script), throwsException);
      });

      test('Invalid OP_PUSHDATA1 length should throw an exception', () {
        Uint8List script = Uint8List.fromList(
            [4, 76, 3, 0xab, 0xcd]); // OP_PUSHDATA1 with incorrect length
        expect(() => Script.parseToCommand(script), throwsRangeError);
      });

      test('Invalid OP_PUSHDATA2 length should throw an exception', () {
        Uint8List script = Uint8List.fromList(
            [6, 77, 4, 0, 0xab, 0xcd]); // OP_PUSHDATA2 with incorrect length
        expect(() => Script.parseToCommand(script), throwsException);
      });
    });
    group('rawSerialize', () {
      test('Serialize script without length', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Encoder.decodeHex(scriptText);
        expect(Script(Script.parseToCommand(script)).rawSerialize(),
            '00143c5e7ce7108e9c0fd8845cc124ea60d30a635e95');
      });
    });
    group('serialize', () {
      test('Serialize script without length', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Encoder.decodeHex(scriptText);
        expect(Script(Script.parseToCommand(script)).serialize(), scriptText);
      });
    });
    group('operator ==', () {
      test('Check equal operation', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Script targetScript =
            Script(Script.parseToCommand(Encoder.decodeHex(scriptText)));
        Script matchedScript =
            Script(Script.parseToCommand(Encoder.decodeHex(scriptText)));
        expect(targetScript == matchedScript, true);
      });
    });
    group('get hashCode', () {
      test('Get hash code', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Script script =
            Script(Script.parseToCommand(Encoder.decodeHex(scriptText)));
        expect(script.hashCode, 88687450);
      });
    });
  });
}
