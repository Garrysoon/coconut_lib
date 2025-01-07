@Tags(['e2e'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

Future<void> main() async {
  group('NodeConnector', () {
    late NodeConnector nodeConnector;
    setUpAll(() async {
      try {
        nodeConnector = await NodeConnector.connectSync(
            'regtest-electrum.coconut.onl', 60401);
      } catch (e) {
        print('NodeConnector error: $e');
        rethrow;
      }
    });

    test('getBlock', () async {
      var result = nodeConnector.currentBlock;

      print('getBlock: ${result.height} / ${result.timestamp}');

      expect(result, isNotNull);
    });

    test('getNetworkMinimumFeeRate', () async {
      var result = await nodeConnector.getNetworkMinimumFeeRate();

      print('getNetworkMinimumFeeRate: ${result.value} ${result.error}');

      expect(result, isNotNull);
    });

    test('getTransaction', () async {
      var result = await nodeConnector.getTransaction(
          'ea92c0bb6cc6d6d3371d7b31006d8b8311066b3bddd5258d40fa26a951612a85');

      print('getTransaction: ${result.value}');

      expect(result, isNotNull);
    });

    test('broadcast', () async {
      var result = await nodeConnector.broadcast('0');

      print('broadcast: ${result.error?.message}');

      expect(result, isNotNull);
    });

    test('fullSync', () async {
      var mockWallet = getMockSingleWallet(TestWalletType.forNormal);
      var result = await nodeConnector.fetch(mockWallet);

      print('fullSync balance: ${result.value?.balance.confirmed}');

      expect(result, isNotNull);
    });

    test('generate exceeded feerate tx', () async {
      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
      NodeConnector nodeConnector = await NodeConnector.connectSync(
          'regtest-electrum.coconut.onl', 60401);
      SingleSignatureVault vault = SingleSignatureVault.fromMnemonic(
          'treat auto inmate dismiss erode twist stick olympic light patch piece delay',
          AddressType.p2wpkh);
      SingleSignatureWallet wallet =
          SingleSignatureWallet.fromDescriptor(vault.descriptor);

      await wallet.fetchOnChainData(nodeConnector);
      // await Repository().sync(wallet, syncResult.value!);

      var address = wallet.getReceiveAddress();
      var estimateFee = await wallet.estimateFee(address.address, 547, 100000);

      print(estimateFee);

      var psbt = await wallet.generatePsbt(address.address, 547, 100000);

      var signedPsbt = vault.addSignatureToPsbt(psbt);

      var transaction =
          PSBT.parse(signedPsbt).getSignedTransaction(AddressType.p2wpkh);

      var result = await nodeConnector.broadcast(transaction.serialize());

      expect(result.error?.errorCode, ErrorCodeEnum.exceededFee);
    }, skip: true);

    test('generate small utxo', () async {
      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
      NodeConnector nodeConnector = await NodeConnector.connectSync(
          'regtest-electrum.coconut.onl', 60401);
      SingleSignatureVault vault = SingleSignatureVault.fromMnemonic(
          'treat auto inmate dismiss erode twist stick olympic light patch piece delay',
          AddressType.p2wpkh);
      SingleSignatureWallet wallet =
          SingleSignatureWallet.fromDescriptor(vault.descriptor);

      await wallet.fetchOnChainData(nodeConnector);

      var address = wallet.getReceiveAddress();

      var psbt = await wallet.generatePsbt(address.address, 547, 1);

      var signedPsbt = vault.addSignatureToPsbt(psbt);

      var transaction =
          PSBT.parse(signedPsbt).getSignedTransaction(AddressType.p2wpkh);

      var result = await nodeConnector.broadcast(transaction.serialize());

      expect(result.value, isNotNull);
    }, skip: true);
  });
}
