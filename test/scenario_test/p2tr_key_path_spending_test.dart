@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
    SingleSignatureVault vault = MockFactory.createP2trKeyPathSpendingVault();

    expect(vault.descriptor.hashCode, 917163750);

    SingleSignatureWallet wallet =
        SingleSignatureWallet.fromDescriptor(vault.descriptor);

    expect(vault.keyStore.getPrivateKey(0, isSchnorr: true),
        '9d9b99c89ab64460dd29d1a6c46a3b6a7ab30eb83e44632b983d658f5ef86d9e');
    expect(wallet.keyStore.getPublicKey(0, isSchnorr: true),
        '7d609fe897b3bd11c252b530f4f2815e76a1339a5c29897a0f73950a200bfcb6');
    expect(wallet.getAddress(0),
        'tb1p04sfl6yhkw73rsjjk5c0fu5ptem2zvu6ts5cj7s0ww2s5gqtljmqle6wnt');
    expect(vault.keyStore.getPrivateKey(1, isSchnorr: true),
        '27554aa112a20f633027a24f450ea7c96653a4e6196d2d65cc8a2f1d4f20b4ed');
    expect(wallet.keyStore.getPublicKey(1, isSchnorr: true),
        'a9fe7b8d167996dbdd90300b18ef2a1ef186862f61a22529db2c306aad9dfc0c');
    expect(vault.keyStore.getPrivateKey(2, isSchnorr: true),
        '84d43d3ac0a5e29d7e314104571d8aa4f3dba1f6ce7d8553e3cefea924685fdb');
    expect(wallet.keyStore.getPublicKey(2, isSchnorr: true),
        '73ec6131a15b603419c848dcca946a2fca02b0f947cf7592ab674bf2237db6fc');
    Psbt unsignedTx = MockFactory.createP2trKeyPathSpendingUnsignedPsbt();

    String signedPsbtText = vault.addSignatureToPsbt(unsignedTx.serialize());

    Psbt signedPsbt = Psbt.parse(signedPsbtText);
    print(signedPsbt.serialize());

    Transaction signedTransaction =
        signedPsbt.getSignedTransaction(wallet.addressType);

    expect(signedTransaction, TypeMatcher<Transaction>());
  });
}
