@Tags(['unit'])
import 'dart:math';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() {
  late SingleSignatureWallet mockWallet;
  late List<UTXO> utxos;
  String receiveAddress = 'bcrt1q8e5ghfg8gpe4dlfv7qqck2c2jc47lnllul3puh';
  setUpAll(() async {
    NetworkType.setNetworkType(NetworkType.regtest);

    mockWallet = getMockSingleWallet(TestWalletType.forNormal);
  });
  group('Transaction', () {
    group('Transaction.withDefault', () {
      test('', () {});
    });
    group('Transaction.fromUtxoList', () {
      test('Change amount is under dust', () {
        // Transaction tx = Transaction.fromUtxoList(
        //     utxos.sublist(0, 1), receiveAddress, 99800, 1, mockWallet);
        // int inputAmount = 0;
        // int outputAmount = 0;
        // for (UTXO u in tx.utxoList) {
        //   inputAmount += u.amount;
        // }
        // for (TransactionOutput output in tx.outputs) {
        //   outputAmount += output.amount;
        // }

        // expect(
        //     inputAmount >=
        //         outputAmount + tx.estimateFee(1, mockWallet.addressType),
        //     true);
        // expect(tx.outputs.length, 1);
      });
      test('Generate tx with change', () {
        // Transaction tx = Transaction.fromUtxoList(
        //     utxos, receiveAddress, 4200, 1, mockWallet);
        // expect(tx.outputs.length, 2);
      });
    });

    group('Transaction.forPayment', () {
      test('Generate p2wpkh transaction', () {
        //TODO
      });
    });
    group('Transaction.forSweep', () {
      test('', () {
        //TODO
      });
    });
    group('Transaction.fromOnChainData', () {
      test('', () {});
    });
    group('Transaction.parse', () {
      test('', () {});
    });
    group('Transaction.parseUnsignedTransaction', () {
      test('', () {});
    });
    group('serialize', () {
      test('Serialize segwit tx', () {
        String segwitTx =
            '02000000000101a463a7a78daffa1bdb1248121adb14b94f70a1fabffc81637f4049c3d65cc69f00000000000000008002e803000000000000160014b247a00acc1cc2c0b4be0d3c38d866f9c08d244a051f000000000000160014d32c7c4dbb9457cff124c786bac87a9a706c5b3a02483045022100c2ce833d29b2bc4048e54fb5a9cb5131f31fe1254d4510339f3bfa2b6c3fe8120220576e45c680b2ab2fa184cf2b6caf7a165b1d5fc61cc165073017104011bfdc42012103324172078ccc5a19cf6db18b0c4bbd135b9d86131d6666bbd494c9474b3eb52600000000';
        Transaction tx = Transaction.parse(segwitTx);
        expect(tx.serialize(), segwitTx);
      });

      test('Serialize legacy tx', () {
        String segwitTx =
            '0100000001d06050454abde3bdd947312b9f54439acb097608a47b0b36a23d76820a3a4044000000006a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8dfffffffff01277c5d000000000016001424b3e9491f3eadd9862389d98480acf89bdab07800000000';
        Transaction tx = Transaction.parse(segwitTx);
        expect(tx.serialize(), segwitTx);
      });
    });
    group('getSigHash', () {
      test('', () {});
    });
    group('validateSignature', () {
      test('', () {});
    });
    group('getVirtualByte', () {
      test('', () {});
    });
    group('estimateVirtualByte', () {
      test('', () {});
    });
    group('calculateFeeWithWitnessSize', () {
      test('', () {});
    });
    group('estimateFee', () {
      test('', () {});
    });
    group('hasNoSignature', () {
      test('', () {});
    });
    group('hasAllSignature', () {
      test('', () {});
    });
    group('addInputWithUtxo', () {
      test('', () {});
    });
    group('addInputWithUtxo', () {
      test('Add utxo', () {
        // int feeRate = 2;

        // Transaction tx =
        //     Transaction.forPayment(receiveAddress, 3200, feeRate, mockWallet);
        // int beforeInputLength = tx.inputs.length;

        // tx.addInputWithUtxo(utxos[5], feeRate, mockWallet);

        // int afterInputLength = tx.inputs.length;

        // int inputAmount = 0;
        // for (UTXO u in tx.utxoList) {
        //   inputAmount += u.amount;
        // }
        // int outputAmount = 0;
        // for (TransactionOutput output in tx.outputs) {
        //   outputAmount += output.amount;
        // }

        // expect(afterInputLength, beforeInputLength + 1);
        // expect(
        //     inputAmount >=
        //         outputAmount + tx.estimateFee(feeRate, mockWallet.addressType),
        //     true);
      });
      test('Add utxo in dust change case', () {
        // int feeRate = 2;

        // Transaction tx = Transaction.fromUtxoList(
        //     utxos.sublist(0, 3), receiveAddress, 320200, feeRate, mockWallet);
        // int beforeInputLength = tx.inputs.length;

        // tx.addInputWithUtxo(utxos[5], feeRate, mockWallet);
        // int afterInputLength = tx.inputs.length;
        // int inputAmount = 0;
        // for (UTXO u in tx.utxoList) {
        //   inputAmount += u.amount;
        // }
        // int outputAmount = 0;
        // for (TransactionOutput output in tx.outputs) {
        //   outputAmount += output.amount;
        // }
        // expect(afterInputLength, beforeInputLength + 1);
        // expect(tx.outputs.length, 1);
        // expect(
        //     inputAmount >=
        //         outputAmount + tx.estimateFee(feeRate, mockWallet.addressType),
        //     true);
      });
    });
    group('removeInputWithUtxo', () {
      test('Remove utxo in dust change case', () {
        // int feeRate = 2;
        // mockWallet.walletStatus!.utxoList = utxos;
        // Transaction tx = Transaction.fromUtxoList(
        //     utxos.sublist(0, 4), receiveAddress, 299300, feeRate, mockWallet);
        // int beforeInputLength = tx.inputs.length;

        // tx.removeInputWithUtxo(utxos[3], feeRate, mockWallet);
        // int afterInputLength = tx.inputs.length;
        // int inputAmount = 0;
        // for (UTXO u in tx.utxoList) {
        //   inputAmount += u.amount;
        // }
        // int outputAmount = 0;
        // for (TransactionOutput output in tx.outputs) {
        //   outputAmount += output.amount;
        // }
        // expect(afterInputLength, beforeInputLength - 1);
        // expect(tx.outputs.length, 1);
        // expect(
        //     inputAmount >=
        //         outputAmount + tx.estimateFee(feeRate, mockWallet.addressType),
        //     true);
      });
      test('Remove utxo', () {
        // int feeRate = 2;
        // Transaction tx = Transaction.fromUtxoList(
        //     utxos.sublist(0, 4), receiveAddress, 100000, feeRate, mockWallet);
        // int beforeInputLength = tx.inputs.length;

        // tx.removeInputWithUtxo(utxos[3], feeRate, mockWallet);
        // int afterInputLength = tx.inputs.length;

        // int inputAmount = 0;
        // for (UTXO u in tx.utxoList) {
        //   inputAmount += u.amount;
        // }

        // int outputAmount = 0;
        // for (TransactionOutput output in tx.outputs) {
        //   outputAmount += output.amount;
        // }

        // expect(afterInputLength, beforeInputLength - 1);
        // expect(tx.outputs.length, 2);
        // expect(
        //     inputAmount >=
        //         outputAmount + tx.estimateFee(feeRate, mockWallet.addressType),
        //     true);
      });
    });
    group('updateFeeRate', () {
      test('Lower fee rate', () {
        // int beforeFeeRate = 4;
        // int afterFeeRate = 2;
        // Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
        //     receiveAddress, 240000, beforeFeeRate, mockWallet);

        // int beforeChange = tx.outputs[1].amount;

        // tx.updateFeeRate(afterFeeRate, mockWallet);
        // int afterChange = tx.outputs[1].amount;
        // expect(afterChange > beforeChange, true);
      });

      test('Higher fee rate', () {
        // int beforeFeeRate = 2;
        // int afterFeeRate = 4;
        // Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
        //     receiveAddress, 240000, beforeFeeRate, mockWallet);
        // int beforeChange = tx.outputs[1].amount;

        // tx.updateFeeRate(afterFeeRate, mockWallet);
        // int afterChange = tx.outputs[1].amount;

        // expect(afterChange < beforeChange, true);
      });
      test('Higher fee rate and dust threshold', () {
        // int beforeFeeRate = 2;
        // int afterFeeRate = 5;

        // Transaction tx = Transaction.fromUtxoList(utxos.sublist(0, 4),
        //     receiveAddress, 398200, beforeFeeRate, mockWallet);

        // tx.updateFeeRate(afterFeeRate, mockWallet);
        // int inputAmount = 0;
        // int outputAmount = 0;
        // for (TransactionOutput output in tx.outputs) {
        //   outputAmount += output.amount;
        // }
        // for (UTXO u in tx.utxoList) {
        //   inputAmount += u.amount;
        // }
        // expect(tx.outputs.length, 1);
        // expect(
        //     inputAmount >=
        //         outputAmount +
        //             tx.estimateFee(afterFeeRate, mockWallet.addressType),
        //     true);
      });
    });
    group('getChangeAmount', () {
      test('add/remove utxo', () {});
    });
    group('getSendingAmount', () {
      test('add/remove utxo', () {});
    });
    group('toJson', () {
      test('add/remove utxo', () {});
    });
    group('Transaction.fromJson', () {
      test('add/remove utxo', () {});
    });
  });
}
