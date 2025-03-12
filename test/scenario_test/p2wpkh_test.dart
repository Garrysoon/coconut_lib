@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
    SingleSignatureVault vault = MockFactory.createP2wpkhVault();
    SingleSignatureWallet wallet =
        SingleSignatureWallet.fromDescriptor(vault.descriptor);

    Psbt unsignedTx = MockFactory.createP2wpkhUnsignedPsbt();

    String signedPsbtText = vault.addSignatureToPsbt(unsignedTx.serialize());

    Transaction signedTransaction =
        Psbt.parse(signedPsbtText).getSignedTransaction(wallet.addressType);

    expect(
        signedTransaction.serialize(),
        MockFactory.createP2wpkhSignedPsbt()
            .getSignedTransaction(wallet.addressType)
            .serialize());
  });
}
