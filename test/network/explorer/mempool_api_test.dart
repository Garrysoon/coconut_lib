@Tags(['unit'])

import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mempool_api_test.mocks.dart';

@GenerateMocks([Client])
void main() {
  group('MempoolApi', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      MempoolApi.client = mockClient;
    });

    group('host 값 테스트', () {
      test('mainnet에서 올바른 host를 반환해야 함', () {
        BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);
        expect(MempoolApi.host, 'https://mempool.space');
      });

      test('testnet에서 올바른 host를 반환해야 함', () {
        BitcoinNetwork.setNetwork(BitcoinNetwork.testnet);
        expect(MempoolApi.host, 'https://mempool.space/testnet');
      });

      test('regtest에서 올바른 host를 반환해야 함', () {
        BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
        expect(MempoolApi.host, 'https://regtest-mempool.coconut.onl');
      });
    });

    test('getRecommendFee가 올바른 형식의 응답을 반환해야 함', () async {
      final mockResponse = {
        'fastestFee': 100,
        'halfHourFee': 80,
        'hourFee': 60,
        'economyFee': 40,
        'minimumFee': 20
      };

      when(mockClient.get(any)).thenAnswer((_) async {
        return Response(json.encode(mockResponse), 200);
      });

      final fee = await MempoolApi.getRecommendFee();

      expect(fee.fastestFee, isA<int>());
      expect(fee.halfHourFee, isA<int>());
      expect(fee.hourFee, isA<int>());
      expect(fee.economyFee, isA<int>());
      expect(fee.minimumFee, isA<int>());

      expect(fee.fastestFee, 100);
      expect(fee.halfHourFee, 80);
      expect(fee.hourFee, 60);
      expect(fee.economyFee, 40);
      expect(fee.minimumFee, 20);
    });
  });
}
