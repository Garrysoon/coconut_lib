@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
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

    MultisignatureVault musig2Vault1 = MultisignatureVault.fromKeyStoreList([
      keyStore1,
      KeyStore.fromSignerBsms(vault2.getSignerBsms(AddressType.p2trMuSig2, "")),
      KeyStore.fromSignerBsms(vault3.getSignerBsms(AddressType.p2trMuSig2, ""))
    ], 3, addressType: AddressType.p2trMuSig2);

    MultisignatureVault musig2Vault2 = MultisignatureVault.fromKeyStoreList([
      KeyStore.fromSignerBsms(vault1.getSignerBsms(AddressType.p2trMuSig2, "")),
      keyStore2,
      KeyStore.fromSignerBsms(vault3.getSignerBsms(AddressType.p2trMuSig2, ""))
    ], 3, addressType: AddressType.p2trMuSig2);

    MultisignatureVault musig2Vault3 = MultisignatureVault.fromKeyStoreList([
      KeyStore.fromSignerBsms(vault1.getSignerBsms(AddressType.p2trMuSig2, "")),
      KeyStore.fromSignerBsms(vault2.getSignerBsms(AddressType.p2trMuSig2, "")),
      keyStore3
    ], 3, addressType: AddressType.p2trMuSig2);

    Transaction tx = Transaction.forSinglePayment(
        MockFactory.createUtxoList(count: 1),
        vault1.getAddress(1),
        '${vault1.derivationPath}/1/1',
        15000,
        3,
        musig2Vault1);

    String partialNoncePsbt1 =
        Psbt.fromTransaction(tx, musig2Vault1).serialize();

    // add nonce musig2Vault2
    String partialNoncePsbt2 =
        musig2Vault2.addMuSig2PublicNonce(partialNoncePsbt1);

    String nonceCompletedPsbt =
        musig2Vault3.addMuSig2PublicNonce(partialNoncePsbt2);

    String partialSigPsbt1 =
        musig2Vault1.addSignatureToPsbt(nonceCompletedPsbt);
    String partialSigPsbt2 = musig2Vault1.addSignatureToPsbt(partialSigPsbt1);
    String signedPsbt = musig2Vault1.addSignatureToPsbt(partialSigPsbt2);

    // print(partialSigPsbt1);
  });
}
