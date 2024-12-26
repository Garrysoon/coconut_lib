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
    WalletBase wallet, String receiveAddress, int satsAmount) async {
  if (satsAmount >= 100000000) {
    satsAmount = 100000000;
  } else if (satsAmount <= 21000) {
    satsAmount = 21000;
  }

  Transaction tx =
      Transaction.forPayment(receiveAddress, satsAmount, 1, wallet);
  PSBT unsignedPsbt = PSBT.fromTransaction(tx, wallet);

  String signedPsbtString = vault.addSignatureToPsbt(unsignedPsbt.serialize());

  PSBT signedPsbt =
      PSBT.parse(signedPsbtString); // parse the PSBT received from vault

  return signedPsbt
      .getSignedTransaction(wallet.addressType); // transaction object
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
    int i) async {
  Transaction tx = Transaction.forPayment(address, i, 1, multiWallet);
  PSBT unsignedPsbt = PSBT.fromTransaction(tx, multiWallet);

  PSBT signedPsbt = PSBT.parse(multiVault.keyStoreList[2].addSignatureToPsbt(
      multiVault.keyStoreList[1].addSignatureToPsbt(unsignedPsbt.serialize())));

  return signedPsbt.getSignedTransaction(multiWallet.addressType);
}
