@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('TimelockScript', () {
    late Uint8List testPublicKey;

    setUp(() {
      // 32-byte x-only public key for testing (from compressed public key by removing prefix)
      // Using a valid x-only public key from existing test data
      Uint8List compressedKey = Codec.decodeHex(
          '02d6481c1e9ead3f86508ec5d4b515089ae40505f642901e078824184e910d3363');
      // Extract x-only key (remove 0x02 prefix)
      testPublicKey = compressedKey.sublist(1);
    });

    group('TimelockScript.parse', () {
      test('Parse timelock script from hex string', () {
        // Create a script and serialize it
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        String serialized = script.serialize();
        InheritanceScript parsed = InheritanceScript.parse(serialized);
        expect(parsed.getTimelockValue(), 1000000);
        expect(parsed.getTimelockType(), 'CLTV');
        expect(parsed.getBeneficiaryPublicKey(), testPublicKey);
      });
    });

    group('TimelockScript.withCheckLockTimeVerify', () {
      test('Create timelock script with CLTV', () {
        int locktime = 1000000;
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(locktime, testPublicKey);

        expect(script.commands.length, 5);
        expect(script.commands[0], isA<Uint8List>());
        expect((script.commands[0] as Uint8List).length, 4);
        expect(script.commands[1],
            ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY'));
        expect(script.commands[2], ScriptOperationCode.getHex('OP_DROP'));
        expect(script.commands[3], testPublicKey);
        expect(script.commands[4], ScriptOperationCode.getHex('OP_CHECKSIG'));
      });

      test('Create timelock script with CLTV - verify locktime bytes', () {
        int locktime = 1000000;
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(locktime, testPublicKey);

        Uint8List locktimeBytes = script.commands[0] as Uint8List;
        int parsedLocktime = Converter.littleEndianToInt(locktimeBytes);
        expect(parsedLocktime, locktime);
      });

      test('Throw exception for invalid public key length', () {
        Uint8List invalidKey = Uint8List.fromList([1, 2, 3]); // Too short
        expect(
            () =>
                InheritanceScript.withCheckLockTimeVerify(1000000, invalidKey),
            throwsArgumentError);
      });
    });

    group('TimelockScript.withCheckSequenceVerify', () {
      test('Create timelock script with CSV', () {
        int sequence = 144; // 144 blocks
        InheritanceScript script =
            InheritanceScript.withCheckSequenceVerify(sequence, testPublicKey);

        expect(script.commands.length, 5);
        expect(script.commands[0], isA<Uint8List>());
        expect((script.commands[0] as Uint8List).length, 4);
        expect(script.commands[1],
            ScriptOperationCode.getHex('OP_CHECKSEQUENCEVERIFY'));
        expect(script.commands[2], ScriptOperationCode.getHex('OP_DROP'));
        expect(script.commands[3], testPublicKey);
        expect(script.commands[4], ScriptOperationCode.getHex('OP_CHECKSIG'));
      });

      test('Create timelock script with CSV - verify sequence bytes', () {
        int sequence = 144;
        InheritanceScript script =
            InheritanceScript.withCheckSequenceVerify(sequence, testPublicKey);

        Uint8List sequenceBytes = script.commands[0] as Uint8List;
        int parsedSequence = Converter.littleEndianToInt(sequenceBytes);
        expect(parsedSequence, sequence);
      });

      test('Throw exception for invalid public key length', () {
        Uint8List invalidKey = Uint8List.fromList([1, 2, 3]); // Too short
        expect(() => InheritanceScript.withCheckSequenceVerify(144, invalidKey),
            throwsArgumentError);
      });
    });

    group('getBeneficiaryPublicKey', () {
      test('Get beneficiary public key from CLTV script', () {
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        Uint8List? pubkey = script.getBeneficiaryPublicKey();
        expect(pubkey, isNotNull);
        expect(pubkey, testPublicKey);
        expect(pubkey?.length, 32);
      });

      test('Get beneficiary public key from CSV script', () {
        InheritanceScript script =
            InheritanceScript.withCheckSequenceVerify(144, testPublicKey);
        Uint8List? pubkey = script.getBeneficiaryPublicKey();
        expect(pubkey, isNotNull);
        expect(pubkey, testPublicKey);
        expect(pubkey?.length, 32);
      });
    });

    group('getTimelockValue', () {
      test('Get locktime value from CLTV script', () {
        int locktime = 1000000;
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(locktime, testPublicKey);
        int? value = script.getTimelockValue();
        expect(value, isNotNull);
        expect(value, locktime);
      });

      test('Get sequence value from CSV script', () {
        int sequence = 144;
        InheritanceScript script =
            InheritanceScript.withCheckSequenceVerify(sequence, testPublicKey);
        int? value = script.getTimelockValue();
        expect(value, isNotNull);
        expect(value, sequence);
      });
    });

    group('getTimelockType', () {
      test('Get CLTV type from script', () {
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        String? type = script.getTimelockType();
        expect(type, 'CLTV');
      });

      test('Get CSV type from script', () {
        InheritanceScript script =
            InheritanceScript.withCheckSequenceVerify(144, testPublicKey);
        String? type = script.getTimelockType();
        expect(type, 'CSV');
      });
    });

    group('isValidTimelockScript', () {
      test('Validate valid CLTV script', () {
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        expect(script.isValidTimelockScript(), true);
      });

      test('Validate valid CSV script', () {
        InheritanceScript script =
            InheritanceScript.withCheckSequenceVerify(144, testPublicKey);
        expect(script.isValidTimelockScript(), true);
      });

      test('Invalid script - empty commands', () {
        InheritanceScript script = InheritanceScript([]);
        expect(script.isValidTimelockScript(), false);
      });

      test('Invalid script - missing OP_CHECKSIG', () {
        List<dynamic> invalidCmds = [
          Converter.intToLittleEndianBytes(1000000, 4),
          ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY'),
          ScriptOperationCode.getHex('OP_DROP'),
          testPublicKey,
          // Missing OP_CHECKSIG
        ];
        InheritanceScript script = InheritanceScript(invalidCmds);
        expect(script.isValidTimelockScript(), false);
      });

      test('Invalid script - wrong public key length', () {
        Uint8List wrongKey = Uint8List.fromList(List.filled(33, 0));
        List<dynamic> invalidCmds = [
          Converter.intToLittleEndianBytes(1000000, 4),
          ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY'),
          ScriptOperationCode.getHex('OP_DROP'),
          wrongKey,
          ScriptOperationCode.getHex('OP_CHECKSIG'),
        ];
        InheritanceScript script = InheritanceScript(invalidCmds);
        expect(script.isValidTimelockScript(), false);
      });
    });

    group('serialize and rawSerialize', () {
      test('Serialize CLTV script', () {
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        String serialized = script.serialize();
        expect(serialized, isNotEmpty);
        expect(serialized.length % 2, 0); // Hex string should have even length
      });

      test('Raw serialize CLTV script', () {
        InheritanceScript script =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        String rawSerialized = script.rawSerialize();
        expect(rawSerialized, isNotEmpty);
        expect(
            rawSerialized.length % 2, 0); // Hex string should have even length
      });

      test('Round trip serialization', () {
        InheritanceScript original =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPublicKey);
        String serialized = original.serialize();
        InheritanceScript parsed = InheritanceScript.parse(serialized);
        expect(parsed.getTimelockValue(), original.getTimelockValue());
        expect(parsed.getTimelockType(), original.getTimelockType());
        expect(parsed.getBeneficiaryPublicKey(),
            original.getBeneficiaryPublicKey());
      });
    });
  });
}
