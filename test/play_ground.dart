import 'package:coconut_lib/coconut_lib.dart';
import 'package:mockito/mockito.dart';

import 'mock_factory.dart';

void main() {
  //TR Case
  // Hash : 586a0ccc240c66884601eebb4b251d2edfc1b34cae744a38c9417d87115d7c24
  // TX : 02000000000101a52468cf4121af7815bb5eef41799a0011edb87e592badcb353ea88f269774770000000000fdffffff015203000000000000225120a25a355d6f25472c5a67d16160effe0f3fb3b8daff2b8a672274d068e23ce04501408ba6c85e4e35c63be98b1710f5fd73179200494fed1d48fc98e0ce9513b3ff727a81b597dc68195a23679bf28d7742a0bc340f8323939319f77d3d9eec27b89300000000
  // Witness : 8ba6c85e4e35c63be98b1710f5fd73179200494fed1d48fc98e0ce9513b3ff727a81b597dc68195a23679bf28d7742a0bc340f8323939319f77d3d9eec27b893
  // Receive address : bc1p5fdr2ht0y4rjckn869skpml7pulm8wx6lu4c5eezwngx3c3uupzssx4myf
  NetworkType.setNetworkType(NetworkType.regtest);
  SingleSignatureVault trVault = MockFactory.createP2trVault();
  // print(vault.descriptor);

  print(trVault.getAddress(0));
  print(trVault.getAddress(0, isChange: true));

  List<Utxo> utxos = MockFactory.createUtxoList(count: 1);

  Transaction trTx = Transaction.forSweep(
      utxos,
      'bc1p5fdr2ht0y4rjckn869skpml7pulm8wx6lu4c5eezwngx3c3uupzssx4myf',
      1,
      trVault);

  // Psbt psbt = Psbt.fromTransaction(trTx, trVault);
  // print(psbt.serialize());
}
