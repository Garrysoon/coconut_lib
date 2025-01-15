// ignore_for_file: unused_import
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/utils/converter.dart';
import 'package:coconut_lib/src/utils/hash.dart';

import 'mock_generator.dart';

void main() async {
  /// >> In Vault
  /// choose the Bitcoin Network
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  /// generate air-gapped vault
  SingleSignatureVault mnemonicVault = SingleSignatureVault.fromMnemonic(
      'dress obvious vendor case rookie bring goat sudden trend fun myth nest',
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

  print(watchOnlyWallet.getBalance());

  Transaction tx = Transaction.forPayment(
      watchOnlyWallet.getAddress(5), 9999200, 1, watchOnlyWallet);

  for (TransactionOutput output in tx.outputs) {
    print(output.amount);
  }
}
