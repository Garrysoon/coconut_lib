@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  late AddressBook addressBook;
  late Address address;

  setUpAll(() async {
    BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
    WalletStatus mockWalletStatus =
        await getMockWalletStatus(TestWalletType.forNormal);
    SingleSignatureWallet mockWallet =
        getMockSingleWallet(TestWalletType.forNormal);
    mockWallet.walletStatus = mockWalletStatus;
    mockWallet.addressBook.updateAddressBook();
    addressBook = mockWallet.addressBook;
    address = addressBook.receiveList.first;
  });

  group('Address', () {
    group('get address', () {
      test('Retrieve address.', () {
        expect(address.address, isNotNull);
        expect(address.address.isNotEmpty, isTrue);
      });

      test('Check address length.', () {
        expect(address.address.length, 44);
      });

      test('The address is starts with tbrc1q.', () {
        expect(address.address.startsWith('bcrt1'), isTrue);
      });
    });

    group('isUsed', () {
      test('isUsed.', () {
        expect(address.isUsed, true);
        expect(addressBook.receiveList.last.isUsed, false);
      });
    });

    group('get Amount', () {
      test('Retrieve amount.', () {
        expect(address.amount >= 0, true);
        expect(addressBook.receiveList[6].amount > 0, true);
      });
    });

    group('get index', () {
      test('Retrieve index.', () {
        expect(address.index, 0);
      });
    });

    group('==', () {
      Address target = Address(
          'bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv', '', 0, false, 0);
      test('Check equal address.', () {
        expect(address == target, true);
        expect(address.hashCode == target.hashCode, true);
      });
    });
  });
}
