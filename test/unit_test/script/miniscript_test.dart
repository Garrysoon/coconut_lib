@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('Miniscript', () {
    late TaprootVault beneficiaryVault;

    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
      beneficiaryVault = MockFactory.createBeneficiaryVault(passphrase: 'C');
    });

    group('factories', () {
      test('pk rejects empty pubkey hex', () {
        expect(() => Miniscript.pk(''), throwsFormatException);
      });

      test('after and older reject non-positive values', () {
        expect(() => Miniscript.after(0), throwsFormatException);
        expect(() => Miniscript.older(-1), throwsFormatException);
      });

      test('validate rejects pk with children', () {
        expect(
            () => Miniscript.validate(
                MiniscriptOperation.pk, [Miniscript.pk('11')]),
            throwsArgumentError);
      });

      test('validate rejects v without key child', () {
        expect(
            () => Miniscript.v(Miniscript.older(10)),
            throwsArgumentError);
      });

      test('validate rejects and_v with wrong child types', () {
        expect(
            () => Miniscript.andV(Miniscript.pk('ab'), Miniscript.older(10)),
            throwsArgumentError);
      });
    });

    group('serializeForDescriptor', () {
      test('serializes inheritance-like tree', () {
        final String pkHex = Codec.encodeHex(
            beneficiaryVault.keyStoreList[0].getPublicKeyBytes(0,
                isXOnly: true));
        final Miniscript tree =
            Miniscript.forInheritance(1767225600, pkHex);
        expect(
            tree.serializeForDescriptor(),
            'and_v(v:pk($pkHex),older(1767225600))');
      });
    });

    group('serializeForScript', () {
      test('matches InheritancePolicy tapscript bytes for same keys', () {
        const int locktime = 1767225600;
        final KeyStore ks = beneficiaryVault.keyStoreList[0];
        final InheritancePolicy policy = InheritancePolicy(ks, locktime);

        final String pkHex = Codec.encodeHex(ks.getPublicKeyBytes(0, isXOnly: true));
        final Miniscript tree = Miniscript.forInheritance(locktime, pkHex);

        expect(
            tree.serializeForScript().toLowerCase(),
            policy.toScript(0).rawSerialize().toLowerCase());
      });

      test('after compiles to CSV drop pattern', () {
        final String fromMiniscript = Miniscript.after(42).serializeForScript();
        final String expected = Script(<dynamic>[
          Converter.intToLittleEndianBytes(42, 4),
          ScriptOperationCode.getHex('OP_CHECKSEQUENCEVERIFY'),
          ScriptOperationCode.getHex('OP_DROP'),
        ]).rawSerialize();
        expect(fromMiniscript.toLowerCase(), expected.toLowerCase());
      });
    });

    group('forBackup', () {
      test('returns pk-only miniscript', () {
        final String pkHex = Codec.encodeHex(
            beneficiaryVault.keyStoreList[0].getPublicKeyBytes(1,
                isXOnly: true));
        expect(
            Miniscript.forBackup(pkHex).serializeForDescriptor(),
            'pk($pkHex)');
      });
    });
  });
}
