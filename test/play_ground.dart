import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';
import 'package:coconut_lib/src/cryptography/elliptic_curve_cryptography.dart'
    as ecc;
import 'mock_factory.dart';

void takeScenario() {
  NetworkType.setNetworkType(NetworkType.regtest);
  SingleSignatureVault vault = MockFactory.createP2trKeyPathSpendingVault();
  String receiveAddress = vault.getAddress(2);
  String utxoPath = "m/86'/1'/0'/0/0";

  // print(vault.getAddress(1));
  print(vault.getAddressWithDerivationPath(utxoPath));
  String changeAddress = vault.getAddress(0, isChange: true);
  // print(
  //     "Origin public key : ${vault.keyStore.getPublicKeyWithDerivationPath(utxoPath)}");

  Utxo utxo = Utxo(
      '76118a51b56d38694c519b2a4714775a7bd5f1b92fc0a416b97fba55f63929a8',
      0,
      21000,
      utxoPath);

  // Transaction tx = Transaction.forPayment(
  //     [utxo], receiveAddress, changeAddress, 3300, 5, vault);

  Transaction tx = Transaction.forSweep([utxo], receiveAddress, 1, vault);

  Psbt psbt = Psbt.fromTransaction(tx, vault);

  String signed = vault.addSignatureToPsbt(psbt.serialize());
  Psbt signedPsbt = Psbt.parse(signed);
  Transaction signedTx = Transaction.parse(signedPsbt
      .getSignedTransaction(AddressType.p2trKeyPathSpending)
      .serialize());

  print(signedTx.serialize());
}

void main() {
  takeScenario();
  // ecc.EllipticCurveCryptography ecc = ecc.EllipticCurveCryptography
}
