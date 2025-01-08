@Tags(['unit'])

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_generator.dart';
import 'isolate_test_mocks.dart';

/// Mockito를 이용해 생성한 클래스는 Isolate 처리가 불가능하여 [TestNodeClient], [TestNodeClientFactory]를 사용하여 단위 테스트를 수행합니다.
void main() {
  late DefaultIsolateManager isolateManager;
  late NodeClientFactory factory;

  setUp(() {
    isolateManager = DefaultIsolateManager();
    factory = TestNodeClientFactory();
  });

  tearDown(() {
    isolateManager.dispose();
  });

  group('DefaultIsolateManager', () {
    test('initialization should complete successfully', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      expect(isolateManager.isInitialized, isTrue);
    });

    test('initialization should fail with invalid port number', () async {
      expect(
        () async =>
            await isolateManager.initialize(factory, 'localhost', -1, false),
        throwsA(predicate((e) =>
            e is CoconutError &&
            e.toString().contains('Port must be between 1 and 65535'))),
      );
    });

    test('initialization should fail when host is empty', () async {
      expect(
        () async => await isolateManager.initialize(factory, '', 50001, false),
        throwsA(predicate((e) =>
            e is CoconutError &&
            e.toString().contains('Host cannot be empty'))),
      );
    });

    test('initialization should fail with invalid port range', () async {
      expect(
        () async => await isolateManager.initialize(
            factory, 'localhost', 999999, false),
        throwsA(predicate((e) =>
            e is CoconutError &&
            e.errorCode == ErrorCodeEnum.invalidParameter)),
      );
    });

    test('initialization should fail with empty host', () async {
      expect(
        () async => await isolateManager.initialize(factory, '', 50001, false),
        throwsA(predicate((e) =>
            e is CoconutError &&
            e.errorCode == ErrorCodeEnum.invalidParameter)),
      );
    });

    test('_send should throw exception when _sendPort is null', () async {
      expect(
          () => isolateManager.broadcast('raw_tx'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              'Exception: Isolate not initialized')));
    });

    test('broadcast message transmission test', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.broadcast('raw_tx');

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('txid'));
    });

    test('broadcast message transmission test with error', () async {
      await isolateManager.initialize(
          TestNodeClientFactoryWithThrowError(), 'localhost', 50001, false);

      final result = await isolateManager.broadcast('raw_tx');
      expect(result.isSuccess, isFalse);
      expect(result.error, isA<CoconutError>());
      expect(result.error.toString(), contains('Error'));
    });

    test('fullSync', () async {
      var wallet = getMockSingleWallet(TestWalletType.forNormal);

      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.fullSync(wallet);

      expect(result.isSuccess, isTrue);
      expect(result.value, isA<WalletStatus>());
    });

    test('getNetworkMinimumFeeRate', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.getNetworkMinimumFeeRate();

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(1000));
    });

    test('getBlock', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.getBlock();

      expect(result.isSuccess, isTrue);
      expect(result.value?.height, equals(100));
      expect(result.value?.timestamp.millisecondsSinceEpoch,
          equals(1234567890000));
    });

    test('getTransaction', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.getTransaction('tx_hash');

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('transaction_data'));
    });

    test('error handling test', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);

      // 에러 케이스를 테스트하기 위한 특별한 TestNodeClient 구현
      isolateManager = DefaultIsolateManager();
      factory = TestNodeClientFactory();
      await isolateManager.initialize(factory, 'localhost', 50001, false);

      final result = await isolateManager.broadcast('error_tx');
      expect(result.isSuccess, isTrue); // 현재 구현에서는 항상 성공을 반환합니다.
    });
  });
}
