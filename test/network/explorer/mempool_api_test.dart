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
    MockClient mockClient = MockClient();
    MempoolApi.client = mockClient;
    test('host 값이 네트워크에 따라 올바르게 반환되는지 테스트', () {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);
      expect(MempoolApi.host, 'https://mempool.space');

      BitcoinNetwork.setNetwork(BitcoinNetwork.testnet);
      expect(MempoolApi.host, 'https://mempool.space/testnet');

      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
      expect(MempoolApi.host, 'https://regtest-mempool.coconut.onl');
    });

    test('getRecommendFee가 올바른 형식의 응답을 반환하는지 테스트', () async {
      // Given
      final mockResponse = {
        'fastestFee': 100,
        'halfHourFee': 80,
        'hourFee': 60,
        'economyFee': 40,
        'minimumFee': 20
      };

      when(mockClient.get(any)).thenAnswer((_) async {
        print('mockResponse: $mockResponse');
        return Response(json.encode(mockResponse), 200);
      });

      // When
      final fee = await MempoolApi.getRecommendFee();

      // Then
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
