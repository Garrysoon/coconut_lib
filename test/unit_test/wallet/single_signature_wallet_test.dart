@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() async {
  group('SingleSignatureWallet', () {
    late SingleSignatureVault vault;
    late SingleSignatureWallet wallet;

    setUpAll(() async {
      NetworkType.setNetworkType(NetworkType.regtest);
      vault = MockFactory.createP2wpkhVault();
      wallet = SingleSignatureWallet.fromDescriptor(vault.descriptor);
    });
    group('SingleSignatureWallet.fromDescriptor', () {
      test('Generate single signature wallet from descriptor', () {
        SingleSignatureWallet targetWallet =
            SingleSignatureWallet.fromDescriptor(vault.descriptor);
        expect(targetWallet.derivationPath, vault.derivationPath);
        expect(targetWallet.addressType, vault.addressType);
        expect(targetWallet.keyStore.masterFingerprint,
            vault.keyStore.masterFingerprint);
      });
      test('Generate single signature wallet from multisignature exception',
          () {
        expect(
            () => SingleSignatureWallet.fromDescriptor(
                MockFactory.createP2wshVault().descriptor),
            throwsException);
      });
    });
    group('toJson', () {
      test('Get json text of single signature wallet', () {
        expect(wallet.toJson().hashCode, 275252338);
      });
    });
    group('SingleSignatureWallet.fromJson', () {
      test('Generate single signature wallet from json', () {
        SingleSignatureWallet targetWallet =
            SingleSignatureWallet.fromJson(wallet.toJson());
        expect(targetWallet.keyStore.masterFingerprint,
            wallet.keyStore.masterFingerprint);
      });
    });
    group('SingleSignatureWallet.fromCryptoAccountPayload', () {
      final String payload = '''
        {
          "1": 3461324038,
          "2": [
            {
              "2": false,
              "3": "02C5F9EA7C223BC038CFFAD759FB4CDFB2C5BFBC173FFF5A51E7927290A85D2362",
              "4": "44DE28F7A8394ED8BC4B7CD9204BD05569E760A0C7CC759DAB7B7B6F1A2DD109",
              "5": {"1": 0, "2": 0},
              "6": {"1": [84, true, 0, true, 0, true], "2": 3461324038, "3": 3},
              "7": {"1": [0, false, [], false], "3": 0},
              "8": 2319540438
            },
            {
              "2": false,
              "3": "039BEEB21E4759714375DC7C1EF753C64C6999B82962DC853545B1F1AB6BEC52B6",
              "4": "FFDB8FA30BF2C757874971BA620B3FED07898FE65A581B6F157283BB115E0A20",
              "5": {"1": 0, "2": 0},
              "6": {"1": [49, true, 0, true, 0, true], "2": 3461324038, "3": 3},
              "7": {"1": [0, false, [], false], "3": 0},
              "8": 117992223
            },
            {
              "2": false,
              "3": "03AC1B7408B5B30ECBB323FEA32713D5EC2C49467CC95D9BB363DC5EAD2B4ADBFF",
              "4": "CED796CCF134FFD3667FD82FF1337B1D0E659A909FC1C631F425FF5209C7958C",
              "5": {"1": 0, "2": 0},
              "6": {"1": [44, true, 0, true, 0, true], "2": 3461324038, "3": 3},
              "7": {"1": [0, false, [], false], "3": 0},
              "8": 2486618859
            }
          ]
        }
        ''';
      test('Generate single signature wallet from crypto account payload', () {
        NetworkType.setNetworkType(NetworkType.mainnet);
        SingleSignatureWallet wallet =
            SingleSignatureWallet.fromCryptoAccountPayload(payload);

        expect(
            Codec.encodeHex(wallet.keyStore.extendedPublicKey.publicKey)
                .toUpperCase(),
            '02C5F9EA7C223BC038CFFAD759FB4CDFB2C5BFBC173FFF5A51E7927290A85D2362');
        expect(wallet.keyStore.extendedPublicKey.parentFingerprint,
            Converter.decToHex(2319540438));
        expect(
            wallet.keyStore.masterFingerprint, Converter.decToHex(3461324038));
        expect(wallet.derivationPath, "m/84'/0'/0'");
        expect(wallet.addressType, AddressType.p2wpkh);
      });

      test('Network type is not match with payload', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        expect(() => SingleSignatureWallet.fromCryptoAccountPayload(payload),
            throwsException);
      });
    });
  });
}
