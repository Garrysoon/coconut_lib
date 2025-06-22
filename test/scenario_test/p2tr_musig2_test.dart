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
          'bcrt1pqxpx7h2z7qt5f2jpnmr0x2yplfl7z2perghkymdsdlref7umc0pqdg23fp');

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
      expect(completedTx.serialize(),
          '020000000001019b17422115ffae89c52a1d30a3b06ca23c2cc33755a714243151dc6fa73320600100000000ffffffff02881300000000000022512033a2310b5332888679eb9895a6b7297d6fd94620695f38ab98beb17c8b170d146c3d000000000000225120daaf3b1d59ca6401fda16d0bc787bf9fd9cb0d45b2294b95224981585cb343cd0140db7b6b9ddc1c58a43d5f6acb1cefb9ee8edac6e52af62fd616ba5781fef4f01137089880e27568fe7c72db4fc71c14bce4fb70a01c0cdd7567ccafea4e9416f400000000');
    });
  });
}
