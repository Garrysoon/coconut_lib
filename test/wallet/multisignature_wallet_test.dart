@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  late MultisignatureWallet mockWallet;
  late WalletStatus mockWalletStatus;

  setUpAll(() async {
    BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
    mockWalletStatus =
        await getMockWalletStatus(TestWalletType.forNormal, isMultisig: true);
    mockWallet = getMockMultisignatureWallet(TestWalletType.forNormal);
    mockWallet.walletStatus = mockWalletStatus;
    mockWallet.addressBook.updateAddressBook();
  });
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
            'eb53661a5cfb0c22cdf3cc2a4813c735978fb476ca23607cdc3a310f1b57ee19');
        expect(utxoList.first.index, 4);
        expect(utxoList.last.transactionHash,
            'eb53661a5cfb0c22cdf3cc2a4813c735978fb476ca23607cdc3a310f1b57ee19');
        expect(utxoList.last.index, 0);
      });

      test('cursor 위치 부터 count 갯수만큼 UTXO를 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(cursor: 2, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.transactionHash,
            'eb53661a5cfb0c22cdf3cc2a4813c735978fb476ca23607cdc3a310f1b57ee19');
        expect(utxoList.last.transactionHash,
            '870e2a84089e71e5e3c5bedc7ba991bb9d24ac42bdb963e0568077fdfc90b216');
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
        expect(utxoList.first.amount, 123456);
        expect(utxoList.last.amount, 99955091);
      });

      test('금액 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountDesc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.amount, 99955091);
        expect(utxoList.last.amount, 123456);
      });

      test('타임스탬프 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.blockHeight, 50026);
        expect(utxoList.last.blockHeight, 50029);
      });

      test('타임스탬프 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampDesc, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.blockHeight, 50029);
        expect(utxoList.last.blockHeight, 50026);
      });

      test('order 파라미터가 없을 경우 UTXO를 타임스탬프 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, mockWalletStatus.utxoList.length);
        expect(utxoList.first.blockHeight, 50029);
        expect(utxoList.last.blockHeight, 50026);
      });

      test('금액 오름차순, cursor 3, count 6 테스트', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountAsc, cursor: 2, count: 6);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 6);
        expect(utxoList.first.amount, 123458);
        expect(utxoList.last.amount, 99955091);
      });

      test('타임스탬프 오름차순, cursor 5, count 5 테스트, 실제로 8개이며 3개 반환', () {
        List<UTXO> utxoList = mockWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, cursor: 5, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 3);
        expect(utxoList.first.blockHeight, 50029);
        expect(utxoList.last.blockHeight, 50029);
      });
    });

    group('getTransferList', () {
      test('파라미터가 없을 경우 기본값(cursor: 0, count: 5)으로 Transfer를 반환한다.', () {
        List<Transfer> transferList = mockWallet.getTransferList();

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList[0].transactionHash,
            'eb53661a5cfb0c22cdf3cc2a4813c735978fb476ca23607cdc3a310f1b57ee19');
        expect(transferList.length, 5);
        expect(transferList[4].transactionHash,
            '870e2a84089e71e5e3c5bedc7ba991bb9d24ac42bdb963e0568077fdfc90b216');
      });

      test('count 갯수만큼 Transfer를 반환한다.', () {
        List<Transfer> transferList = mockWallet.getTransferList(count: 3);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 3);
        expect(transferList[0].transactionHash,
            'eb53661a5cfb0c22cdf3cc2a4813c735978fb476ca23607cdc3a310f1b57ee19');
        expect(transferList[2].transactionHash,
            '76204aa4b8dbc88736ea70667a83c3cfbe66b0e4f04745c69b55b9113d35b845');
      });

      test('cursor 위치부터 count 갯수만큼 Transfer를 반환한다.', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 2, count: 3);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 3);
        expect(transferList[0].transactionHash,
            '76204aa4b8dbc88736ea70667a83c3cfbe66b0e4f04745c69b55b9113d35b845');
        expect(transferList[2].transactionHash,
            '870e2a84089e71e5e3c5bedc7ba991bb9d24ac42bdb963e0568077fdfc90b216');
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
            'eb53661a5cfb0c22cdf3cc2a4813c735978fb476ca23607cdc3a310f1b57ee19');
        expect(transferList.last.transactionHash,
            '43e0783a2f6fb4f4a1f1df1d0954d2c6ab2030c93e4d37bd05459fddf5224a0e');
      });

      test('cursor 3, count 7 테스트, 실제로 9개이며 6개 반환', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 3, count: 7);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 6);
        expect(transferList.first.transactionHash,
            'e0f695264a1c44c16911a56cd034987326ae1a00b2b758fb1021dd77c846ea44');
        expect(transferList.last.transactionHash,
            '43e0783a2f6fb4f4a1f1df1d0954d2c6ab2030c93e4d37bd05459fddf5224a0e');
      });

      test('cursor 5, count 4 테스트', () {
        List<Transfer> transferList =
            mockWallet.getTransferList(cursor: 5, count: 5);

        expect(transferList.isNotEmpty, isTrue);
        expect(transferList.length, 4);
        expect(transferList.first.transactionHash,
            '1cf580c8847aa488e1dc3bd8d60bd183e2b3a84338787c393a7a60250edc7c89');
        expect(transferList.last.transactionHash,
            '43e0783a2f6fb4f4a1f1df1d0954d2c6ab2030c93e4d37bd05459fddf5224a0e');
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
            mockWallet.getTransferList(cursor: 3, count: 1);

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
            mockWallet.getTransferList(cursor: 7, count: 1);

        Transfer transfer = transferList[0];

        expect(transfer.transferType, TransactionTypeEnum.received.name);

        for (Address inputAddress in transfer.inputAddressList) {
          expect(inputAddress.derivationPath, isEmpty);
        }
      });
    });
  });
}
