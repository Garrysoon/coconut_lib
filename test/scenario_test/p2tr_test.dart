// @Tags(['scenario'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('P2TR Test', () {
    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
    });

    bool validateSchnorr(String prevTx, String currTx, int inputIndex) {
      final Transaction funding = Transaction.parse(prevTx);
      final Transaction spending = Transaction.parse(currTx);

      if (funding.transactionHash.toLowerCase() !=
          spending.inputs[inputIndex].transactionHash.toLowerCase()) {
        return false;
      }

      final TransactionOutput prevOut =
          funding.outputs[spending.inputs[inputIndex].index];

      if (prevOut.scriptPubKey.isP2tr() == false) {
        return false;
      }

      if (spending.inputs[inputIndex].witnessList.length != 1) {
        return false;
      }

      final Uint8List outputKeyXOnly =
          Uint8List.fromList((prevOut.scriptPubKey.commands[1] as Uint8List));

      final Uint8List message =
          Codec.decodeHex(spending.getTaprootSigHash(inputIndex, [prevOut]));
      final Uint8List signature =
          Codec.decodeHex(spending.inputs[inputIndex].witnessList[0]);

      return Ecc.verifySchnorr(message, outputKeyXOnly, signature);
    }

    test('P2TR MuSig2 Test (case 1)', () {
      late KeyStore keyStore1;
      late KeyStore keyStore2;
      late TaprootVault vault;

      NetworkType.setNetworkType(NetworkType.regtest);

      SingleSignatureVault vault1 =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      SingleSignatureVault vault2 =
          MockFactory.createP2wpkhVault(passphrase: 'B');

      keyStore1 = KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2tr);
      keyStore2 = KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2tr);

      int addressIndex = 1;

      print(
          "keyStore1.getPrivateKey($addressIndex) : ${keyStore1.getPublicKey(addressIndex)}");
      print(
          "keyStore2.getPrivateKey($addressIndex) : ${keyStore2.getPublicKey(addressIndex)}");

      vault = TaprootVault.fromKeyStoreList([keyStore1, keyStore2], []);

      print(
          "vault.getAddress($addressIndex) : ${vault.getAddress(addressIndex)}");

      Utxo utxo = Utxo(
          '5786f8eda5a9b882d35b5116d1fae71256f4f0d8b799bc45bb1b4fdbf86c79df',
          0,
          21000,
          "m/86'/1'/0'/0/$addressIndex");
      Transaction tx = Transaction.forSinglePayment([utxo],
          MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 1000, 3, vault);
      String unsignedPsbt = Psbt.fromTransaction(tx, vault).serialize();
      String noncePsbt = vault.addPublicNonce(unsignedPsbt);
      String signedPsbt = vault.addSignatureToPsbt(noncePsbt);
      Transaction signedTx =
          Psbt.parse(signedPsbt).getSignedTransaction(AddressType.p2tr);
      print(signedTx.serialize());
    });

    test('P2TR MuSig2 Test (case 2)', () {
      late KeyStore keyStore1;
      late KeyStore keyStore2;
      late TaprootVault vault;

      NetworkType.setNetworkType(NetworkType.regtest);

      SingleSignatureVault vault1 =
          MockFactory.createP2wpkhVault(passphrase: 'A');
      SingleSignatureVault vault2 =
          MockFactory.createP2wpkhVault(passphrase: 'B');

      keyStore1 = KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2tr);
      keyStore2 = KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2tr);

      int addressIndex = 0;

      print(
          "keyStore1.getPrivateKey($addressIndex) : ${keyStore1.getPublicKey(addressIndex)}");
      print(
          "keyStore2.getPrivateKey($addressIndex) : ${keyStore2.getPublicKey(addressIndex)}");

      vault = TaprootVault.fromKeyStoreList([keyStore1, keyStore2], []);

      print(
          "vault.getAddress($addressIndex) : ${vault.getAddress(addressIndex)}");

      Utxo utxo = Utxo(
          '9953d794bd9d939b96ad7b7d17df7524c41078d6517514fe6349fcdfbd8d78cb',
          1,
          21000,
          "m/86'/1'/0'/0/$addressIndex");
      Transaction tx = Transaction.forSinglePayment([utxo],
          MockFactory.reveiveAddress, "m/86'/1'/0'/1/0", 1000, 3, vault);
      String unsignedPsbt = Psbt.fromTransaction(tx, vault).serialize();
      String noncePsbt = vault.addPublicNonce(unsignedPsbt);
      String signedPsbt = vault.addSignatureToPsbt(noncePsbt);
      Transaction signedTx =
          Psbt.parse(signedPsbt).getSignedTransaction(AddressType.p2tr);
      print(signedTx.serialize());
    });

    test('Validator Test', () {
      // Bitcoin Core: mandatory-script-verify-flag-failed (Invalid Schnorr signature)
      // → Taproot key-path에서 BIP340 검증이 실패할 때. 아래는 동일 입력에 대해
      // TapSighash + witness 서명이 올바를 때 Ecc.verifySchnorr 가 통과함을 본다.
      String prevTx =
          '02000000000101df796cf8db4f1bbb45bc99b7d8f0f45612e7fad116515bd382b8a9a5edf886570100000000feffffff02085200000000000022512011ea1ebca0e3516547053f7557ba80157c24118a4f8a81108bfe299c537e23266bb74c892d010000225120ee6e66fcc1dc5b2d683191891e539738b5d9b29341c33ed4cd542ad1ce983e080140e49b267e97a8b0f298e0cb5e0f9040bfe0c42dabe533cbd4aa05c19a952cc2bef768f71c99e76f66ce3af37a0e1f47a72fdf0610883f39d46decdec9bb4f6c2018ab0200';
      String currTx =
          '0200000000010193a27471ed01812438ede377c3df354f18ad135792544b14c7b8f7d2a435aee70000000000ffffffff0288130000000000002251201d8e1f53f8d6d9956386ef566713e4974ad7eab604c233eba521d3aa6acae7326c3d0000000000002251203be0e447acfa88e442ebee74f5af49f8ddb75aecd05029e50777ff3f6aa47ea401406ee802e05d8aa640bb820e65e5810c6bce8f6794ad4f6c8e79c9ffb3ae09518327a42c13a41a6b065d67d31c7f678d28a77c6a985515ef2f47340b660164d4f600000000';
      int inputIndex = 0;

      bool isValid = validateSchnorr(prevTx, currTx, inputIndex);
      expect(isValid, isTrue);
    });
  });
}
