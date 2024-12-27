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
      test('파라미터가 없을 경우 5개의 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList();

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
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

    group('getTransferList', () {
      test('파라미터가 없을 경우 기본값(cursor: 0, count: 5)으로 Transfer를 반환한다.', () {
        List<Transfer> transferList = mockWallet.getTransferList();

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList[0].transactionHash,
            '88b8da7f8027619cc44bc5c26ce730f50028ece6e6b450cf6625b4e50515f286');
        expect(transferList.length, 5);
        expect(transferList[4].transactionHash,
            '6a5a212ce8896e0dc8e9c34d03b701683ccaef624c30515b90636bf2407ccaa3');
      });

      test('count 갯수만큼 Transfer를 반환한다.', () {
        List<Transfer> transferList = mockWallet.getTransferList(count: 3);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 3);
        expect(transferList[0].transactionHash,
            '88b8da7f8027619cc44bc5c26ce730f50028ece6e6b450cf6625b4e50515f286');
        expect(transferList[2].transactionHash,
            'b69859ea03bd2445c976bba7850855a419c84b9b2960ad8d3b9bdd6ed4a5e33f');
      });

      test('cursor 위치부터 count 갯수만큼 Transfer를 반환한다.', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 2, count: 3);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 3);
        expect(transferList[0].transactionHash,
            'b69859ea03bd2445c976bba7850855a419c84b9b2960ad8d3b9bdd6ed4a5e33f');
        expect(transferList[2].transactionHash,
            '6a5a212ce8896e0dc8e9c34d03b701683ccaef624c30515b90636bf2407ccaa3');
      });

      test('cursor가 전체 Transfer 갯수보다 클 경우 빈 리스트를 반환한다.', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 1000, count: 5);

        expect(transferList.isEmpty, isTrue);
      });

      test('count가 전체 Transfer 갯수보다 클 경우 남은 Transfer를 모두 반환한다.', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 0, count: 1000);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, mockWalletStatus.transactionList.length);
        expect(transferList.first.transactionHash,
            '88b8da7f8027619cc44bc5c26ce730f50028ece6e6b450cf6625b4e50515f286');
        expect(transferList.last.transactionHash,
            '265497a6da34f54f6c6254237e8e82080d10f9f7bee98b7c35c7b76c8e22b657');
      });

      test('cursor 3, count 7 테스트', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 3, count: 7);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 7);
        expect(transferList.first.transactionHash,
            '90b536c3cd816addc817ae1fd35a339d2f7db97e7de279e6433b758b5d10a836');
        expect(transferList.last.transactionHash,
            '9fb71c3e99e8f517a42a3dec1167f7d43f7efe5d760564a0b161982f1f71424b');
      });

      test('cursor 5, count 5 테스트', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 5, count: 5);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 5);
        expect(transferList.first.transactionHash,
            '2c2b49b0dcde4c5344745f3b69dd4b70e5802eab963ac7286cca2c66baa121cd');
        expect(transferList.last.transactionHash,
            '9fb71c3e99e8f517a42a3dec1167f7d43f7efe5d760564a0b161982f1f71424b');
      });

      test(
          'Self 유형의 Transfer인 경우 input/output 모든 주소에 derivationPath가 포함되어 있어야 한다.',
          () {
        List<Transfer> transferList = mockWallet.getTransferList();

        Transfer transfer = transferList[0];

        expect(transfer.transferType, TransactionTypeEnum.self.name);

        for (Address inputAddress in transfer.inputAddressList) {
          expect(inputAddress.derivationPath, isNotEmpty);
        }
        for (Address outputAddress in transfer.outputAddressList) {
          expect(outputAddress.derivationPath, isNotEmpty);
        }
      });

      test('Sent 유형의 Transfer인 경우 input 주소의 derivationPath가 모두 포함되어 있어야 한다.',
          () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 12, count: 1);

        Transfer transfer = transferList[0];

        expect(transfer.transferType, TransactionTypeEnum.sent.name);

        for (Address inputAddress in transfer.inputAddressList) {
          expect(inputAddress.derivationPath, isNotEmpty);
        }

        Address outputAddress = transfer.outputAddressList[0];

        expect(outputAddress.derivationPath, isEmpty);
      });

      test('Received 유형의 Transfer인 경우 input 주소가 모두 본인 주소가 아니어야 한다.', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 20, count: 1);

        Transfer transfer = transferList[0];

        expect(transfer.transferType, TransactionTypeEnum.received.name);

        for (Address inputAddress in transfer.inputAddressList) {
          expect(inputAddress.derivationPath, isEmpty);
        }
      });
    });
  });
}
