@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('TaprootVault', () {
    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
    });

    test('fromSeedList creates vault', () {
      final vault = TaprootVault.fromSeedList(
          [MockFactory.getCommonSeed(passphrase: 'A')], []);
      expect(vault.keyStoreList.length, 1);
      expect(vault.getAddress(0).startsWith('bcrt1p'), true);
    });

    test('toJson/fromJson roundtrip with policies (seedless via descriptor)',
        () {
      final original = TaprootVault.fromDescriptor(
          MockFactory.createP2trVaultWithPolicies().descriptor);
      final restored = TaprootVault.fromJson(original.toJson());
      expect(restored.keyStoreList.length, original.keyStoreList.length);
      expect(restored.policyList.length, original.policyList.length);
      expect(restored.derivationPath, original.derivationPath);
    });

    test('fromJson throws when wallet payload is passed', () {
      final wallet = TaprootWallet.fromDescriptor(
          MockFactory.createP2trVaultWithPolicies().descriptor);
      expect(() => TaprootVault.fromJson(wallet.toJson()), throwsException);
    });

    test('fromHeritorDescriotor throws on non-taproot descriptor', () {
      final p2wpkh = MockFactory.createP2wpkhVault();
      expect(() => TaprootVault.fromDescriptor(p2wpkh.descriptor),
          throwsException);
    });

    test('fromCoordinatorBsms builds key stores from coordinator payload', () {
      final multisig = MockFactory.createP2wshVault();
      final coordinator = multisig.getCoordinatorBsms();
      final vault = TaprootVault.fromCoordinatorBsms(coordinator);
      expect(vault.keyStoreList.length, multisig.keyStoreList.length);
      expect(vault.policyList, isEmpty);
    });

    test('bindSeedToBeneficiaryKeyStore does not throw when no match', () {
      final vault = MockFactory.createP2trVaultWithPolicies();
      final otherSeed = MockFactory.getCommonSeed(passphrase: 'not-matching');
      expect(() => vault.bindSeedToBeneficiaryKeyStore(otherSeed),
          returnsNormally);
    });

    test('getSpendablePolicy throws when no beneficiary seed exists', () {
      final vault = MockFactory.createP2trVaultWithPolicies();
      expect(() => vault.getSpendablePolicy(), throwsException);
    });

    test('addPublicNonce returns same psbt for single-key vault', () {
      final vault = MockFactory.createP2trKeyPathSpendingVault();
      final psbt =
          MockFactory.createP2trKeyPathSpendingUnsignedPsbt().serialize();
      expect(vault.addPublicNonce(psbt), psbt);
    });

    test('addPublicNonce throws when no keyStore can sign', () {
      final vault = MockFactory.createP2trKeyPathSpendingVault();
      final psbt = MockFactory.createP2wpkhUnsignedPsbt().serialize();
      expect(() => vault.addPublicNonce(psbt), throwsException);
    });
  });
}
