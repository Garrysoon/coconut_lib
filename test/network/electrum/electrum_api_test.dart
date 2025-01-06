@Tags(['unit', 'network'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/network/electrum/electrum_response_types.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../mock_generator.dart';
import 'electrum_api_test.mocks.dart';

@GenerateMocks([ElectrumClient])
void main() async {
  group('ElectrumApi Tests', () {
    MockElectrumClient client = MockElectrumClient();
    when(client.connectionStatus).thenReturn(SocketConnectionStatus.connected);
    ElectrumApi electrumApi =
        ElectrumApi('localhost', 1234, ssl: false, client: client);
    SingleSignatureWallet wallet =
        getMockSingleWallet(TestWalletType.forNormal);

    setUp(() {
      when(client.getTransaction(any)).thenAnswer((_) async => '');
      when(client.getHistory(any)).thenAnswer((_) async => []);
      when(client.getUnspentList(any)).thenAnswer((_) async => []);
      when(client.getCurrentBlock()).thenAnswer((_) async => BlockHeaderSubscribe(
          height: 1000,
          hex:
              '000000203075fe151ad71408f237b917e953f3056515087246b7b5d522120c6fb9e65b166907739518f1a8d826146a96079c4d018d9695161645a78d5bdfe76ef2a08bdc7c647b67ffff7f2000000000'));
    });

    test('ElectrumApi factory', () {
      MockElectrumClient disconnectedClient = MockElectrumClient();
      when(disconnectedClient.connectionStatus)
          .thenReturn(SocketConnectionStatus.reconnecting);
      when(disconnectedClient.connect(any, any, ssl: anyNamed('ssl')))
          .thenAnswer((_) async {});

      ElectrumApi('localhost', 1234, ssl: false, client: disconnectedClient);

      verify(disconnectedClient.connect('localhost', 1234, ssl: false))
          .called(1);
    });

    test('connectSync', () async {
      MockElectrumClient mockClient = MockElectrumClient();
      when(mockClient.connect(any, any, ssl: false)).thenAnswer((_) async {});
      when(mockClient.connectionStatus)
          .thenReturn(SocketConnectionStatus.connected);

      await ElectrumApi.connectSync('localhost', 1234,
          ssl: false, client: mockClient);

      verify(mockClient.connect(any, any, ssl: false)).called(1);
    });

    test('broadcast successful', () async {
      when(client.broadcast(any)).thenAnswer((_) async => 'transaction_id');
      var result = await electrumApi.broadcast('raw_transaction');
      expect(result.isSuccess, true);
      expect(result.value, 'transaction_id');
    });

    test('broadcast failure', () async {
      when(client.broadcast(any)).thenThrow(Exception('Broadcast Error'));
      var result = await electrumApi.broadcast('invalid_transaction');
      expect(result.isFailure, true);
    });

    test('fullSync successful', () async {
      var result = await electrumApi.fullSync(wallet);

      expect(result.isSuccess, true);
    });

    test('fullSync successful with some data', () async {
      int historyCount = 5;
      int unspentCount = historyCount;
      Map<String, Transaction> transactionMap = {};

      when(client.getHistory(any)).thenAnswer((_) async {
        if (historyCount > 0) {
          historyCount--;
          var transaction = getMockTransaction(_.positionalArguments[0], 1000);
          transactionMap[transaction.transactionHash] = transaction;
          return [
            GetHistoryRes(txHash: transaction.transactionHash, height: 123),
          ];
        }
        return [];
      });
      when(client.getUnspentList(any)).thenAnswer((_) async {
        if (unspentCount > 0) {
          unspentCount--;
          var transaction = getMockTransaction(_.positionalArguments[0], 1000);
          return [
            ListUnspentRes(
                txHash: transaction.transactionHash,
                txPos: 0,
                value: 1000,
                height: 123),
          ];
        }
        return [];
      });
      when(client.getTransaction(any)).thenAnswer((_) async =>
          transactionMap[_.positionalArguments[0]]?.serialize() ?? '');
      when(client.getBlockHeader(any))
          .thenAnswer((_) async => getMockBlockHeaderSubscribe().hex);

      var result = await electrumApi.fullSync(wallet);

      expect(result.isSuccess, true);
      expect(result.value?.receiveMaxGap, 24);
      expect(result.value?.utxoList.length, 5);
      expect(result.value?.transactionList.length, 5);
    });

    test('fullSync failure', () async {
      when(client.getHistory(any)).thenThrow(Exception('Sync Error'));
      var result = await electrumApi.fullSync(wallet);
      expect(result.isFailure, true);
      expect(result.error!.errorCode, ErrorCodeEnum.unknownError);
    });

    test('getNetworkMinimumFeeRate no-mempool-tx', () async {
      when(client.getMempoolFeeHistogram()).thenAnswer((_) async => []);
      var result = await electrumApi.getNetworkMinimumFeeRate();
      expect(result.isSuccess, true);
      expect(result.value, 1);
    });

    test('getNetworkMinimumFeeRate', () async {
      when(client.getMempoolFeeHistogram()).thenAnswer((_) async => [
            [5, 1000],
            [3, 2000]
          ]);
      var result = await electrumApi.getNetworkMinimumFeeRate();
      expect(result.isSuccess, true);
      expect(result.value, 3);
    });

    test('getTransaction successful', () async {
      when(client.getTransaction(any))
          .thenAnswer((_) async => 'transaction_data');
      var result = await electrumApi.getTransaction('valid_tx_hash');
      expect(result.isSuccess, true);
      expect(result.value, 'transaction_data');
    });

    test('getTransaction failure', () async {
      when(client.getTransaction(any))
          .thenThrow(Exception('Transaction Error'));
      var result = await electrumApi.getTransaction('invalid_tx_hash');
      expect(result.isFailure, true);
    });

    test('getBlock', () async {
      when(client.getCurrentBlock()).thenAnswer((_) async => BlockHeaderSubscribe(
          height: 1000,
          hex:
              '000000203075fe151ad71408f237b917e953f3056515087246b7b5d522120c6fb9e65b166907739518f1a8d826146a96079c4d018d9695161645a78d5bdfe76ef2a08bdc7c647b67ffff7f2000000000'));
      var result = await electrumApi.getBlock();
      expect(result.isSuccess, true);
      expect(result.value?.height, 1000);
    });
  });

  group('ElectrumApi fetch', () {});
}
