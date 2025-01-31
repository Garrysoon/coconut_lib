@Tags(['unit'])

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('WalletBase', () {
    late SingleSignatureVault vault;
    late SingleSignatureWallet wallet;
    late String receiverAddress;
    late String changeAddress;

    setUpAll(() async {
      NetworkType.setNetworkType(NetworkType.regtest);
      vault = MockFactory.createP2wpkhVault();
      wallet = SingleSignatureWallet.fromDescriptor(vault.descriptor);
      receiverAddress = vault.getAddress(0);
      changeAddress = vault.getAddress(0, isChange: true);
    });
    group('get addressType', () {
      test('Get address type from wallet base', () {
        expect(wallet.addressType, AddressType.p2wpkh);
      });
    });
    group('get derivationPath', () {
      test('Get derivation path', () {
        expect(wallet.derivationPath, "m/84'/1'/0'");
      });
    });
    group('get accountIndex', () {
      test('Get account index', () {
        expect(wallet.accountIndex, 0);
      });
    });
    group('get descriptor', () {
      test('Get descriptor', () {
        expect(vault.descriptor.hashCode, 186870090);
      });
    });
    group('generatePsbtForPayment', () {
      test('Generate psbt for payment', () async {
        List<UTXO> utxoPool = MockFactory.createUtxoList(count: 5);
        int sendingAmount = 150000;
        int feeRate = 1;
        String psbt = await wallet.generatePsbtForPayment(
            utxoPool, receiverAddress, changeAddress, sendingAmount, feeRate);
        expect(psbt.hashCode, 252587404);
      });
    });
    group('generatePsbtWithUtxoList', () {
      test('Generate psbt from utxo list', () async {
        List<UTXO> utxoPool = MockFactory.createUtxoList(count: 3);
        String psbt = await wallet.generatePsbtWithUtxoList(
            utxoPool, receiverAddress, changeAddress, 150000, 1);
        expect(psbt.hashCode, 793019315);
      });
    });
    group('generatePsbtForSweep', () {
      test('Generate psbt for sweep', () async {
        List<UTXO> utxoPool = MockFactory.createUtxoList(count: 5);
        String psbt =
            await wallet.generatePsbtForSweep(utxoPool, receiverAddress, 1);
        expect(psbt.hashCode, 943576437);
      });
    });
  });
}
