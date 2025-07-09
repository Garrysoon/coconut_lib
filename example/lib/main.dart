// ignore_for_file: unused_local_variable

import 'package:coconut_lib/coconut_lib.dart';

void main() async {
  print("0. Set the Bitcoin Network");
  NetworkType.setNetworkType(NetworkType.regtest);

  print("1-1. Create a single signature vault");
  Seed seed = Seed.fromMnemonic(
      'thank split shrimp error own spirit slow glow act evidence globe slight');

  SingleSignatureVault singleSignatureVault =
      SingleSignatureVault.fromSeed(seed);
  print(
      ' - Master Fingerprint: ${singleSignatureVault.keyStore.masterFingerprint}');

  print("1-2. Create a 2-of-3 Multisignature vault");
  SingleSignatureVault insideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      passphrase: 'ABC');

  SingleSignatureVault outsideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      passphrase: 'DEF');

  SingleSignatureVault outsideVault2 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      passphrase: 'GHI');

  //Generate P2WSH Keystore
  KeyStore insideKey1 =
      KeyStore.fromSeed(insideVault1.keyStore.seed, AddressType.p2wsh);
  KeyStore outsideKey1 = KeyStore.fromSignerBsms(
      outsideVault1.getSignerBsms(AddressType.p2wsh, "OutsideSigner1"));
  KeyStore outsideKey2 = KeyStore.fromSignerBsms(
      outsideVault2.getSignerBsms(AddressType.p2wsh, "OutsideSigner2"));

  MultisignatureVault multisignatureVault =
      MultisignatureVault.fromKeyStoreList(
          [insideKey1, outsideKey1, outsideKey2], 2);

  // Share Coordinator BSMS with Outside Signers
  MultisignatureVault outsideMultisignatureVault =
      MultisignatureVault.fromCoordinatorBsms(
          multisignatureVault.getCoordinatorBsms());

  // Find Seed in Outside Vault and bind it to KeyStore
  outsideMultisignatureVault.bindSeedToKeyStore(outsideVault1.keyStore.seed);

  print(
      ' - Master Fingerprint of Key Store [0]: ${multisignatureVault.keyStoreList[0].masterFingerprint}');
  print(
      ' - Master Fingerprint of Key Store [1]: ${multisignatureVault.keyStoreList[1].masterFingerprint}');
  print(
      ' - Master Fingerprint of Key Store [2]: ${multisignatureVault.keyStoreList[2].masterFingerprint}');

  print("2-1. Sync to the single signature wallet");
  // Repository.initialize('Coconut_Wallet');
  SingleSignatureWallet singleSignatureWallet =
      SingleSignatureWallet.fromDescriptor(singleSignatureVault.descriptor);
  print(
      ' - Extended Public Key: ${singleSignatureWallet.keyStore.extendedPublicKey.serialize()}');

  print("2-2. Sync to the multisignature wallet");
  MultisignatureWallet multisignatureWallet;

  Descriptor descriptor = Descriptor.parse(multisignatureVault.descriptor);
  if (descriptor.scriptType == 'wsh') {
    multisignatureWallet =
        MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);
    // } else if (descriptor.scriptType == 'wpkh') {
    //   watchOnlyWallet =
    //       SingleSignatureWallet.fromDescriptor(multisignatureVault.descriptor);
  } else {
    throw Exception('Unsupported Address Type');
  }
  print(
      ' - Extended Public Key of Key Store [0]: ${multisignatureWallet.keyStoreList[0].extendedPublicKey.serialize()}');
  print(
      ' - Extended Public Key of Key Store [1]: ${multisignatureWallet.keyStoreList[1].extendedPublicKey.serialize()}');
  print(
      ' - Extended Public Key of Key Store [2]: ${multisignatureWallet.keyStoreList[2].extendedPublicKey.serialize()}');

  print(
      "4. Send Bitcoin from the single signature wallet to the multisignature wallet");
  String receiverAddress = multisignatureWallet.getAddress(0);
  String changeAddress = singleSignatureWallet.getAddress(0, isChange: true);
  int sendingAmount = 1000;
  double feeRate = 3.0;
  List<Utxo> utxosForSingleSignatureWallet = [
    Utxo('5c5fa04bc94647ee339083d6fd381a3b1ac4de7d7bfa966788971d62072a1e66', 1,
        100000000, "m/84'/1'/0'/0/68")
  ];
  print(' - Generating unsigned PSBT');
  List<Utxo> utxoList = [
    Utxo('393a2d56f910019a6df975672989a449648f355b1fb7889fb831f0402c5550f3', 0,
        21000, "m/84'/1'/0'/0/0")
  ];
  Transaction unsignedTransaction = Transaction.forSinglePayment(utxoList,
      receiverAddress, "m/84'/1'/0'/1/0", 2000, 2, singleSignatureWallet);
  String unsignedPsbt =
      Psbt.fromTransaction(unsignedTransaction, singleSignatureWallet)
          .serialize();

  print(' - Add signature from vault');
  String signedPsbt = singleSignatureVault.addSignatureToPsbt(unsignedPsbt);
  Psbt walletReceivedPsbt = Psbt.parse(signedPsbt);
  Transaction signedTransaction = walletReceivedPsbt
      .getSignedTransaction(singleSignatureWallet.addressType);
  print(' - Final Transaction : ${signedTransaction.serialize()}');
}
