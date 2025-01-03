@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  late AddressBook addressBook;
  late SingleSignatureVault mockVault;

  setUpAll(() async {
    BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
    WalletStatus mockWalletStatus =
        await getMockWalletStatus(TestWalletType.forNormal);
    SingleSignatureWallet mockWallet =
        getMockSingleWallet(TestWalletType.forNormal);
    mockWallet.walletStatus = mockWalletStatus;
    mockWallet.addressBook.updateAddressBook();
    addressBook = mockWallet.addressBook;
    mockVault = SingleSignatureVault.random(AddressType.p2wpkh);
  });

  group('AddressBook', () {
    group('get walletStatus', () {
      test('Getting wallet status from Vault.', () {
        expect(() => mockVault.addressBook.walletStatus, throwsException);
      });
    });

    group('get receiveList', () {
      test('Retrive receive address.', () {
        expect(addressBook.receiveList.length >= addressBook.gapLimit, true);
      });
    });

    group('get changeList', () {
      test('Retrive receive address.', () {
        expect(addressBook.changeList.length >= addressBook.gapLimit, true);
      });
    });

    group('get gapLimit', () {
      test('Retrive gep Limit.', () {
        expect(addressBook.gapLimit, 20);
      });
    });

    group('get derivationPath', () {
      test('Retrive derivation path.', () {
        expect(
            addressBook.getDerivationPath(
                "bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv"),
            "m/84'/1'/0'/0/0");
      });

      test('Address does not exist.', () {
        expect(
            () => addressBook.getDerivationPath(
                "bcrt1qu9pncp9uzj4jsnjfq6ut3c5dz89cklm2llwqk6"),
            throwsException);
      });
    });

    group('contains', () {
      test('Checking address in book.', () {
        print(addressBook.changeList.first.address);
        expect(
            addressBook
                .contains("bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv"),
            true);
        expect(
            addressBook
                .contains("bcrt1qu9pncp9uzj4jsnjfq6ut3c5dz89cklm2llwqk6"),
            false);
        expect(
            addressBook.containsInReceive(
                "bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv"),
            true);
        expect(
            addressBook.containsInReceive(
                "bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg"),
            false);
        expect(
            addressBook.containsInChange(
                "bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv"),
            false);
        expect(
            addressBook.containsInChange(
                "bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg"),
            true);
      });
    });
    group('getAddressObject', () {
      test('Retrive address object.', () {
        expect(
            addressBook.getAddressObject(
                "bcrt1qk4z5ysfc2k72pz2ws4dhskxdq772s7uq6cdqkv"),
            isA<Address>());
        expect(
            addressBook.getAddressObject(
                "bcrt1qyg29ghzqe5fweer9tyga4dtccxhnx4yq7ysflg"),
            isA<Address>());
      });
      test('Address does not exist.', () {
        expect(
            () => addressBook.getAddressObject(
                "bcrt1qu9pncp9uzj4jsnjfq6ut3c5dz89cklm2llwqk6"),
            throwsException);
      });
    });

    group('getAddress', () {
      test('Retrive address object from index.', () {
        expect(addressBook.getAddress(0, false), isA<Address>());
        expect(addressBook.getAddress(0, true), isA<Address>());
      });
      test('Retrive address object from large index.', () {
        expect(addressBook.getAddress(200, false), isA<Address>());
        expect(addressBook.getAddress(200, true), isA<Address>());
      });
    });
  });
}
