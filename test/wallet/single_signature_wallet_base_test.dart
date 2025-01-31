@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('SingleSignatureWalletBase', () {
    late SingleSignatureVault vault;
    late SingleSignatureWallet wallet;
    setUp(() {
      vault = MockFactory.createP2wpkhVault();
      wallet = SingleSignatureWallet.fromDescriptor(vault.descriptor);
    });
    group('get isVault', () {
      test('Check the object is vault', () {
        expect(wallet.isVault, false);
        expect(vault.isVault, true);
      });
    });
    group('get keyStore', () {
      test('Get key store from wallet base', () {
        expect(vault.keyStore.masterFingerprint,
            wallet.keyStore.masterFingerprint);
      });
    });
    group('getAddress', () {
      test('Get address of wallet base', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            wallet.getAddress(0), 'tb1qk4z5ysfc2k72pz2ws4dhskxdq772s7uqc35dp9');
        expect(wallet.getAddress(0, isChange: true),
            'tb1qyg29ghzqe5fweer9tyga4dtccxhnx4yqudfygp');
      });
    });
    group('getAddressWithDerivationPath', () {
      test('Get addresss with derivation path', () {
        expect(wallet.getAddressWithDerivationPath("m/84'/1'/0'/0/0"),
            "tb1qk4z5ysfc2k72pz2ws4dhskxdq772s7uqc35dp9");
        expect(wallet.getAddressWithDerivationPath("m/84'/1'/0'/1/0"),
            "tb1qyg29ghzqe5fweer9tyga4dtccxhnx4yqudfygp");
      });
    });
    group('canSignToPsbt', () {
      test('Can right vault can sign', () {
        PSBT psbt = MockFactory.createP2wpkhUnsignedPsbt();
        expect(vault.canSignToPsbt(psbt.serialize()), true);

        SingleSignatureVault targetVault = SingleSignatureVault.random();
        expect(targetVault.canSignToPsbt(psbt.serialize()), false);
      });
    });
    group('addSignatureToPsbt', () {
      test('Sign to psbt', () {
        PSBT psbt = MockFactory.createP2wpkhUnsignedPsbt();
        String signedPsbt = vault.addSignatureToPsbt(psbt.serialize());
        expect(signedPsbt.hashCode, 862890113);
      });
    });
    group('estimateFee', () {
      test('Get estimated fee', () async {
        Transaction targetTransaction = MockFactory.createP2wpkhSignedPsbt()
            .getSignedTransaction(AddressType.p2wpkh);
        int estimatedFee = await vault.estimateFee(
            MockFactory.createUtxoList(count: 2),
            vault.getAddress(1),
            vault.getAddress(1, isChange: true),
            15000,
            1);
        int targetFee =
            targetTransaction.estimateVirtualByte(AddressType.p2wpkh).ceil();
        expect(estimatedFee, targetFee);
      });
    });
    group('estimateFeeWithMaximum', () {
      Matcher isWithinRange(int lower, int upper) => predicate(
          (x) => x is num && x >= lower && x <= upper,
          'is within range $lower to $upper');
      test('Get estimated fee for sweep', () async {
        Transaction transaction = Transaction.forSweep(
            MockFactory.createUtxoList(count: 2),
            vault.getAddress(1),
            1,
            vault);
        int targetFee = PSBT
            .parse(vault.addSignatureToPsbt(
                PSBT.fromTransaction(transaction, vault).serialize()))
            .getSignedTransaction(AddressType.p2wpkh)
            .getVirtualByte()
            .floor();
        int estimatedFee = await vault.estimateFeeForSweep(
            MockFactory.createUtxoList(count: 2), vault.getAddress(1), 1);
        expect(estimatedFee, isWithinRange(targetFee - 1, targetFee + 1));
      });
    });
  });
}
