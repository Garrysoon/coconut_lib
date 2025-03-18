import 'package:coconut_lib/coconut_lib.dart';
import 'mock_factory.dart';

void main() {
  MultisignatureVault vault = MockFactory.createP2wshVault();
  List<Utxo> utxoList = MockFactory.createUtxoList(count: 2);
  Transaction unsignedTx = Transaction.forSinglePayment(utxoList,
      vault.getAddress(0), '${vault.derivationPath}/1/0', 3000, 1, vault);

  print(
      "Get change derived path in TX : ${unsignedTx.changeAddressDerivationPath}");

  String unsignedPsbtText = Psbt.fromTransaction(unsignedTx, vault).serialize();

  Psbt unsignedPsbt = Psbt.parse(unsignedPsbtText);

  for (PsbtOutput output in unsignedPsbt.outputs) {
    print("Is Change Output : ${output.isChange}");
    if (output.bip32Derivation == null) {
      continue;
    }
    print("Finger print : ${output.bip32Derivation!.masterFingerprint}");
    print("Path : ${output.bip32Derivation!.path}");
  }
}
