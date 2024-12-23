// ignore_for_file: unused_import
import 'dart:io';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/utils/converter.dart';
import 'package:coconut_lib/src/utils/hash.dart';
import 'mock_generator.dart';

void main() async {
  SingleSignatureWallet wallet = getMockSingleWallet(TestWalletType.manyTx);
  wallet.walletStatus = await getWalletStatus(TestWalletType.manyTx);

  for (UTXO utxo in wallet.walletStatus!.utxoList) {
    print('UTXO: ${utxo.amount} ${utxo.transactionHash}');
  }
}
