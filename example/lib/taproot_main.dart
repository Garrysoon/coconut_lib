import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/cryptography/converter.dart';

void main() async {
  NetworkType.setNetworkType(NetworkType.regtest);

  SingleSignatureVault vault = SingleSignatureVault.fromMnemonic(
      'machine crack daughter fish credit glare raven fever tunnel delay fish record',
      addressType: AddressType.p2tr);

  UTXO utxo1 = UTXO(
      '3e428b24f41924684ce06792d51975bbac39fdcd3ed65dee3809de4355cedadd',
      1,
      3748,
      "m/86'/0'/0'/0/0");

  TransactionInput input = TransactionInput.forPayment(
      '2729887f5073c8c09359948ceb09bd5489ccb4cbd68d13a5ffdaaca9c5f87abf', 1);
  print("input: ${input.serialize()}");
  TransactionOutput output = TransactionOutput.forPayment(
      2800, 'bc1qda6q5jymq0kyzs89cmg2xpaum0n2tq96687z8w');
  print("output: ${output.serialize()}");
  print("output.amount: ${output.amount}");
  print("output.scriptPubKey: ${output.scriptPubKey.serialize()}");

  Transaction tx = Transaction.withDefault([input], [output], AddressType.p2tr);
  print('tx: ${tx.serialize()}');
  Transaction txE = Transaction.parse(
      '02000000000101bf7af8c5a9acdaffa5138dd6cbb4cc8954bd09eb8c945993c0c873507f8829270000000000fdffffff01f00a0000000000001600146f740a489b03ec4140e5c6d0a307bcdbe6a580ba01405f7fbba460f10449b1cff47cd72d81464ff3be54834c880d4f456e2cd3ccf11aab97ff4888f55c20a6740187044de66d0683d5e2ab4872ebe57f40faf1e7bc7900000000');
  print('txE.witness[0]: ${txE.inputs[0].witnessList[0]}');
}
