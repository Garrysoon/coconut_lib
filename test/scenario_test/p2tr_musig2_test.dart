@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('P2TR MuSig2', () {
    late MultisignatureVault musig2Vault1;
    late MultisignatureVault musig2Vault2;
    late MultisignatureVault musig2Vault3;
    late List<Utxo> utxoList;
    late Transaction tx;
    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);

      SingleSignatureVault vault1 =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      SingleSignatureVault vault2 =
          MockFactory.createP2wpkhVault(passphrase: 'B');
      SingleSignatureVault vault3 =
          MockFactory.createP2wpkhVault(passphrase: 'C');

      KeyStore keyStore1 =
          KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2trMuSig2);
      KeyStore keyStore2 =
          KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2trMuSig2);
      KeyStore keyStore3 =
          KeyStore.fromSeed(vault3.keyStore.seed, AddressType.p2trMuSig2);

      musig2Vault1 = MultisignatureVault.fromKeyStoreList([
        keyStore1,
        KeyStore.fromSignerBsms(
            vault2.getSignerBsms(AddressType.p2trMuSig2, "")),
        KeyStore.fromSignerBsms(
            vault3.getSignerBsms(AddressType.p2trMuSig2, ""))
      ], 3, addressType: AddressType.p2trMuSig2);

      musig2Vault2 = MultisignatureVault.fromKeyStoreList([
        KeyStore.fromSignerBsms(
            vault1.getSignerBsms(AddressType.p2trMuSig2, "")),
        keyStore2,
        KeyStore.fromSignerBsms(
            vault3.getSignerBsms(AddressType.p2trMuSig2, ""))
      ], 3, addressType: AddressType.p2trMuSig2);

      musig2Vault3 = MultisignatureVault.fromKeyStoreList([
        KeyStore.fromSignerBsms(
            vault1.getSignerBsms(AddressType.p2trMuSig2, "")),
        KeyStore.fromSignerBsms(
            vault2.getSignerBsms(AddressType.p2trMuSig2, "")),
        keyStore3
      ], 3, addressType: AddressType.p2trMuSig2);

      utxoList = MockFactory.createUtxoList(
          count: 1, derivationPath: "m/86'/1'/0'/0/0");
      tx = Transaction.forSinglePayment(utxoList, musig2Vault1.getAddress(1),
          '${musig2Vault1.derivationPath}/1/1', 15000, 3, musig2Vault1);
    });
    test('Add signature to psbt scenario', () {
      String partialNoncePsbt1 =
          Psbt.fromTransaction(tx, musig2Vault1).serialize();
      // print("partialNoncePsbt1 : $partialNoncePsbt1");

      // add nonce musig2Vault2
      String partialNoncePsbt2 =
          musig2Vault2.addMuSig2PublicNonce(partialNoncePsbt1);
      // print("partialNoncePsbt2 : $partialNoncePsbt2");

      String nonceCompletedPsbt =
          musig2Vault3.addMuSig2PublicNonce(partialNoncePsbt2);
      // print("nonceCompletedPsbt : $nonceCompletedPsbt");

      String partialSigPsbt1 =
          musig2Vault1.addSignatureToPsbt(nonceCompletedPsbt);
      // print("partialSigPsbt1 : $partialSigPsbt1");
      String partialSigPsbt2 = musig2Vault2.addSignatureToPsbt(partialSigPsbt1);
      // print("partialSigPsbt2 : $partialSigPsbt2");
      String partialSigPsbt3 = musig2Vault3.addSignatureToPsbt(partialSigPsbt2);
      // print("partialSigPsbt3 : $partialSigPsbt3");

      Psbt completedPsbt = Psbt.parse(partialSigPsbt3);

      // print("completedPsbt : ${completedPsbt.serialize()}");

      Transaction completedTx =
          completedPsbt.getSignedTransaction(AddressType.p2trMuSig2);
      // print("completedTx : ${completedTx.serialize()}");

      // print("completedPsbt : $completedPsbt");
    });
  });
}
