import 'dart:io';
import 'package:coconut_lib/coconut_lib.dart';

void main() async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  SingleSignatureVault insideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'ABC');

  SingleSignatureVault insideVault2 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'DEF');

  SingleSignatureVault outsideVault = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'GHI');

  //Generate P2WSH Keystore
  KeyStore insideKey1 =
      KeyStore.fromSeed(insideVault1.keyStore.seed, AddressType.p2wsh);
  KeyStore insideKey2 =
      KeyStore.fromSeed(insideVault2.keyStore.seed, AddressType.p2wsh);
  String signerBsms =
      outsideVault.getBsmsForSigner(AddressType.p2wsh, "MyHardWallet");
  KeyStore outsideKey = KeyStore.fromBsmsSigner(signerBsms);

  MultisignatureVault multisignatureVault =
      MultisignatureVault.fromKeyStoreList(
          [insideKey1, insideKey2, outsideKey], 2, AddressType.p2wsh);

  // Start : In Outside Vault
  MultisignatureVault outsideMultisignatureVault =
      MultisignatureVault.fromBsmsCoordinator(
          multisignatureVault.getBsmsForCoordinator());

  // Find Seed in Outside Vault and bind it to KeyStore
  outsideMultisignatureVault.bindSeedToKeyStore(
      outsideVault.keyStore.seed, outsideVault.accountIndex);

  // Start : In Outside Vault

  dynamic watchOnlyWallet;

  Descriptor descriptor = Descriptor.parse(multisignatureVault.descriptor);
  if (descriptor.scriptType == 'wsh') {
    watchOnlyWallet =
        MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);
  } else if (descriptor.scriptType == 'wpkh') {
    watchOnlyWallet =
        SingleSignatureWallet.fromDescriptor(multisignatureVault.descriptor);
  } else {
    throw Exception('Unsupported Address Type');
  }

  print("address : ${watchOnlyWallet.getReceiveAddress()}");

  /// connect to the node and fetch transaction data
  NodeConnector nodeConnector = await NodeConnector.connectSync(
      'regtest-electrum.coconut.onl', 60401,
      ssl: true);

  /// fetch on chain data
  await watchOnlyWallet.fetchOnChainData(nodeConnector);

  /// and then, check the balance
  print("balance : ${watchOnlyWallet.getBalance()}");

  PSBT unsignedPSBT = PSBT.forSending(
      "bcrt1qkn8haxetu7gmku4q5lums0yv8f84ze4z6sgjgxq6kw0z5qrfrfkqpgl75y",
      1000,
      3,
      watchOnlyWallet);

//   print("Usigned : " + unsignedPSBT.serialize());

  String insideVaultSigned =
      multisignatureVault.addSignatureToPsbt(unsignedPSBT.serialize());

//   print("Inside Vault Signed : " + insideVaultSigned);

  String outsideVaultSigned =
      outsideMultisignatureVault.addSignatureToPsbt(insideVaultSigned);

  print("Outside Vault Signed : " + outsideVaultSigned);

  PSBT signedPSBT = PSBT.parse(outsideVaultSigned);
  Transaction signedTx =
      signedPSBT.getSignedTransaction(watchOnlyWallet.addressType);

  for (String witness in signedTx.inputs[0].witnessList) {
    print("Witness : " + witness);
  }

  print("TX : " + signedTx.serialize());

  exit(0);
}
