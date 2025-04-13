@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

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
        expect(signedPsbtText.hashCode, 176233417);

        Psbt signedPsbt = Psbt.parse(signedPsbtText);

        for (PsbtInput input in signedPsbt.inputs) {
          expect(input.requiredSignature, input.signedCount);
        }
      });
    });

    group('getAddregatedPublilcKey', () {
      test('Get aggregatedPublicKey', () {});
    });

    group('aggregatePublicKey', () {
      //Test vector from : https://github.com/bitcoin/bips/blob/master/bip-0327/vectors/key_agg_vectors.json
      List<String> publicKeyList = [
        "02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",
        "03DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659",
        "023590A94E768F8E1815C2F24B4D80A8E3149316C3518CE7B7AD338368D038CA66",
        "020000000000000000000000000000000000000000000000000000000000000005",
        "02FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC30",
        "04F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9",
        "03935F972DA013F80AE011890FA89B67A27B7BE6CCB24D3274D18B2D4067F261A9"
      ];
      test('Get aggregated public key (case 1)', () {
        List<String> pubs = [
          publicKeyList[0],
          publicKeyList[1],
          publicKeyList[2]
        ];
        expect(
            Codec.encodeHex(
                    MultisignatureWalletBase.aggregatePublicKey(pubs, true))
                .toUpperCase(),
            '90539EEDE565F5D054F32CC0C220126889ED1E5D193BAF15AEF344FE59D4610C');
      });

      test('Get aggregated public key (case 2)', () {
        List<String> pubs = [
          publicKeyList[2],
          publicKeyList[1],
          publicKeyList[0]
        ];
        expect(
            Codec.encodeHex(
                    MultisignatureWalletBase.aggregatePublicKey(pubs, true))
                .toUpperCase(),
            '6204DE8B083426DC6EAF9502D27024D53FC826BF7D2012148A0575435DF54B2B');
      });

      test('Get aggregated public key (case 3)', () {
        List<String> pubs = [
          publicKeyList[0],
          publicKeyList[0],
          publicKeyList[0]
        ];
        expect(
            Codec.encodeHex(
                    MultisignatureWalletBase.aggregatePublicKey(pubs, true))
                .toUpperCase(),
            'B436E3BAD62B8CD409969A224731C193D051162D8C5AE8B109306127DA3AA935');
      });

      test('Get aggregated public key (case 4)', () {
        List<String> pubs = [
          publicKeyList[0],
          publicKeyList[0],
          publicKeyList[1],
          publicKeyList[1]
        ];
        expect(
            Codec.encodeHex(
                    MultisignatureWalletBase.aggregatePublicKey(pubs, true))
                .toUpperCase(),
            '69BC22BFA5D106306E48A20679DE1D7389386124D07571D0D872686028C26A3E');
      });
    });
  });
}
