@Tags(['unit'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Miniscript', () {
    late String testPubkeyHex; // 32-byte x-only pubkey hex
    late Uint8List testPubkeyBytes;

    setUp(() {
      // 32-byte x-only public key for testing
      Uint8List compressedKey = Codec.decodeHex(
          '02d6481c1e9ead3f86508ec5d4b515089ae40505f642901e078824184e910d3363');
      testPubkeyBytes = compressedKey.sublist(1); // Remove prefix for x-only
      testPubkeyHex = Codec.encodeHex(testPubkeyBytes);
    });

    group('factory Miniscript.pk', () {
      test('Create pk node with valid pubkey', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        expect(pk.op, MiniscriptOp.pk);
        expect(pk.type, MiniscriptType.key);
        expect(pk.pubkeyHex, testPubkeyHex);
        expect(pk.children, isEmpty);
        expect(pk.value, isNull);
      });

      test('Throw exception for empty pubkey', () {
        expect(() => Miniscript.pk(''), throwsFormatException);
      });
    });

    group('factory Miniscript.after', () {
      test('Create after node with valid value', () {
        int sequence = 144;
        Miniscript after = Miniscript.after(sequence);
        expect(after.op, MiniscriptOp.after);
        expect(after.type, MiniscriptType.boolean);
        expect(after.value, sequence);
        expect(after.children, isEmpty);
        expect(after.pubkeyHex, isNull);
      });

      test('Throw exception for zero value', () {
        expect(() => Miniscript.after(0), throwsFormatException);
      });

      test('Throw exception for negative value', () {
        expect(() => Miniscript.after(-1), throwsFormatException);
      });
    });

    group('factory Miniscript.older', () {
      test('Create older node with valid value', () {
        int locktime = 1000000;
        Miniscript older = Miniscript.older(locktime);
        expect(older.op, MiniscriptOp.older);
        expect(older.type, MiniscriptType.boolean);
        expect(older.value, locktime);
        expect(older.children, isEmpty);
        expect(older.pubkeyHex, isNull);
      });

      test('Throw exception for zero value', () {
        expect(() => Miniscript.older(0), throwsFormatException);
      });

      test('Throw exception for negative value', () {
        expect(() => Miniscript.older(-1), throwsFormatException);
      });
    });

    group('factory Miniscript.v', () {
      test('Create v node with pk child', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        expect(v.op, MiniscriptOp.v);
        expect(v.type, MiniscriptType.verify);
        expect(v.children.length, 1);
        expect(v.children[0], pk);
        expect(v.pubkeyHex, isNull);
      });

      test('Throw exception for non-key child', () {
        Miniscript after = Miniscript.after(144);
        expect(() => Miniscript.v(after), throwsArgumentError);
      });
    });

    group('factory Miniscript.andV', () {
      test('Create and_v node with valid children', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript older = Miniscript.older(1000000);
        Miniscript andV = Miniscript.andV(v, older);

        expect(andV.op, MiniscriptOp.and_v);
        expect(andV.type, MiniscriptType.boolean);
        expect(andV.children.length, 2);
        expect(andV.children[0], v);
        expect(andV.children[1], older);
      });

      test('Throw exception for invalid left child type', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript older = Miniscript.older(1000000);
        expect(() => Miniscript.andV(pk, older), throwsArgumentError);
      });

      test('Throw exception for invalid right child type', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript v2 = Miniscript.v(pk);
        expect(() => Miniscript.andV(v, v2), throwsArgumentError);
      });
    });

    group('serializeForDescriptor', () {
      test('Serialize pk node', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        expect(pk.serializeForDescriptor(), 'pk($testPubkeyHex)');
      });

      test('Serialize after node', () {
        Miniscript after = Miniscript.after(144);
        expect(after.serializeForDescriptor(), 'after(144)');
      });

      test('Serialize older node', () {
        Miniscript older = Miniscript.older(1000000);
        expect(older.serializeForDescriptor(), 'older(1000000)');
      });

      test('Serialize v node', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        expect(v.serializeForDescriptor(), 'v:pk($testPubkeyHex)');
      });

      test('Serialize and_v node', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript older = Miniscript.older(1000000);
        Miniscript andV = Miniscript.andV(v, older);
        expect(andV.serializeForDescriptor(),
            'and_v(v:pk($testPubkeyHex),older(1000000))');
      });

      // Note: Cannot test missing pubkeyHex/value directly as Miniscript._ is private
      // These cases are covered by integration tests
    });

    group('serializeForScript', () {
      test('Serialize pk node to script', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        String scriptHex = pk.serializeForScript();
        expect(scriptHex, isNotEmpty);
        expect(scriptHex.length % 2, 0); // Hex string should have even length

        // Verify script structure: <pubkey> OP_CHECKSIG
        Script script = Script(Script.parseToCommand(Codec.decodeHex(scriptHex)));
        expect(script.commands.length, 2);
        expect(script.commands[0], testPubkeyBytes);
        expect(script.commands[1], ScriptOperationCode.getHex('OP_CHECKSIG'));
      });

      test('Serialize v:pk node to script', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        String scriptHex = v.serializeForScript();
        expect(scriptHex, isNotEmpty);

        // Verify script structure: <pubkey> OP_CHECKSIGVERIFY
        Script script = Script(Script.parseToCommand(Codec.decodeHex(scriptHex)));
        expect(script.commands.length, 2);
        expect(script.commands[0], testPubkeyBytes);
        expect(script.commands[1],
            ScriptOperationCode.getHex('OP_CHECKSIGVERIFY'));
      });

      test('Serialize after node to script', () {
        int sequence = 144;
        Miniscript after = Miniscript.after(sequence);
        String scriptHex = after.serializeForScript();
        expect(scriptHex, isNotEmpty);

        // Verify script structure: <sequence> OP_CHECKSEQUENCEVERIFY OP_DROP
        Script script = Script(Script.parseToCommand(Codec.decodeHex(scriptHex)));
        expect(script.commands.length, 3);
        expect(script.commands[0], isA<Uint8List>());
        Uint8List sequenceBytes = script.commands[0] as Uint8List;
        expect(sequenceBytes.length, 4);
        expect(Converter.littleEndianToInt(sequenceBytes), sequence);
        expect(script.commands[1],
            ScriptOperationCode.getHex('OP_CHECKSEQUENCEVERIFY'));
        expect(script.commands[2], ScriptOperationCode.getHex('OP_DROP'));
      });

      test('Serialize older node to script', () {
        int locktime = 1000000;
        Miniscript older = Miniscript.older(locktime);
        String scriptHex = older.serializeForScript();
        expect(scriptHex, isNotEmpty);

        // Verify script structure: <locktime> OP_CHECKLOCKTIMEVERIFY OP_DROP
        Script script = Script(Script.parseToCommand(Codec.decodeHex(scriptHex)));
        expect(script.commands.length, 3);
        expect(script.commands[0], isA<Uint8List>());
        Uint8List locktimeBytes = script.commands[0] as Uint8List;
        expect(locktimeBytes.length, 4);
        expect(Converter.littleEndianToInt(locktimeBytes), locktime);
        expect(script.commands[1],
            ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY'));
        expect(script.commands[2], ScriptOperationCode.getHex('OP_DROP'));
      });

      test('Serialize and_v(v:pk, older) to inheritance script pattern', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript older = Miniscript.older(1000000);
        Miniscript andV = Miniscript.andV(v, older);

        String scriptHex = andV.serializeForScript();
        expect(scriptHex, isNotEmpty);

        // Should match InheritanceScript.withCheckLockTimeVerify structure
        InheritanceScript expectedScript =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPubkeyBytes);
        String expectedHex = expectedScript.rawSerialize();

        expect(scriptHex, expectedHex);
      });

      test('Serialize and_v(v:pk, after) to inheritance script pattern', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript after = Miniscript.after(144);
        Miniscript andV = Miniscript.andV(v, after);

        String scriptHex = andV.serializeForScript();
        expect(scriptHex, isNotEmpty);

        // Should match InheritanceScript.withCheckSequenceVerify structure
        InheritanceScript expectedScript =
            InheritanceScript.withCheckSequenceVerify(144, testPubkeyBytes);
        String expectedHex = expectedScript.rawSerialize();

        expect(scriptHex, expectedHex);
      });

      // Note: Cannot test missing pubkeyHex directly as Miniscript._ is private
      // These cases are covered by integration tests
    });

    group('validate', () {
      test('Validate pk node - no children', () {
        expect(() => Miniscript.validate(MiniscriptOp.pk, []), returnsNormally);
      });

      test('Validate pk node - throw for having children', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        expect(() => Miniscript.validate(MiniscriptOp.pk, [pk]),
            throwsArgumentError);
      });

      test('Validate pk node - throw for empty pubkeyHex', () {
        // This is tested indirectly through factory validation
        expect(() => Miniscript.pk(''), throwsFormatException);
      });

      test('Validate after node - no children', () {
        expect(() => Miniscript.validate(MiniscriptOp.after, []),
            returnsNormally);
      });

      test('Validate after node - throw for having children', () {
        Miniscript after = Miniscript.after(144);
        expect(() => Miniscript.validate(MiniscriptOp.after, [after]),
            throwsArgumentError);
      });

      test('Validate older node - no children', () {
        expect(() => Miniscript.validate(MiniscriptOp.older, []),
            returnsNormally);
      });

      test('Validate older node - throw for having children', () {
        Miniscript older = Miniscript.older(1000000);
        expect(() => Miniscript.validate(MiniscriptOp.older, [older]),
            throwsArgumentError);
      });

      test('Validate v node - exactly one key child', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        expect(() => Miniscript.validate(MiniscriptOp.v, [pk]),
            returnsNormally);
      });

      test('Validate v node - throw for wrong number of children', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        expect(() => Miniscript.validate(MiniscriptOp.v, []),
            throwsArgumentError);
        expect(() => Miniscript.validate(MiniscriptOp.v, [pk, pk]),
            throwsArgumentError);
      });

      test('Validate v node - throw for non-key child', () {
        Miniscript after = Miniscript.after(144);
        expect(() => Miniscript.validate(MiniscriptOp.v, [after]),
            throwsArgumentError);
      });

      test('Validate and_v node - verify and boolean children', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript older = Miniscript.older(1000000);
        expect(() => Miniscript.validate(MiniscriptOp.and_v, [v, older]),
            returnsNormally);
      });

      test('Validate and_v node - throw for wrong number of children', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        expect(() => Miniscript.validate(MiniscriptOp.and_v, []),
            throwsArgumentError);
        expect(() => Miniscript.validate(MiniscriptOp.and_v, [v]),
            throwsArgumentError);
        expect(() => Miniscript.validate(MiniscriptOp.and_v, [v, v, v]),
            throwsArgumentError);
      });

      test('Validate and_v node - throw for wrong left child type', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript older = Miniscript.older(1000000);
        expect(() => Miniscript.validate(MiniscriptOp.and_v, [pk, older]),
            throwsArgumentError);
      });

      test('Validate and_v node - throw for wrong right child type', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        expect(() => Miniscript.validate(MiniscriptOp.and_v, [v, v]),
            throwsArgumentError);
      });

      test('Validate v node - throw for non-pk child in factory', () {
        Miniscript after = Miniscript.after(144);
        expect(() => Miniscript.v(after), throwsArgumentError);
      });
    });

    group('Integration tests', () {
      test('Full inheritance plan: and_v(v:pk, older)', () {
        // Simulate: and_v(v:pk(beneficiary), older(locktime))
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript older = Miniscript.older(1000000);
        Miniscript inheritancePlan = Miniscript.andV(v, older);

        // Test descriptor serialization
        String descriptor = inheritancePlan.serializeForDescriptor();
        expect(descriptor,
            'and_v(v:pk($testPubkeyHex),older(1000000))');

        // Test script serialization matches InheritanceScript
        String scriptHex = inheritancePlan.serializeForScript();
        InheritanceScript expectedScript =
            InheritanceScript.withCheckLockTimeVerify(1000000, testPubkeyBytes);
        expect(scriptHex, expectedScript.rawSerialize());
      });

      test('Full inheritance plan: and_v(v:pk, after)', () {
        // Simulate: and_v(v:pk(beneficiary), after(sequence))
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript after = Miniscript.after(144);
        Miniscript inheritancePlan = Miniscript.andV(v, after);

        // Test descriptor serialization
        String descriptor = inheritancePlan.serializeForDescriptor();
        expect(descriptor, 'and_v(v:pk($testPubkeyHex),after(144))');

        // Test script serialization matches InheritanceScript
        String scriptHex = inheritancePlan.serializeForScript();
        InheritanceScript expectedScript =
            InheritanceScript.withCheckSequenceVerify(144, testPubkeyBytes);
        expect(scriptHex, expectedScript.rawSerialize());
      });

      test('Round trip: descriptor -> script -> parse script', () {
        Miniscript pk = Miniscript.pk(testPubkeyHex);
        Miniscript v = Miniscript.v(pk);
        Miniscript older = Miniscript.older(1000000);
        Miniscript inheritancePlan = Miniscript.andV(v, older);

        String scriptHex = inheritancePlan.serializeForScript();
        InheritanceScript parsedScript = InheritanceScript.parse(scriptHex);

        expect(parsedScript.getTimelockValue(), 1000000);
        expect(parsedScript.getTimelockType(), 'CLTV');
        expect(parsedScript.getBeneficiaryPublicKey(), testPubkeyBytes);
      });
    });
  });
}
