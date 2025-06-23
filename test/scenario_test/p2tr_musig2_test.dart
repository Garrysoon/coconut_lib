// @Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('P2TR MuSig2', () {
    late KeyStore keyStore1;
    late KeyStore keyStore2;
    late KeyStore keyStore3;
    late MultisignatureVault musig2Vault1;
    late MultisignatureVault musig2Vault2;

    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
      int requiredSigners = 2;

      SingleSignatureVault vault1 =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      SingleSignatureVault vault2 =
          MockFactory.createP2wpkhVault(passphrase: 'B');
      SingleSignatureVault vault3 =
          MockFactory.createP2wpkhVault(passphrase: 'C');

      keyStore1 =
          KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2trMuSig2);
      keyStore2 =
          KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2trMuSig2);
      keyStore3 =
          KeyStore.fromSeed(vault3.keyStore.seed, AddressType.p2trMuSig2);

      musig2Vault1 = MultisignatureVault.fromKeyStoreList([
        keyStore1,
        KeyStore.fromSignerBsms(
            vault2.getSignerBsms(AddressType.p2trMuSig2, "")),
        // KeyStore.fromSignerBsms(
        //     vault3.getSignerBsms(AddressType.p2trMuSig2, ""))
      ], requiredSigners, addressType: AddressType.p2trMuSig2);

      musig2Vault2 = MultisignatureVault.fromKeyStoreList([
        KeyStore.fromSignerBsms(
            vault1.getSignerBsms(AddressType.p2trMuSig2, "")),
        keyStore2,
        // KeyStore.fromSignerBsms(
        //     vault3.getSignerBsms(AddressType.p2trMuSig2, ""))
      ], requiredSigners, addressType: AddressType.p2trMuSig2);
    });
    test('Connect to other wallet', () {
      NetworkType.setNetworkType(NetworkType.regtest);
      MultisignatureWallet descriptorWallet =
          MultisignatureWallet.fromDescriptor(musig2Vault1.descriptor);
      MultisignatureVault bsmsWallet = MultisignatureVault.fromCoordinatorBsms(
          musig2Vault1.getCoordinatorBsms());
      expect(musig2Vault1.getAddress(0), descriptorWallet.getAddress(0));
      expect(bsmsWallet.getAddress(0), descriptorWallet.getAddress(0));
    });
    test('Add signature to psbt scenario (2-of-2)', () {
      late List<Utxo> utxoList;
      late Transaction tx;
      utxoList = MockFactory.createUtxoList(
          count: 1, derivationPath: "m/86'/1'/0'/0/0");
      tx = Transaction.forSinglePayment(utxoList, musig2Vault1.getAddress(1),
          '${musig2Vault1.derivationPath}/1/1', 15000, 3, musig2Vault1);
      String unsignedPsbt = Psbt.fromTransaction(tx, musig2Vault1).serialize();

      String partialNoncePsbt1 =
          musig2Vault1.addMuSig2PublicNonce(unsignedPsbt);

      String partialNoncePsbt2 =
          musig2Vault2.addMuSig2PublicNonce(partialNoncePsbt1);

      String partialSigPsbt1 =
          musig2Vault1.addSignatureToPsbt(partialNoncePsbt2);

      String partialSigPsbt2 = musig2Vault2.addSignatureToPsbt(partialSigPsbt1);

      Psbt completedPsbt = Psbt.parse(partialSigPsbt2);

      Transaction completedTx =
          completedPsbt.getSignedTransaction(AddressType.p2trMuSig2);
      expect(completedTx, isA<Transaction>());
    });
    test('3-of-3 test', () {
      late List<Utxo> utxoList;
      late Transaction tx;

      MultisignatureVault multisigVault = MultisignatureVault.fromKeyStoreList(
          [keyStore1, keyStore2, keyStore3], 3,
          addressType: AddressType.p2trMuSig2);
      utxoList = MockFactory.createUtxoList(
          count: 1, derivationPath: "m/86'/1'/0'/0/0");
      tx = Transaction.forSinglePayment(utxoList, musig2Vault1.getAddress(1),
          '${musig2Vault1.derivationPath}/1/1', 15000, 3, musig2Vault1);

      String unsignedPsbt = Psbt.fromTransaction(tx, multisigVault).serialize();
      String noncedPsbt = multisigVault.addMuSig2PublicNonce(unsignedPsbt);
      String sigedPsbt = multisigVault.addSignatureToPsbt(noncedPsbt);
      Transaction completedTx =
          Psbt.parse(sigedPsbt).getSignedTransaction(AddressType.p2trMuSig2);
      expect(completedTx, isA<Transaction>());
      // print("partialNoncePsbt1 : $partialNoncePsbt1");
    });
    test('For regtest', () {
      NetworkType.setNetworkType(NetworkType.regtest);

      expect(musig2Vault1.getAddress(0),
          'bcrt1pz84pa09qudgk23c98a640w5qz47zgyv2f79gzyytlc5ec5m7yvnq6j30r5');

      Utxo utxo = Utxo(
          '602033a76fdc51312414a75537c32c3ca26cb0a3301d2ac589aeff152142179b',
          1,
          21000,
          "m/86'/1'/0'/0/0");
      Transaction tx = Transaction.forSinglePayment([utxo],
          musig2Vault1.getAddress(1), "m/86'/1'/0'/1/0", 5000, 2, musig2Vault1);
      String unsignedPsbt = Psbt.fromTransaction(tx, musig2Vault1).serialize();
      String partialNoncePsbt1 =
          musig2Vault1.addMuSig2PublicNonce(unsignedPsbt);
      String partialNoncePsbt2 =
          musig2Vault2.addMuSig2PublicNonce(partialNoncePsbt1);
      String partialSigPsbt1 =
          musig2Vault1.addSignatureToPsbt(partialNoncePsbt2);
      String partialSigPsbt2 = musig2Vault2.addSignatureToPsbt(partialSigPsbt1);
      Psbt completedPsbt = Psbt.parse(partialSigPsbt2);
      Transaction completedTx =
          completedPsbt.getSignedTransaction(AddressType.p2trMuSig2);
      expect(completedTx, isA<Transaction>());
    });
  });
}
