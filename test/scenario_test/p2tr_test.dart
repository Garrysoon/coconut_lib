// @Tags(['scenario'])
import 'dart:js_interop';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('P2TR Test', () {
    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
    });
    test('P2TR MuSig2 Test', () {
      late KeyStore keyStore1;
      late KeyStore keyStore2;
      late KeyStore keyStore3;
      late TaprootVault vault;

      NetworkType.setNetworkType(NetworkType.regtest);

      SingleSignatureVault vault1 =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      SingleSignatureVault vault2 =
          MockFactory.createP2wpkhVault(passphrase: 'B');
      SingleSignatureVault vault3 =
          MockFactory.createP2wpkhVault(passphrase: 'C');

      keyStore1 = KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2tr);
      keyStore2 = KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2tr);
      keyStore3 = KeyStore.fromSeed(vault3.keyStore.seed, AddressType.p2tr);

      // print("keyStore1.getPrivateKey(0) : ${keyStore1.getPrivateKey(0)}");
      // print("keyStore1.getPublicKey(0) : ${keyStore1.getPublicKey(0)}");
      // print("keyStore2.getPrivateKey(0) : ${keyStore2.getPrivateKey(0)}");
      // print("keyStore2.getPublicKey(0) : ${keyStore2.getPublicKey(0)}");
      // print("keyStore3.getPrivateKey(0) : ${keyStore3.getPrivateKey(0)}");
      // print("keyStore3.getPublicKey(0) : ${keyStore3.getPublicKey(0)}");

      vault =
          TaprootVault.fromKeyStoreList([keyStore1, keyStore2, keyStore3], []);

      // print(
      //     "vault.getAggregatedPublicKey(0) : ${Codec.encodeHex(vault.getAggregatedPublicKey(0))}");

      // print(
      //     "vault.getAddress(0) : ${vault.getAddress(0)}"); //bcrt1p3gu94a4n2hukh0zqpqglu5j2dnkl8sxwzezytle27vvwqxwy55ls957cxs

      Utxo utxo = Utxo(
          '9e734cf5c607b6914610458a2ec23056e9024919192f55852c5f27c605a62f30',
          0,
          21000,
          "m/86'/1'/0'/0/0");
      Transaction tx = Transaction.forSinglePayment([utxo],
          MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 1000, 3, vault);

      String unsignedPsbt = Psbt.fromTransaction(tx, vault).serialize();
      String noncePsbt = vault.addPublicNonce(unsignedPsbt);
      String signedPsbt = vault.addSignatureToPsbt(noncePsbt);
      Transaction signedTx =
          Psbt.parse(signedPsbt).getSignedTransaction(AddressType.p2tr);
      print(signedTx.serialize());

      // // test 2-of-2
      // late List<Utxo> utxoList;
      // late Transaction tx;
      // utxoList = MockFactory.createUtxoList(
      //     count: 1, derivationPath: "m/86'/1'/0'/0/0");
      // tx = Transaction.forSinglePayment(utxoList, musig2Vault1.getAddress(1),
      //     '${musig2Vault1.derivationPath}/1/1', 15000, 3, musig2Vault1);
      // String unsignedPsbt = Psbt.fromTransaction(tx, musig2Vault1).serialize();

      // String partialNoncePsbt1 = musig2Vault1.addPublicNonce(unsignedPsbt);

      // String partialNoncePsbt2 = musig2Vault2.addPublicNonce(partialNoncePsbt1);

      // String partialSigPsbt1 =
      //     musig2Vault1.addSignatureToPsbt(partialNoncePsbt2);

      // String partialSigPsbt2 = musig2Vault2.addSignatureToPsbt(partialSigPsbt1);

      // Psbt completedPsbt = Psbt.parse(partialSigPsbt2);

      // // print(completedPsbt.serialize());

      // Transaction completedTx =
      //     completedPsbt.getSignedTransaction(AddressType.p2tr);
      // expect(completedTx, isA<Transaction>());
    });
    test('P2TR Script Path Spending Test', () {
      Transaction tx = Transaction.parse(
          '020000000001019cbf420644d68c7018fc31ff0ccacd33a230d4aae25355eaee5e9fdd3764f4bf0100000000feffffff0208520000000000002251208a385af6b355f96bbc400811fe524a6cedf3c0ce164445ff2af318e019c4a53f4436438f2d010000225120cfdf9e814bf91b67388a4a7971ecff90d4a92149db609e636ec47725c801ac540247304402203fee2ff072425f2395bf05e652275323fc0cfe4e51dce8895f358dae7a83731b02201e1389a3f10c1a5d2ba659fb6586b464614ee30ac2c57fb57354fe98f89cee07012102fc157ae670f42e87785c98b093de47af743c50dce1f4bbdfef3423495e69763a68a50200');
      print(tx.outputs[0].amount);
    });
  });
}
