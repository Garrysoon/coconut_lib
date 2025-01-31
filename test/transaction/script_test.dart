@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/converter.dart';
import 'package:test/test.dart';

main() {
  group('Script', () {
    group('get length', () {
      test('Get length of script', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Converter.hexToBytes(scriptText);
        expect(Script(Script.parseToCommand(script)).length, 23);
      });
    });
    group('Script.parse', () {
      test('Generate scrip from script text', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Converter.hexToBytes(scriptText);
        expect(Script(Script.parseToCommand(script)), isA<Script>());
      });
    });
    group('rawSerialize', () {
      test('Serialize script without length', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Converter.hexToBytes(scriptText);
        expect(Script(Script.parseToCommand(script)).rawSerialize(),
            '00143c5e7ce7108e9c0fd8845cc124ea60d30a635e95');
      });
    });
    group('serialize', () {
      test('Serialize script without length', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Uint8List script = Converter.hexToBytes(scriptText);
        expect(Script(Script.parseToCommand(script)).serialize(), scriptText);
      });
    });
    group('operator ==', () {
      test('Check equal operation', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Script targetScript =
            Script(Script.parseToCommand(Converter.hexToBytes(scriptText)));
        Script matchedScript =
            Script(Script.parseToCommand(Converter.hexToBytes(scriptText)));
        expect(targetScript == matchedScript, true);
      });
    });
    group('get hashCode', () {
      test('Get hash code', () {
        String scriptText = '1600143c5e7ce7108e9c0fd8845cc124ea60d30a635e95';
        Script script =
            Script(Script.parseToCommand(Converter.hexToBytes(scriptText)));
        expect(script.hashCode, 88687450);
      });
    });
  });
}
