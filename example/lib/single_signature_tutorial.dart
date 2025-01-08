import 'dart:io';
import 'package:coconut_lib/coconut_lib.dart';

void main() async {
  bool isForSending = false;
  /*
  This shows the process from creating a Bitcoin wallet in the Coconut Library to sending Bitcoin.
  Please check that the roles of the Vault and the Wallet are separate.
  Enjoy Bitcoin programming with Coconut Library!
  */

  /// >> In Vault
  /// choose the Bitcoin Network
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  /// generate air-gapped vault
  SingleSignatureVault mnemonicVault = SingleSignatureVault.fromMnemonic(
      'output opera coin bottom power cable abuse bitter maximum cost gift burger',
      AddressType.p2wpkh);

  // >> In Wallet
  /// import expub to watch-only wallet with descriptor(BIP-0380)
  SingleSignatureWallet watchOnlyWallet =
      SingleSignatureWallet.fromDescriptor(mnemonicVault.descriptor);

  /// Obtain the bitcoin from faucet
  print("address : ${watchOnlyWallet.getReceiveAddress()}");

  /// connect to the node and fetch transaction data
  NodeConnector nodeConnector = await NodeConnector.connectSync(
      'regtest-electrum.coconut.onl', 60401,
      ssl: true);

  /// fetch on chain data
  await watchOnlyWallet.fetchOnChainData(nodeConnector);

  print(watchOnlyWallet.walletStatus!.toJson());

  /// and then, check the balance
  print("balance before tx : ${watchOnlyWallet.getBalance()}");

  /// create a PSBT(BIP-0174) to my another address
  PSBT unsignedPSBT = PSBT.fromTransaction(
      Transaction.forPayment(
          "bcrt1q3e20um9mrcwpl34agd07v0t76hg48n97ufjwe20mku7n5nqll32sxawr52",
          100000,
          1,
          watchOnlyWallet),
      watchOnlyWallet);

  print(unsignedPSBT.serialize());

  print("Estimating Fee : ${unsignedPSBT.estimateFee(1, AddressType.p2wpkh)}");

  /// >> In Vault
  /// vault can sign the PSBT
  String signedPsbt =
      mnemonicVault.addSignatureToPsbt(unsignedPSBT.serialize());

  print(signedPsbt);

  /// >> In Wallet
  // watchOnlyWallet can broadcast the signed transaction
  PSBT signedPSBT =
      PSBT.parse(signedPsbt); // parse the PSBT received from vault

  Transaction signedTx = signedPSBT
      .getSignedTransaction(watchOnlyWallet.addressType); // transaction object

  if (isForSending) {
    Result result =
        await nodeConnector.broadcast(signedTx.serialize()); // broadcast
    print(' - Transaction is broadcasted: ${result.value}');
  }

  /// need to sync again
  await watchOnlyWallet.fetchOnChainData(nodeConnector);

  /// check the balance again
  print("balance after tx : ${watchOnlyWallet.getBalance()}");

  exit(0);
}
