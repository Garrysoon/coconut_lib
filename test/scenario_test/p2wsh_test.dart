@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
    MultisignatureVault vault = MockFactory.createP2wshVault();

    expect(vault.descriptor.hashCode, 541502011);

    MultisignatureWallet wallet =
        MultisignatureWallet.fromDescriptor(vault.descriptor);

    Psbt unsignedTx = MockFactory.createP2wshUnsignedPsbt();

    expect(unsignedTx.addressType, AddressType.p2wsh);

    String signedPsbtText = vault.addSignatureToPsbt(unsignedTx.serialize());

    Transaction signedTransaction =
        Psbt.parse(signedPsbtText).getSignedTransaction(wallet.addressType);

    expect(
        signedTransaction.serialize(),
        MockFactory.createP2wshSignedPsbt()
            .getSignedTransaction(wallet.addressType)
            .serialize());
  });
}
