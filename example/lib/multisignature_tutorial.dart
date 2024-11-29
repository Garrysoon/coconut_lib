import 'dart:io';
import 'package:coconut_lib/coconut_lib.dart';

void main() async {
  bool send = false;
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  //Generate 2-of-3 Multisig Vault with 2 Outside signer
  SingleSignatureVault insideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'ABC');

  SingleSignatureVault outsideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'DEF');

  SingleSignatureVault outsideVault2 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'GHI');

  //Generate P2WSH Keystore
  KeyStore insideKey1 =
      KeyStore.fromSeed(insideVault1.keyStore.seed, AddressType.p2wsh);
  KeyStore outsideKey1 = KeyStore.fromSignerBsms(
      outsideVault1.getSignerBsms(AddressType.p2wsh, "OutsideSigner1"));
  KeyStore outsideKey2 = KeyStore.fromSignerBsms(
      outsideVault2.getSignerBsms(AddressType.p2wsh, "OutsideSigner2"));

  // print(insideKey1.masterFingerprint); //AEF5B293
  // print(outsideKey1.masterFingerprint); //BAD41B33
  // print(outsideKey2.masterFingerprint); //62A936C3

  MultisignatureVault multisignatureVault =
      MultisignatureVault.fromKeyStoreList(
          [insideKey1, outsideKey1, outsideKey2], 2, AddressType.p2wsh);

  // Share Coordinator BSMS with Outside Signers
  MultisignatureVault outsideMultisignatureVault =
      MultisignatureVault.fromCoordinatorBsms(
          multisignatureVault.getCoordinatorBsms());

  // Find Seed in Outside Vault and bind it to KeyStore
  outsideMultisignatureVault.bindSeedToKeyStore(outsideVault1.keyStore.seed);

  // Make WatchOnlyWallet for multisig
  MultisignatureWallet watchOnlyWallet;

  Descriptor descriptor = Descriptor.parse(multisignatureVault.descriptor);
  if (descriptor.scriptType == 'wsh') {
    watchOnlyWallet =
        MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);
    // } else if (descriptor.scriptType == 'wpkh') {
    //   watchOnlyWallet =
    //       SingleSignatureWallet.fromDescriptor(multisignatureVault.descriptor);
  } else {
    throw Exception('Unsupported Address Type');
  }

  print("descriptor: ${multisignatureVault.descriptor}");

  print("${watchOnlyWallet.getReceiveAddress()}");

  /// connect to the node and fetch transaction data
  NodeConnector nodeConnector = await NodeConnector.connectSync(
      'regtest-electrum.coconut.onl', 60401,
      ssl: true);

  /// fetch on chain data
  await watchOnlyWallet.fetchOnChainData(nodeConnector);

  /// and then, check the balance
  print("balance before sending : ${watchOnlyWallet.getBalance()}");

  // PSBT unsignedPSBT = PSBT.forSending(
  //     "bcrt1qjc4p02r0782v5326j3njeeucesly7pnrwnaqft", 4000, 3, watchOnlyWallet);
  PSBT unsignedPSBT = PSBT.forSending(
      "bcrt1qkn8haxetu7gmku4q5lums0yv8f84ze4z6sgjgxq6kw0z5qrfrfkqpgl75y",
      100000,
      1,
      watchOnlyWallet);

  print("Unsigned PSBT: ${unsignedPSBT.serialize()}");

  // Add signature 1
  String insideVaultSigned =
      multisignatureVault.addSignatureToPsbt(unsignedPSBT.serialize());

  print("Inside Vault Signed PSBT: $insideVaultSigned");

  // Add signature 2
  String outsideVaultSigned =
      outsideMultisignatureVault.addSignatureToPsbt(insideVaultSigned);

  print("Outside Vault Signed PSBT: $outsideVaultSigned");

  // If signature is completed, you can broadcast in the watch-only wallet
  PSBT signedPSBT = PSBT.parse(outsideVaultSigned);
  Transaction signedTx =
      signedPSBT.getSignedTransaction(watchOnlyWallet.addressType);

  print("Transaction: ${signedTx.serialize()}");

  if (send) {
    Result result =
        await nodeConnector.broadcast(signedTx.serialize()); // broadcast
    print(' - Transaction is broadcasted: ${result.value}');
  }

  /// need to sync again
  await watchOnlyWallet.fetchOnChainData(nodeConnector);

  /// check the balance again
  print("balance after sending: ${watchOnlyWallet.getBalance()}");

  for (Transfer tf in watchOnlyWallet.getTransferList()) {
    print("${tf.timestamp} ${tf.transferType} ${tf.amount} ${tf.fee}");
  }

  exit(0);
}
