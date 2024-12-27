@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  WalletStatus mockWalletStatus =
      await getMockWalletStatus(TestWalletType.forNormal);
  SingleSignatureWallet mockWallet =
      getMockSingleWallet(TestWalletType.forNormal);
  mockWallet.walletStatus = mockWalletStatus;
  mockWallet.addressBook.updateAddressBook();

  group('SingleSignatureWallet', () {
    group('getUtxoList', () {
      test('파라미터가 없을 경우 전체 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList();

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
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
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountAsc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 21000);
        expect(utxoList.last.amount, 5000000);
      });

      test('금액 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountDesc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 5000000);
        expect(utxoList.last.amount, 21000);
      });

      test('타임스탬프 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.timestamp, 1723540500);
        expect(utxoList.last.timestamp, 1734078600);
      });

      test('타임스탬프 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampDesc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.timestamp, 1734078600);
        expect(utxoList.last.timestamp, 1723540500);
      });

      test('order 파라미터가 없을 경우 UTXO를 타임스탬프 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(count: 100);

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

    group('getTransferList', () {
      test('파라미터가 없을 경우 기본값(cursor: 0, count: 5)으로 Transfer를 반환한다.', () {
        List<Transfer> transferList = mockWallet.getTransferList();

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList[0].transactionHash,
            '8a6ad9e7e143c97b24c969ed4b5bb84ce40b6fae78fef17208a36e4c0346e0ae');
        expect(transferList.length, 5);
        expect(transferList[4].transactionHash,
            '5799e62fcb1fb1ce6c196ae5e990c6a1166b864fc2cc09be1fb3afd8a75a022f');
      });

      test('count 갯수만큼 Transfer를 반환한다.', () {
        List<Transfer> transferList = mockWallet.getTransferList(count: 3);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 3);
        expect(transferList[0].transactionHash,
            '8a6ad9e7e143c97b24c969ed4b5bb84ce40b6fae78fef17208a36e4c0346e0ae');
        expect(transferList[2].transactionHash,
            'cf0f5be823525e9f385f5d7ff133131e5a5aa116a8703b49c045baa24ec7ac4f');
      });

      test('cursor 위치부터 count 갯수만큼 Transfer를 반환한다.', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 2, count: 3);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 3);
        expect(transferList[0].transactionHash,
            'cf0f5be823525e9f385f5d7ff133131e5a5aa116a8703b49c045baa24ec7ac4f');
        expect(transferList[2].transactionHash,
            '5799e62fcb1fb1ce6c196ae5e990c6a1166b864fc2cc09be1fb3afd8a75a022f');
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
            '8a6ad9e7e143c97b24c969ed4b5bb84ce40b6fae78fef17208a36e4c0346e0ae');
        expect(transferList.last.transactionHash,
            'fbbb11a686ad004e1d2c25546cdedcf2a90e57f4d2de7049d25202e372cdce0e');
      });

      test('cursor 3, count 7 테스트', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 3, count: 7);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 7);
        expect(transferList.first.transactionHash,
            'd832dfccbb01376e8784fd91201178a496204302f44c8a4ac5070f381b9720e4');
        expect(transferList.last.transactionHash,
            '2c4647d4f785a8ad4f53c2b5b09bcfa6c6d9ba54223dcf8a391e9e64794e93b6');
      });

      test('cursor 5, count 5 테스트', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 5, count: 5);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 5);
        expect(transferList.first.transactionHash,
            '159e7810929876e3e71d0cb4f77ecc7ac8add3b6cc994aea426aff475f644bb1');
        expect(transferList.last.transactionHash,
            '2c4647d4f785a8ad4f53c2b5b09bcfa6c6d9ba54223dcf8a391e9e64794e93b6');
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
            mockWallet.getTransferList(cursor: 14, count: 1);

        Transfer transfer = transferList[0];

        expect(transfer.transferType, TransactionTypeEnum.received.name);

        for (Address inputAddress in transfer.inputAddressList) {
          expect(inputAddress.derivationPath, isEmpty);
        }
      });
    });
  });
}
