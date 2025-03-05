import 'dart:math';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/elliptic_curve_cryptography.dart';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';
import 'package:coconut_lib/src/cryptography/elliptic_curve_cryptography.dart'
    as ecc;
import 'mock_factory.dart';

void takeScenario(int accountIndex, Utxo utxo, SingleSignatureVault vault) {
  // String receiveAddress = vault.getAddress(2, isChange: false);
  String receiveAddress =
      'bcrt1p40qqa84kpphe5vtcwd8zv7v6w7p62cmupf6f60mf8pxdkcv2455qgtw98j';
  String utxoPath = "m/86'/1'/0'/0/$accountIndex";

  print(vault.descriptor);
  SingleSignatureWallet wallet =
      SingleSignatureWallet.fromDescriptor(vault.descriptor);

  print(wallet.getAddress(accountIndex));

  print(vault.getAddress(accountIndex));
  // print(utxo.transactionHash);
  // print(utxo.index);
  // print(vault.getAddressWithDerivationPath(utxoPath));
  // String changeAddress = vault.getAddress(accountIndex, isChange: true);
  String changeAddress =
      'bcrt1p6uav7en8k7zsumsqugdmg5j6930zmzy4dg7jcddshsr0fvxlqx7qnc7l22';
  String tweakedPublicKey =
      vault.keyStore.getPublicKey(accountIndex, isSchnorr: true);
  // print("origin public key : ${vault.keyStore.getPublicKey(accountIndex)}");
  // print("tweaked public key : ${tweakedPublicKey}");

  Transaction tx = Transaction.forSweep([utxo], receiveAddress, 1, vault);

  Psbt psbt = Psbt.fromTransaction(tx, vault);

  // print("=== Signing ===");
  String signed = vault.addSignatureToPsbt(psbt.serialize());
  Psbt signedPsbt = Psbt.parse(signed);
  Transaction signedTx = Transaction.parse(signedPsbt
      .getSignedTransaction(AddressType.p2trKeyPathSpending)
      .serialize());
  List<TransactionOutput> utxos =
      signedPsbt.inputs.map((e) => e.witnessUtxo!).toList();
  String sigHash = signedTx.getTaprootSigHash(0, utxos);
  // print("sigHash : $sigHash");
  String signature = signedTx.inputs[0].witnessList[0];
  // print("signature : $signature");

  // print("=== Final check ===");
  // print(verify(Encoder.decodeHex(sigHash), Encoder.decodeHex(tweakedPublicKey),
  //     Encoder.decodeHex(signature),
  //     isSchnorr: true, parity: 0));

  // print(signedTx.serialize());
}

void main() {
  NetworkType.setNetworkType(NetworkType.regtest);
  SingleSignatureVault vault = SingleSignatureVault.fromMnemonic(
      "initial off nephew risk hundred fruit wing coach dream heavy draw motion siege immense movie",
      addressType: AddressType.p2trKeyPathSpending);
  List<Utxo> utxos = [
    Utxo('00b7b88f566234c2a09b3291168e8fc133f8844b40e4ef28e4342d06a74cf05c', 1,
        21000, "m/86'/1'/0'/0/0"),
    Utxo('ed0d900f1944a801d0a69c284a17149f2dd91a47479e636216b5a4d875370158', 0,
        21000, "m/86'/1'/0'/0/1"),
    Utxo('dfaf3d4ca10cc2d3a118d7dbc4294f58537cb265191e07e0d0ffe5510a0b1786', 1,
        21000, "m/86'/1'/0'/0/2"),
    Utxo('c9b13179a2781a0b50811c44a118212a6c3c731bf75f78cfc1f465888a3b8935', 0,
        21000, "m/86'/1'/0'/0/3"),
    Utxo('6ebe64fb75feed094bf0320fde3bb9746aec6b780de0b34527d356ac1f8a5be0', 1,
        21000, "m/86'/1'/0'/0/4"),
    Utxo('a587541c8a159f380635caa3817cf3016780ee32e69e55fc543bf4b1941a5f8b', 1,
        21000, "m/86'/1'/0'/0/5"),
    Utxo('d49fc674b1263aafa3e3499d6141f612a50bb5981b8a668e4f11d39f26598fbb', 0,
        21000, "m/86'/1'/0'/0/6"),
    Utxo('edcdd5d10a459436e5778e988d1a3b39a73fff882620def9fca9f2dd6c65240c', 0,
        21000, "m/86'/1'/0'/0/7"),
    Utxo('a403115a79eb80977f1f3e2cb110cc67b05c6ad17888153b1de89aedb6c16913', 1,
        21000, "m/86'/1'/0'/0/8"),
    Utxo('569d7f16480e89c754f21784d38f41a2c21120cd08920f6414c72a62877cd364', 0,
        21000, "m/86'/1'/0'/0/9")
  ];
  List<int> notWorking = [];
  // for (int i = 0; i < 10; i++) {
  //   print("=== Scenario $i ===");
  //   if (notWorking.contains(i)) {
  //     // print("X");
  //     // continue;
  //     // takeScenario(i, utxos[i], vault);
  //   }
  takeScenario(0, utxos[0], vault);
  // }
}
