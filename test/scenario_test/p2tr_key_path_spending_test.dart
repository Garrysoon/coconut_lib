@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  WalletUtility.getAccountIndexFromDerivationPath("m/86'/1'/0'/0/0");
  NetworkType.setNetworkType(NetworkType.regtest);
  test('Add signature to psbt scenario', () {
    SingleSignatureVault vault = MockFactory.createP2trKeyPathSpendingVault();

    expect(vault.descriptor.hashCode, 917163750);
    expect(checkTweak(vault), true);
    expect(vault.getAddress(0),
        'bcrt1p04sfl6yhkw73rsjjk5c0fu5ptem2zvu6ts5cj7s0ww2s5gqtljmqjqsgx3');
    Utxo utxo = Utxo(
        '0b8779db44139926fb87f0077bf8d1ad7e00ab2fac51af429ee95ee66fd4bb76',
        1,
        100000000,
        "m/86'/1'/0'/0/0");

    Transaction tx = Transaction.forSinglePayment(
        [utxo], vault.getAddress(1), "m/86'/1'/0'/1/0", 210000, 3, vault);
    Psbt unsignedPsbt = Psbt.fromTransaction(tx, vault);
    Psbt signedPsbt =
        Psbt.parse(vault.addSignatureToPsbt(unsignedPsbt.serialize()));
    Transaction signedTx = signedPsbt.getSignedTransaction(vault.addressType);
    expect(signedTx, isA<Transaction>());
  });
}

bool checkSpending(SingleSignatureVault vault) {
  Utxo utxo = Utxo(
      '0b8779db44139926fb87f0077bf8d1ad7e00ab2fac51af429ee95ee66fd4bb76',
      1,
      100000000,
      "m/86'/1'/0'/0/0");

  Transaction tx = Transaction.forSinglePayment(
      [utxo], vault.getAddress(1), "m/86'/1'/0'/1/0", 210000, 3, vault);
  Psbt unsignedPsbt = Psbt.fromTransaction(tx, vault);
  Psbt signedPsbt =
      Psbt.parse(vault.addSignatureToPsbt(unsignedPsbt.serialize()));
  if (signedPsbt.getSignedTransaction(vault.addressType).serialize().hashCode ==
      366721487) {
    return true;
  }
  return false;
}

bool checkTweak(SingleSignatureVault vault) {
  if (vault.keyStore.getPrivateKey(0, isSchnorr: true) !=
      '9d9b99c89ab64460dd29d1a6c46a3b6a7ab30eb83e44632b983d658f5ef86d9e') {
    return false;
  }
  if (vault.keyStore.getPublicKey(0, isSchnorr: true) !=
      '7d609fe897b3bd11c252b530f4f2815e76a1339a5c29897a0f73950a200bfcb6') {
    return false;
  }
  if (vault.keyStore.getPrivateKey(1, isSchnorr: true) !=
      '27554aa112a20f633027a24f450ea7c96653a4e6196d2d65cc8a2f1d4f20b4ed') {
    return false;
  }
  if (vault.keyStore.getPublicKey(1, isSchnorr: true) !=
      'a9fe7b8d167996dbdd90300b18ef2a1ef186862f61a22529db2c306aad9dfc0c') {
    return false;
  }
  if (vault.keyStore.getPrivateKey(2, isSchnorr: true) !=
      '84d43d3ac0a5e29d7e314104571d8aa4f3dba1f6ce7d8553e3cefea924685fdb') {
    return false;
  }
  if (vault.keyStore.getPublicKey(2, isSchnorr: true) !=
      '73ec6131a15b603419c848dcca946a2fca02b0f947cf7592ab674bf2237db6fc') {
    return false;
  }

  return true;
}
