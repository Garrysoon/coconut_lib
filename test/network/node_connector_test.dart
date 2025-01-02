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

    setUpAll(() async {
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
      test('should create NodeConnector with custom isolateManager', () async {
        // Arrange
        final factory = MockNodeClientFactory();
        when(factory.create('localhost', 50001, ssl: true))
            .thenAnswer((_) async => mockElectrumApi);
        final manager = MockIsolateManager();
        when(manager.getBlock()).thenAnswer(
            (_) async => Result.success(BlockTimestamp(0, DateTime.now())));

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
      verify(mockIsolateManager.fullSync(mockWallet))
          .called(2); // 1 for connectSync, 1 for fetch
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
  });
}
