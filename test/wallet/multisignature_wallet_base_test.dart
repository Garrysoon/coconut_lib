@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  group('MultisignatureWalletBase', () {
    late MultisignatureVault vault;
    setUpAll(() {
      vault = MockFactory.createP2wshVault();
    });
    group('get totalSigner', () {
      test('Get total signer of vault', () {
        expect(vault.totalSigner, 3);
      });
    });
    group('get requiredSignature', () {
      test('Get required signature of vault', () {
        expect(vault.requiredSignature, 2);
      });
    });
    group('get keyStoreList', () {
      test('Get key store list from vault', () {
        expect(vault.keyStoreList, isA<List<KeyStore>>());
        expect(vault.keyStoreList.length, 3);
      });
    });
    group('getAddress', () {
      test('Get address from vault', () {
        expect(vault.getAddress(0),
            'tb1qd22redun2rm8mt4zxjazks5mr8dxxdjnk57hhgf2fw2ghmarjahqm9g672');
        expect(vault.getAddress(0, isChange: true),
            'tb1qqpte5pxtdrpaw8xqxc2t3j3n3c0v02trla9zwfvnw59nguj8h9lqqtsqn2');
      });
    });

    group('getAddressWithDerivationPath', () {
      test('get address from vault with derivation path', () {
        expect(vault.getAddressWithDerivationPath("m/48'/1'/0'/2'/10/0"),
            'tb1qd22redun2rm8mt4zxjazks5mr8dxxdjnk57hhgf2fw2ghmarjahqm9g672');
        expect(vault.getAddressWithDerivationPath("m/48'/1'/0'/2'/10/1"),
            'tb1qy5v9z67n7aqkqyd2p7an0sl23ccxrducvs95e5mehygex0rhxh4qth92w0');
        expect(vault.getAddressWithDerivationPath("m/48'/1'/0'/2'/10/5"),
            'tb1qq0q7qav557ea92qszuytkyh33ly8elz0whcuwsycux59pzqnyulsc5vskx');
      });
    });
    group('getCoordinatorBsms', () {
      test('Get coordinator bsms from vault', () {
        expect(vault.getCoordinatorBsms().hashCode, 1032617779);
      });
    });
    group('getWitnessScript', () {
      test('Get witness script of vault', () {
        expect(
            vault.getWitnessScript("m/48'/1'/0'/2'/10/1").hashCode, 669698738);
      });
    });
    group('canSignToPsbt', () {
      test('Check the vault can sign', () {
        MultisignatureVault otherVault =
            MockFactory.createP2wshVault(testWalletType: TestWalletType.random);
        Psbt psbt = MockFactory.createP2wshUnsignedPsbt();
        expect(otherVault.canSignToPsbt(psbt.serialize()), false);
        expect(vault.canSignToPsbt(psbt.serialize()), true);
      });
    });
    group('addSignatureToPsbt', () {
      test('Sign to PSBT', () {
        Psbt unsignedPsbt = MockFactory.createP2wshUnsignedPsbt();
        String signedPsbtText =
            vault.addSignatureToPsbt(unsignedPsbt.serialize());
        expect(signedPsbtText.hashCode, 244975286);

        Psbt signedPsbt = Psbt.parse(signedPsbtText);

        for (PsbtInput input in signedPsbt.inputs) {
          expect(input.requiredSignature, input.partialSigList.length);
        }
      });
    });
    // group('estimateFee', () {
    //   test('Get estimated fee', () async {
    //     Transaction targetTransaction = MockFactory.createP2wshSignedPsbt()
    //         .getSignedTransaction(AddressType.p2wsh);
    //     int estimatedFee = await vault.estimateFee(
    //         MockFactory.createUtxoList(count: 2),
    //         vault.getAddress(1),
    //         vault.getAddress(1, isChange: true),
    //         15000,
    //         1);
    //     int targetFee = targetTransaction
    //         .estimateVirtualByte(AddressType.p2wsh,
    //             requiredSignature: 2, totalSigner: 3)
    //         .ceil();
    //     expect(estimatedFee, targetFee);
    //   });
    // });
    // group('estimateFeeWithMaximum', () {
    //   Matcher isWithinRange(int lower, int upper) => predicate(
    //       (x) => x is num && x >= lower && x <= upper,
    //       'is within range $lower to $upper');
    //   test('Get estimated fee for sweep', () async {
    //     Transaction transaction = Transaction.forSweep(
    //         MockFactory.createUtxoList(count: 2),
    //         vault.getAddress(1),
    //         1,
    //         vault);
    //     int targetFee = Psbt.parse(vault.addSignatureToPsbt(
    //             Psbt.fromTransaction(transaction, vault).serialize()))
    //         .getSignedTransaction(AddressType.p2wsh)
    //         .getVirtualByte()
    //         .floor();
    //     int estimatedFee = await vault.estimateFeeForSweep(
    //         MockFactory.createUtxoList(count: 2), vault.getAddress(1), 1);
    //     expect(estimatedFee, isWithinRange(targetFee - 1, targetFee + 1));
    //   });
    // });
  });
}
