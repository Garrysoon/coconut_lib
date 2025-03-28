import 'package:coconut_lib/coconut_lib.dart';

import 'mock_factory.dart';

void main() {
  Psbt unsignedPsbt = MockFactory.createP2wpkhUnsignedPsbt();
  SingleSignatureVault vault = MockFactory.createP2wpkhVault();

  Transaction tx = unsignedPsbt.unsignedTransaction!;

  for (TransactionOutput out in tx.outputs) {
    print(out.amount);
  }

  tx.updateFeeRate(2, vault);

  for (TransactionOutput out in tx.outputs) {
    print(out.amount);
  }
}
