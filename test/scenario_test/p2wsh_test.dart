@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
    NetworkType.setNetworkType(NetworkType.mainnet);
    SingleSignatureVault vault1 =
        MockFactory.createP2wpkhVault(passphrase: 'A');
    SingleSignatureVault vault2 =
        MockFactory.createP2wpkhVault(passphrase: 'B');
    SingleSignatureVault vault3 =
        MockFactory.createP2wpkhVault(passphrase: 'C');

    KeyStore keyStore1 =
        KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2wsh);
    KeyStore keyStore2 =
        KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2wsh);
    KeyStore keyStore3 =
        KeyStore.fromSeed(vault3.keyStore.seed, AddressType.p2wsh);

    MultisignatureVault multiSigVault1 = MultisignatureVault.fromKeyStoreList([
      keyStore1,
      KeyStore.fromSignerBsms(vault2.getSignerBsms(AddressType.p2wsh, "")),
      KeyStore.fromSignerBsms(vault3.getSignerBsms(AddressType.p2wsh, ""))
    ], 2, addressType: AddressType.p2wsh);

    MultisignatureVault multiSigVault2 =
        MultisignatureVault.fromCoordinatorBsms(
            multiSigVault1.getCoordinatorBsms());
    multiSigVault2.bindSeedToKeyStore(keyStore2.seed);

    // ignore: unused_local_variable
    MultisignatureVault multiSigVault3 =
        MultisignatureVault.fromCoordinatorBsms(
            multiSigVault1.getCoordinatorBsms());
    multiSigVault2.bindSeedToKeyStore(keyStore3.seed);

    MultisignatureWallet wallet =
        MultisignatureWallet.fromDescriptor(multiSigVault1.descriptor);

    Psbt unsignedTx = MockFactory.createP2wshUnsignedPsbt();

    expect(unsignedTx.isForVault(multiSigVault1), true);
    expect(unsignedTx.isForVault(multiSigVault2), true);
    expect(unsignedTx.isForVault(MockFactory.createP2wshVault()), false);

    expect(unsignedTx.addressType, AddressType.p2wsh);

    String signed1PsbtText =
        multiSigVault1.addSignatureToPsbt(unsignedTx.serialize());
    // print(signed1PsbtText);
    String signed2PsbtText = multiSigVault2.addSignatureToPsbt(signed1PsbtText);
    // String signed3PsbtText = multiSigVault3.addSignatureToPsbt(signed2PsbtText);

    // print(Psbt.parse(signed3PsbtText).inputs[0].partialSig!.length);

    Transaction signedTransaction =
        Psbt.parse(signed2PsbtText).getSignedTransaction(wallet.addressType);

    expect(
        signedTransaction.serialize(),
        MockFactory.createP2wshSignedPsbt()
            .getSignedTransaction(wallet.addressType)
            .serialize());
  });
}
