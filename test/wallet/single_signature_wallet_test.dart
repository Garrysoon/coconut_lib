@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  WalletStatus mockWalletStatus =
      await getMockWalletStatus(TestWalletType.forNormal);
  SingleSignatureWallet mockWallet =
      getMockSingleWallet(TestWalletType.forNormal);
  mockWallet.walletStatus = mockWalletStatus;

  group('SingleSignatureWallet', () {
    group('getUtxoList', () {
      test('파라미터가 없을 경우 전체 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList();

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
      });

      test('count 갯수만큼 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(cursor: 0, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.transactionHash,
            '8a6ad9e7e143c97b24c969ed4b5bb84ce40b6fae78fef17208a36e4c0346e0ae');
        expect(utxoList.last.transactionHash,
            '5799e62fcb1fb1ce6c196ae5e990c6a1166b864fc2cc09be1fb3afd8a75a022f');
      });

      test('cursor 위치 부터 count 갯수만큼 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(cursor: 3, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.transactionHash,
            '5799e62fcb1fb1ce6c196ae5e990c6a1166b864fc2cc09be1fb3afd8a75a022f');
        expect(utxoList.last.transactionHash,
            '2eeb34dcf8c780d19afeaee41056e55a5c736e03784307c9d123ce64aea209a3');
      });

      test('cursor가 전체 UTXO 갯수보다 클 경우 빈 리스트를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(cursor: 100, count: 5);

        expect(utxoList.isEmpty, isTrue);
      });

      test('count가 전체 UTXO 갯수보다 클 경우 전체 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(cursor: 0, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
      });

      test('order 파라미터가 금액 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            mockWallet.getUtxoList(order: UtxoOrderEnum.byAmountAsc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 21000);
        expect(utxoList.last.amount, 5000000);
      });

      test('금액 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            mockWallet.getUtxoList(order: UtxoOrderEnum.byAmountDesc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 5000000);
        expect(utxoList.last.amount, 21000);
      });

      test('타임스탬프 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            mockWallet.getUtxoList(order: UtxoOrderEnum.byTimestampAsc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.timestamp, 1723540500);
        expect(utxoList.last.timestamp, 1734078600);
      });

      test('타임스탬프 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            mockWallet.getUtxoList(order: UtxoOrderEnum.byTimestampDesc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.timestamp, 1734078600);
        expect(utxoList.last.timestamp, 1723540500);
      });

      test('order 파라미터가 없을 경우 UTXO를 타임스탬프 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList();

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.timestamp, 1734078600);
        expect(utxoList.last.timestamp, 1723540500);
      });

      test('금액 오름차순, cursor 3, count 7 테스트', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountAsc, cursor: 3, count: 7);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 7);
        expect(utxoList.first.amount, 100000);
        expect(utxoList.last.amount, 100000);
      });

      test('타임스탬프 오름차순, cursor 5, count 5 테스트', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, cursor: 5, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.timestamp, 1725434700);
        expect(utxoList.last.timestamp, 1725873600);
      });
    });

    group('getTransferList', () {});
  });
}
