@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  Stopwatch stopwatch = Stopwatch()..start();
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  WalletStatus mockWalletStatus =
      await getMockWalletStatus(TestWalletType.forNormal, isMultisig: true);

  print('walletStatus loaded: ${stopwatch.elapsedMilliseconds}');

  MultisignatureWallet mockWallet =
      getMockMultisignatureWallet(TestWalletType.forNormal);
  mockWallet.walletStatus = mockWalletStatus;
  mockWallet.addressBook.updateAddressBook();
  print('wallet loaded: ${stopwatch.elapsedMilliseconds}');
  group('MultisignatureWallet', () {
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
            '88b8da7f8027619cc44bc5c26ce730f50028ece6e6b450cf6625b4e50515f286');
        expect(utxoList.last.transactionHash,
            '88b8da7f8027619cc44bc5c26ce730f50028ece6e6b450cf6625b4e50515f286');
      });

      test('cursor 위치 부터 count 갯수만큼 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(cursor: 20, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.transactionHash,
            'c23149273ec08089a56749de8e819d8b1dbe13bb5e85342910934bb8823c5396');
        expect(utxoList.last.transactionHash,
            'b69859ea03bd2445c976bba7850855a419c84b9b2960ad8d3b9bdd6ed4a5e33f');
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
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountAsc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 1000);
        expect(utxoList.last.amount, 699301666);
      });

      test('금액 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountDesc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 699301666);
        expect(utxoList.last.amount, 1000);
      });

      test('타임스탬프 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.blockHeight, 46573);
        expect(utxoList.last.blockHeight, 46584);
      });

      test('타임스탬프 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampDesc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.blockHeight, 46584);
        expect(utxoList.last.blockHeight, 46573);
      });

      test('order 파라미터가 없을 경우 UTXO를 타임스탬프 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.blockHeight, 46584);
        expect(utxoList.last.blockHeight, 46573);
      });

      test('금액 오름차순, cursor 3, count 7 테스트', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountAsc, cursor: 2, count: 7);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 7);
        expect(utxoList.first.amount, 1000);
        expect(utxoList.last.amount, 1002);
      });

      test('타임스탬프 오름차순, cursor 5, count 5 테스트', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, cursor: 5, count: 15);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 15);
        expect(utxoList.first.blockHeight, 46573);
        expect(utxoList.last.blockHeight, 46575);
      });
    });
  });
}
