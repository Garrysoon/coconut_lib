@Tags(['unit'])
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('Psbt.isForVault', () {
    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
    });

    test('matches only the single signature vault that owns the key', () {
      final SingleSignatureVault vaultA = MockFactory.createP2wpkhVault();
      final SingleSignatureVault vaultB =
          MockFactory.createP2wpkhVault(passphrase: 'vaultB');

      final Transaction txForA = Transaction.forSinglePayment(
          MockFactory.createUtxoList(count: 1),
          vaultA.getAddress(1),
          '${vaultA.derivationPath}/1/1',
          15000,
          3,
          vaultA);
      final Psbt psbtForVaultA = Psbt.fromTransaction(txForA, vaultA);

      expect(psbtForVaultA.isForVault(vaultA), isTrue);
      expect(psbtForVaultA.isForVault(vaultB), isFalse);
    });

    test('distinguishes multisig vaults with same keys but different required signers', () {
      final SingleSignatureVault signerA =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      final SingleSignatureVault signerB =
          MockFactory.createP2wpkhVault(passphrase: 'B');
      final SingleSignatureVault signerC =
          MockFactory.createP2wpkhVault(passphrase: 'C');

      final KeyStore keyStoreA =
          KeyStore.fromSeed(signerA.keyStore.seed, AddressType.p2wsh);
      final KeyStore keyStoreB =
          KeyStore.fromSeed(signerB.keyStore.seed, AddressType.p2wsh);
      final KeyStore keyStoreC =
          KeyStore.fromSeed(signerC.keyStore.seed, AddressType.p2wsh);
      final List<KeyStore> keyStores = [keyStoreA, keyStoreB, keyStoreC];

      final MultisignatureVault vault2Of3 =
          MultisignatureVault.fromKeyStoreList(keyStores, 2);
      final MultisignatureVault vault3Of3 =
          MultisignatureVault.fromKeyStoreList(keyStores, 3);

      final Transaction txFor2Of3 = Transaction.forSinglePayment(
          MockFactory.createUtxoList(
              count: 1, derivationPath: "${vault2Of3.derivationPath}/0/0"),
          vault2Of3.getAddress(1),
          '${vault2Of3.derivationPath}/1/1',
          15000,
          3,
          vault2Of3);
      final Psbt psbtFor2Of3 = Psbt.fromTransaction(txFor2Of3, vault2Of3);

      final Transaction txFor3Of3 = Transaction.forSinglePayment(
          MockFactory.createUtxoList(
              count: 1, derivationPath: "${vault3Of3.derivationPath}/0/0"),
          vault3Of3.getAddress(1),
          '${vault3Of3.derivationPath}/1/1',
          15000,
          3,
          vault3Of3);
      final Psbt psbtFor3Of3 = Psbt.fromTransaction(txFor3Of3, vault3Of3);

      expect(psbtFor2Of3.isForVault(vault2Of3), isTrue);
      expect(psbtFor2Of3.isForVault(vault3Of3), isFalse);
      expect(psbtFor3Of3.isForVault(vault2Of3), isFalse);
      expect(psbtFor3Of3.isForVault(vault3Of3), isTrue);
    });

    test('matches only the exact taproot vault parent and child key set', () {
      final KeyStore parentA1 = KeyStore.fromSeed(
          Seed.fromMnemonic(
              utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
              passphrase: utf8.encode('parentA1')),
          AddressType.p2tr);
      final KeyStore parentA2 = KeyStore.fromSeed(
          Seed.fromMnemonic(
              utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
              passphrase: utf8.encode('parentA2')),
          AddressType.p2tr);
      final TaprootVault childA = MockFactory.createBeneficiaryVault(passphrase: 'childA');
      final Policy childPolicyA = InheritancePolicy.fromDescriptorAndLocktime(childA.descriptor, 1767225600);
      final TaprootVault vaultA = TaprootVault.fromKeyStoreList([parentA1, parentA2], [childPolicyA]);

      final TaprootVault vaultB = TaprootVault.fromKeyStoreList([parentA1], [childPolicyA]);

      const int addressIndex = 0;
      final Utxo utxo = Utxo(
          '0b5b43a8a09f1021bac4f4357c2808043b409231b42fc0143050ac37668a984b', 0, 21000, "m/86'/1'/0'/0/$addressIndex");
      final Transaction txForA =
          Transaction.forSinglePayment([utxo], MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 20000, 1, vaultA);
      final Psbt psbtForVaultA = Psbt.fromTransaction(txForA, vaultA);
      final Transaction txForB =
          Transaction.forSinglePayment([utxo], MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 20000, 1, vaultB);
      final Psbt psbtForVaultB = Psbt.fromTransaction(txForB, vaultB);

      expect(psbtForVaultA.isForVault(vaultA), isTrue);
      expect(psbtForVaultA.isForVault(vaultB), isFalse);
      expect(psbtForVaultB.isForVault(vaultA), isFalse);
      expect(psbtForVaultB.isForVault(vaultB), isTrue);
    });

    test('only beneficiary locktime diff of taproot wallets', () {
      final KeyStore parentA1 = KeyStore.fromSeed(
          Seed.fromMnemonic(
              utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
              passphrase: utf8.encode('parentA1')),
          AddressType.p2tr);
      final KeyStore parentA2 = KeyStore.fromSeed(
          Seed.fromMnemonic(
              utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
              passphrase: utf8.encode('parentA2')),
          AddressType.p2tr);
      final TaprootVault childA = MockFactory.createBeneficiaryVault(passphrase: 'childA');
      final Policy childPolicyA = InheritancePolicy.fromDescriptorAndLocktime(childA.descriptor, 1767225600);
      final Policy childPolicyB = InheritancePolicy.fromDescriptorAndLocktime(childA.descriptor, 1767225601);
      final TaprootVault vaultA = TaprootVault.fromKeyStoreList([parentA1, parentA2], [childPolicyA]);
      final TaprootVault vaultB = TaprootVault.fromKeyStoreList([parentA1, parentA2], [childPolicyB]);

      const int addressIndex = 0;
      final Utxo utxo = Utxo(
          '0b5b43a8a09f1021bac4f4357c2808043b409231b42fc0143050ac37668a984b', 0, 21000, "m/86'/1'/0'/0/$addressIndex");

      final Transaction txForA =
          Transaction.forSinglePayment([utxo], MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 20000, 1, vaultA);
      final Transaction txForB =
          Transaction.forSinglePayment([utxo], MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 20000, 1, vaultB);

      final Psbt psbtForVaultA = Psbt.fromTransaction(txForA, vaultA);
      final Psbt psbtForVaultB = Psbt.fromTransaction(txForB, vaultB);

      expect(psbtForVaultA.isForVault(vaultA), isTrue);
      expect(psbtForVaultA.isForVault(vaultB), isFalse);
      expect(psbtForVaultB.isForVault(vaultA), isFalse);
      expect(psbtForVaultB.isForVault(vaultB), isTrue);
    });
  });
}
