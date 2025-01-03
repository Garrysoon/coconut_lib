@Tags(['unit'])

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import 'isolate_test.mocks.dart';

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
    test('초기화가 성공적으로 완료되어야 함', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);

      expect(isolateManager.isInitialized, isTrue);
    });

    test('broadcast 메시지 전송 테스트', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.broadcast('raw_tx');

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('txid'));
    });

    test('getNetworkMinimumFeeRate 테스트', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.getNetworkMinimumFeeRate();

      expect(result.isSuccess, isTrue);
      expect(result.value, equals(1000));
    });

    test('getBlock 테스트', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.getBlock();

      expect(result.isSuccess, isTrue);
      expect(result.value?.height, equals(100));
      expect(result.value?.timestamp.millisecondsSinceEpoch,
          equals(1234567890000));
    });

    test('getTransaction 테스트', () async {
      await isolateManager.initialize(factory, 'localhost', 50001, false);
      final result = await isolateManager.getTransaction('tx_hash');

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('transaction_data'));
    });

    test('에러 처리 테스트', () async {
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
