@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() {
  late SingleSignatureWallet mockWallet;
  late WalletStatus mockWalletStatus;
  setUpAll(() async {
    BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
    mockWalletStatus =
        await getMockWalletStatus(TestWalletType.forNormal, isMultisig: true);

    mockWallet = getMockSingleWallet(TestWalletType.forNormal);
    mockWallet.walletStatus = mockWalletStatus;
    mockWallet.addressBook.updateAddressBook();
  });
  group('Transaction', () {
    group('addInputWithUtxo', () {
      test('add/remove utxo', () {});
    });
  });
}
