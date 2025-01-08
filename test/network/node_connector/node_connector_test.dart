@Tags(['unit', 'network'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'node_connector_test.mocks.dart';

@GenerateMocks([ElectrumApi, IsolateManager, WalletBase, NodeClientFactory])
void main() async {
  group('NodeConnector Tests', () {
    late MockElectrumApi mockElectrumApi;
    late MockIsolateManager mockIsolateManager;
    late MockNodeClientFactory mockFactory;
    late NodeConnector nodeConnector;
    late MockWalletBase mockWallet;

    setUp(() async {
      mockElectrumApi = MockElectrumApi();
      mockIsolateManager = MockIsolateManager();
      mockFactory = MockNodeClientFactory();
      mockWallet = MockWalletBase();

      when(mockFactory.create('localhost', 50001, ssl: true))
          .thenAnswer((_) async => mockElectrumApi);
      when(mockIsolateManager.getBlock()).thenAnswer(
          (_) async => Result.success(BlockTimestamp(0, DateTime.now())));
      when(mockIsolateManager.broadcast('raw_tx')).thenAnswer(
          (_) async => Result<String, CoconutError>.success('txid'));
      when(mockIsolateManager.getNetworkMinimumFeeRate())
          .thenAnswer((_) async => Result.success(1000));
      when(mockIsolateManager.fullSync(mockWallet))
          .thenAnswer((_) async => Result.success(WalletStatus(
                transactionList: [],
                utxoList: [],
                balance: Balance(0, 0),
                blockHeaderMap: {},
                receiveAddressBalanceMap: {},
                changeAddressBalanceMap: {},
                receiveUsedIndexList: [],
                changeUsedIndexList: [],
                receiveMaxGap: 0,
                changeMaxGap: 0,
              )));
      nodeConnector = await NodeConnector.connectSync(
        'localhost',
        50001,
        ssl: true,
        nodeClientFactory: mockFactory,
        isolateManager: mockIsolateManager,
      );
    });

    group('create', () {
      test('should create NodeConnector with default isolateManager', () async {
        await expectLater(
          NodeConnector.connectSync('localhost', 50001),
          throwsA(
            isA<CoconutError>()
                .having((error) => error.errorCode, 'errorCode',
                    ErrorCodeEnum.electrumApiError)
                .having((error) => error.message, 'message',
                    'Can not connect to the server. Please connect and try again.'),
          ),
        );
      });

      test('should create NodeConnector with custom isolateManager', () async {
        // Arrange
        final now = DateTime.now();
        final factory = MockNodeClientFactory();
        when(factory.create('localhost', 50001, ssl: true))
            .thenAnswer((_) async => mockElectrumApi);
        final manager = MockIsolateManager();
        when(manager.getBlock())
            .thenAnswer((_) async => Result.success(BlockTimestamp(0, now)));

        // Act
        final connector = await NodeConnector.connectSync(
          'localhost',
          50001,
          nodeClientFactory: factory,
          isolateManager: manager,
        );

        // Assert
        verify(manager.initialize(factory, 'localhost', 50001, true)).called(1);
        expect(connector, isA<NodeConnector>());
        expect(connector.host, 'localhost');
        expect(connector.port, 50001);
        expect(connector.ssl, true);
        expect(connector.connectionStatus, SocketConnectionStatus.connected);

        // 0.1초 이내로 차이가 나면 통과
        expect(
            connector.lastBlockUpdatedAt!.difference(now).inMilliseconds.abs(),
            lessThan(100));
      });
    });

    test('fetch should return error when already syncing', () async {
      // Act
      nodeConnector.fetch(mockWallet);
      final isSyncing = nodeConnector.isSyncing;
      final secondFetch = nodeConnector.fetch(mockWallet);

      // Assert
      expect(isSyncing, true);
      expect(
        await secondFetch,
        isA<Result<WalletStatus, CoconutError>>()
            .having((result) => result.isFailure, 'isFailure', true)
            .having(
              (result) => result.error?.errorCode,
              'error code',
              ErrorCodeEnum.alreadySyncing,
            ),
      );
    });

    test('fetch should return error when not connected', () async {
      nodeConnector.dispose();
      final result = await nodeConnector.fetch(mockWallet);

      expect(result.isFailure, true);
      expect(result.error?.errorCode, ErrorCodeEnum.electrumRpcError);
    });

    test('fetch should delegate to isolateManager when connected', () async {
      // Arrange
      final expectedStatus = WalletStatus(
        transactionList: [],
        utxoList: [],
        balance: Balance(0, 0),
        blockHeaderMap: {},
        receiveAddressBalanceMap: {},
        changeAddressBalanceMap: {},
        receiveUsedIndexList: [],
        changeUsedIndexList: [],
        receiveMaxGap: 0,
        changeMaxGap: 0,
      );

      when(mockIsolateManager.fullSync(mockWallet))
          .thenAnswer((_) async => Result.success(expectedStatus));

      // Act
      final result = await nodeConnector.fetch(mockWallet);

      // Assert
      expect(result.isSuccess, true);
      expect(result.value, expectedStatus);
      verify(mockIsolateManager.fullSync(mockWallet)).called(1);
    });

    test('stopFetching should dispose resources', () async {
      // Act
      nodeConnector.stopFetching();

      // Assert
      verify(mockIsolateManager.dispose()).called(1);
    });

    test('broadcast should delegate to network', () async {
      // Arrange

      // Act
      final result = await nodeConnector.broadcast('raw_tx');

      // Assert
      expect(result, isA<Result<String, CoconutError>>());
      verify(mockIsolateManager.broadcast('raw_tx')).called(1);
    });

    test('should return block timestamp', () {
      expect(nodeConnector.currentBlock, isA<BlockTimestamp>());
      verify(mockIsolateManager.getBlock()).called(1);
    });

    test('should return getNetworkMinimumFeeRate', () async {
      expect(await nodeConnector.getNetworkMinimumFeeRate(),
          isA<Result<int, CoconutError>>());
      verify(mockIsolateManager.getNetworkMinimumFeeRate()).called(1);
    });

    test('should return getTransaction', () async {
      when(mockIsolateManager.getTransaction('txHash'))
          .thenAnswer((_) async => Result.success('tx'));
      expect(await nodeConnector.getTransaction('txHash'),
          isA<Result<String, CoconutError>>());

      verify(mockIsolateManager.getTransaction('txHash')).called(1);
    });
  });
}
