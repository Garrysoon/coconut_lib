import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';

import 'mock_factory.dart';

void main() {
  print(Encoder.decodeHex(''));
}

String getHashScriptPubkeys() {
  List<String> utxoList = [
    "512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343",
    "5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3",
    "76a914751e76e8199196d454941c45d1b3a323f1433bd688ac",
    "5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e",
    "512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605",
    "00147dd65592d0ab2fe0d0257d571abf032cd9db93dc",
    "512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831",
    "5120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5",
    "512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220"
  ];
  List<int> buffer = [];
  for (String utxo in utxoList) {
    buffer.addAll((Encoder.encodeVariableInteger(utxo.length ~/ 2)).toList());
    buffer.addAll(Encoder.decodeHex(utxo));
  }
  return Encoder.encodeHex(Hash.sha256fromByte(Uint8List.fromList(buffer)));
  //23ad0f61ad2bca5ba6a7693f50fce988e17c3780bf2b1e720cfbb38fbdd52e21
}

String getA() {
  String ee =
      "512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda3435120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea376a914751e76e8199196d454941c45d1b3a323f1433bd688ac5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc2178360500147dd65592d0ab2fe0d0257d571abf032cd9db93dc512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b8315120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220";
  print(Hash.sha256fromHex(ee));
  return Hash.sha256fromHex(ee);
}

void takeScenario() {
  // TR Case
// Hash : 586a0ccc240c66884601eebb4b251d2edfc1b34cae744a38c9417d87115d7c24
// TX : 02000000000101a52468cf4121af7815bb5eef41799a0011edb87e592badcb353ea88f269774770000000000fdffffff015203000000000000225120a25a355d6f25472c5a67d16160effe0f3fb3b8daff2b8a672274d068e23ce04501408ba6c85e4e35c63be98b1710f5fd73179200494fed1d48fc98e0ce9513b3ff727a81b597dc68195a23679bf28d7742a0bc340f8323939319f77d3d9eec27b89300000000
// Witness : 8ba6c85e4e35c63be98b1710f5fd73179200494fed1d48fc98e0ce9513b3ff727a81b597dc68195a23679bf28d7742a0bc340f8323939319f77d3d9eec27b893
// Receive address : bc1p5fdr2ht0y4rjckn869skpml7pulm8wx6lu4c5eezwngx3c3uupzssx4myf

  NetworkType.setNetworkType(NetworkType.mainnet);
  SingleSignatureVault trVault = MockFactory.createP2trKeyPathSpendingVault();
// print(vault.descriptor);
  print(trVault.getAddress(0));

  List<Utxo> utxos =
      MockFactory.createUtxoList(count: 1, derivationPath: "m/86'/1'/0'/0/0");

  Transaction trTx = Transaction.forSweep(
      utxos,
      'bc1p5fdr2ht0y4rjckn869skpml7pulm8wx6lu4c5eezwngx3c3uupzssx4myf',
      1,
      trVault);

  Psbt psbt = Psbt.fromTransaction(trTx, trVault);
// print(psbt.serialize());

  print(trVault.canSignToPsbt(psbt.serialize()));
  trVault.addSignatureToPsbt(psbt.serialize());

  // print(Transaction.getTaprootSigHash());
}
