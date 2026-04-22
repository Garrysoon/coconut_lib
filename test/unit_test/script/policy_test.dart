@Tags(['unit'])
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('Policy', () {
    late TaprootVault beneficiaryVault;
    late InheritancePolicy inheritancePolicy;

    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
      beneficiaryVault = MockFactory.createBeneficiaryVault(passphrase: 'A');
      inheritancePolicy =
          InheritancePolicy.fromDescriptor(beneficiaryVault.descriptor, 1798761600);
    });

    group('fromMiniscript', () {
      test('parses inheritance miniscript', () {
        final Policy p =
            Policy.fromMiniscript(inheritancePolicy.toMiniscript());
        expect(p, isA<InheritancePolicy>());
        expect((p as InheritancePolicy).locktime, inheritancePolicy.locktime);
      });

      test('throws for unsupported miniscript', () {
        expect(() => Policy.fromMiniscript('pk(k)'), throwsException);
      });
    });

    group('fromJson', () {
      test('deserializes typed inheritance policy JSON', () {
        final Policy p = Policy.fromJson(inheritancePolicy.toJson());
        expect(p, isA<InheritancePolicy>());
        final InheritancePolicy ip = p as InheritancePolicy;
        expect(ip.locktime, inheritancePolicy.locktime);
        expect(ip.beneficiaryKeyStore.masterFingerprint,
            inheritancePolicy.beneficiaryKeyStore.masterFingerprint);
      });

      test('deserializes legacy JSON with miniscript field only', () {
        final String legacy = jsonEncode(<String, String>{
          'miniscript': inheritancePolicy.toMiniscript(),
        });
        final Policy p = Policy.fromJson(legacy);
        expect(p, isA<InheritancePolicy>());
      });

      test('throws when type is unsupported', () {
        final String json = jsonEncode(<String, String>{
          'type': 'unknown_type',
          'dummy': 'x',
        });
        expect(() => Policy.fromJson(json), throwsException);
      });

      test('throws when neither type nor miniscript present', () {
        expect(() => Policy.fromJson('{}'), throwsException);
      });
    });

    group('getTapleafHash', () {
      test('returns 32-byte TapLeaf tagged hash', () {
        expect(inheritancePolicy.getTapleafHash(0).length, 32);
      });

      test('matches Policy restored from miniscript', () {
        final Policy restored =
            Policy.fromMiniscript(inheritancePolicy.toMiniscript());
        expect(restored.getTapleafHash(0),
            inheritancePolicy.getTapleafHash(0));
      });
    });
  });
}
