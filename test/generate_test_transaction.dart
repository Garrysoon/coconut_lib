@Tags(['regtest-integration'])

import 'dart:convert';
import 'dart:math';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'mock_generator.dart';

DotEnv _testEnv = DotEnv()..load(['.env.test']);

/// 아래 테스트 코드는 실제 Regtest 네트워크에 트랜잭션을 제출합니다.
/// 필요한 케이스만 skip을 해제하여 사용합니다.

void main() async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  SingleSignatureVault vault = getMockSingleVault(TestWalletType.forNormal);
  SingleSignatureWallet wallet =
      SingleSignatureWallet.fromDescriptor(vault.descriptor);

  SingleSignatureVault otherVault =
      getMockSingleVault(TestWalletType.forNormal, passphrase: 'other');
  SingleSignatureWallet otherWallet =
      SingleSignatureWallet.fromDescriptor(otherVault.descriptor);

  MultisignatureVault multiVault =
      getMockMultisignatureVault(TestWalletType.forNormal);
  MultisignatureWallet multiWallet =
      MultisignatureWallet.fromDescriptor(multiVault.descriptor);

  NodeConnector nodeConnector = await NodeConnector.connectSync(
      'regtest-electrum.coconut.onl', 60401,
      ssl: true);

  await wallet.fetchOnChainData(nodeConnector);
  await otherWallet.fetchOnChainData(nodeConnector);
  await multiWallet.fetchOnChainData(nodeConnector);

  multiWallet.saveStatus();
  group('SingleSignatureWallet 트랜잭션 생성', () {
    test('테스트 지갑 faucet 요청', () async {
      var response =
          await _requestFaucet(wallet.getReceiveAddress().address, 100000000);

      expect(response.contains('txHash'), true);
    }, skip: true);
    // });

    test('상대방 주소로 트랜잭션 생성', () async {
      var balance = wallet.getBalance();
      if (balance < 100000000) {
        throw Exception(
            'Wallet balance is less than 100000000, balance: $balance');
      }
      Transaction signedTx = await _generateSendTransaction(
        vault,
        wallet,
        otherWallet.getReceiveAddress().address,
        Random().nextInt(99000) + 1000,
      );

      Result<String, CoconutError> result =
          await nodeConnector.broadcast(signedTx.serialize()); // broadcast

      expect(result.isSuccess, true);
    }, skip: true);
    // });

    test('상대방 지갑에서 전액 회수하기', () async {
      if (otherWallet.getBalance() == 0) {
        throw Exception('Other wallet balance is 0');
      }

      Transaction sweepTx = await _generateSweepTransaction(
        otherVault,
        otherWallet,
        wallet.getReceiveAddress().address,
      );

      Result<String, CoconutError> result =
          await nodeConnector.broadcast(sweepTx.serialize());

      expect(result.isSuccess, true);
    }, skip: true);
    // });
  });

  group('MultiSignatureWallet 트랜잭션 생성', () {
    test('테스트 지갑 faucet 요청', () async {
      var response = await _requestFaucet(
          multiWallet.getReceiveAddress().address, 100000000);

      expect(response.contains('txHash'), true);
    }, skip: true);
    // });

    test('상대방 주소로 트랜잭션 생성', () async {
      var balance = multiWallet.getBalance();
      if (balance < 100000000) {
        throw Exception(
            'Wallet balance is less than 100000000, balance: $balance');
      }

      Transaction signedTx = await _generateSendMultisignatureTransaction(
        multiVault,
        multiWallet,
        otherWallet.getReceiveAddress().address,
        Random().nextInt(99000) + 1000,
      );

      Result<String, CoconutError> result =
          await nodeConnector.broadcast(signedTx.serialize());

      expect(result.isSuccess, true);
    }, skip: true);
    // });

    test('상대방 주소로 RBF 트랜잭션 생성', () async {
      List<Transaction> txs = await _generateSendFullRbfTransaction(
        vault,
        wallet,
        otherWallet.addressBook
            .getAddress(otherWallet.addressBook.usedReceive + 1, false)
            .address,
        otherWallet.addressBook
            .getAddress(otherWallet.addressBook.usedReceive + 2, false)
            .address,
        30000,
      );

      for (Transaction tx in txs) {
        Result<String, CoconutError> result =
            await nodeConnector.broadcast(tx.serialize());

        print('txid: ${result.value}');

        await Future.delayed(const Duration(seconds: 10));

        expect(result.isSuccess, true);
      }
    });

    test('상대방 지갑에서 전액 회수하기', () async {
      if (otherWallet.getBalance() == 0) {
        throw Exception('Other wallet balance is 0');
      }

      Transaction sweepTx = await _generateSweepTransaction(
        otherVault,
        otherWallet,
        wallet.getReceiveAddress().address,
      );

      Result<String, CoconutError> result =
          await nodeConnector.broadcast(sweepTx.serialize());

      expect(result.isSuccess, true);
    }, skip: true);
    // });

    test('내 지갑에서 UTXO 여러 개로 분산하는 트랜잭션 생성', () async {
      Transaction signedTx = await _generateSplitMultisignatureTransaction(
        multiVault,
        multiWallet,
        1000,
        10,
      );

      Result<String, CoconutError> result =
          await nodeConnector.broadcast(signedTx.serialize());

      expect(result.isSuccess, true);
    }, skip: true);
    // });
  });
}

Future<String> _requestFaucet(String address, int satsAmount) async {
  if (satsAmount >= 100000000) {
    satsAmount = 100000000;
  } else if (satsAmount <= 21000) {
    satsAmount = 21000;
  }

  double amount = double.parse(
      (satsAmount / 100000000).toStringAsFixed(8).replaceAll(',', ''));
  String host = _testEnv.getOrElse(
      'REGTEST_API_HOST', () => throw Exception('REGTEST_API_HOST is not set'));
  String path = _testEnv.getOrElse('REGTEST_API_PATH_FAUCET_REQUEST',
      () => throw Exception('REGTEST_API_PATH_FAUCET_REQUEST is not set'));

  var body = json.encode({
    "address": address,
    "amount": amount,
  });

  var response = await post(Uri.parse(host + path),
      headers: {'Content-Type': 'application/json'}, body: body);

  return response.body;
}

Future<Transaction> _generateSendTransaction(VaultFeature vault,
    WalletBase wallet, String receiveAddress, int satsAmount,
    {int feeRate = 1}) async {
  if (satsAmount >= 100000000) {
    satsAmount = 100000000;
  } else if (satsAmount <= 21000) {
    satsAmount = 21000;
  }

  Transaction tx =
      Transaction.forPayment(receiveAddress, satsAmount, feeRate, wallet);
  PSBT unsignedPsbt = PSBT.fromTransaction(tx, wallet);

  String signedPsbtString = vault.addSignatureToPsbt(unsignedPsbt.serialize());

  PSBT signedPsbt =
      PSBT.parse(signedPsbtString); // parse the PSBT received from vault

  return signedPsbt
      .getSignedTransaction(wallet.addressType); // transaction object
}

Future<List<Transaction>> _generateSendFullRbfTransaction(
    SingleSignatureVault vault,
    SingleSignatureWallet wallet,
    String prevAddress,
    String newAddress,
    int amount) async {
  Transaction prevTransaction = await _generateSendTransaction(
      vault, wallet, prevAddress, (amount * 0.9).ceil(),
      feeRate: 1);

  Transaction newTransaction = await _generateSendTransaction(
      vault, wallet, newAddress, amount,
      feeRate: 2);

  return [prevTransaction, newTransaction];
}

Future<Transaction> _generateSweepTransaction(SingleSignatureVault vault,
    SingleSignatureWallet wallet, String address) async {
  Transaction sweepTx = Transaction.forSweep(
    address,
    1,
    wallet,
  );

  PSBT unsignedPsbt = PSBT.fromTransaction(sweepTx, wallet);
  String signedPsbtString = vault.addSignatureToPsbt(unsignedPsbt.serialize());
  PSBT signedPsbt = PSBT.parse(signedPsbtString);
  return signedPsbt.getSignedTransaction(wallet.addressType);
}

Future<Transaction> _generateSendMultisignatureTransaction(
    MultisignatureVault multiVault,
    MultisignatureWallet multiWallet,
    String address,
    int amount) async {
  Transaction tx = Transaction.forPayment(address, amount, 1, multiWallet);
  PSBT unsignedPsbt = PSBT.fromTransaction(tx, multiWallet);

  PSBT signedPsbt = PSBT.parse(multiVault.keyStoreList[2].addSignatureToPsbt(
      multiVault.keyStoreList[1].addSignatureToPsbt(unsignedPsbt.serialize())));

  return signedPsbt.getSignedTransaction(multiWallet.addressType);
}

Future<Transaction> _generateSplitMultisignatureTransaction(
    MultisignatureVault vault,
    MultisignatureWallet wallet,
    int amount,
    int count) async {
  List<UTXO> utxoList = wallet.getUtxoList();
  List<UTXO> toUseUtxoList = [];
  int totalInputAmount = 0;
  List<TransactionInput> inputs = [];
  List<TransactionOutput> outputs = [];

  toUseUtxoList.add(utxoList.reduce((a, b) => a.amount > b.amount ? a : b));

  List<UTXO> remainingUtxos =
      utxoList.where((utxo) => utxo.amount == 548).toList();
  remainingUtxos.sort((a, b) => b.amount.compareTo(a.amount));

  for (int i = 0; i < remainingUtxos.length; i++) {
    if (i > 30) break;
    toUseUtxoList.add(remainingUtxos[i]);
  }

  for (UTXO utxo in toUseUtxoList) {
    totalInputAmount += utxo.amount;
    inputs.add(TransactionInput.forPayment(utxo.transactionHash, utxo.index));
  }
  String changeAddress = wallet.getChangeAddress().address;

  for (int i = 0; i < count; i++) {
    String receiveAddress = wallet
        .getAddress(i + wallet.addressBook.usedReceive + 1, isChange: false);
    TransactionOutput sendingOutput =
        TransactionOutput.forPayment(amount + i, receiveAddress);
    outputs.add(sendingOutput);
  }

  TransactionOutput changeOutput =
      TransactionOutput.forPayment(0, changeAddress);

  outputs.add(changeOutput);

  Transaction tx = Transaction.withDefault(inputs, outputs, wallet.addressType,
      version: 2, lockTime: 0);

  double vByte = 0.0;
  if (wallet.addressType == AddressType.p2wpkh) {
    vByte = tx.estimateVirtualByte(wallet.addressType);
  } else if (wallet.addressType == AddressType.p2wsh) {
    vByte = tx.estimateVirtualByte(wallet.addressType,
        requiredSignature: wallet.requiredSignature,
        totalSigner: wallet.totalSigner);
  } else {
    throw Exception('Unsupported Address Type');
  }
  int fee = (vByte * 1).ceil();
  int changeAmount = totalInputAmount - (amount * count) - fee - 1000;

  if (changeAmount <= 0) {
    for (TransactionOutput output in tx.outputs) {
      if (output.scriptPubKey.getAddress() == changeAddress) {
        tx.outputs.remove(output);
        break;
      }
    }
  } else {
    changeOutput.setAmount(changeAmount);
  }

  PSBT unsignedPsbt = PSBT.fromTransaction(tx, wallet);
  PSBT signedPsbt = PSBT.parse(vault.keyStoreList[2].addSignatureToPsbt(
      vault.keyStoreList[1].addSignatureToPsbt(unsignedPsbt.serialize())));

  return signedPsbt.getSignedTransaction(wallet.addressType);
}
