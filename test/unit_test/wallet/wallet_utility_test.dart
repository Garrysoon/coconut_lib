@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('WalletUtility', () {
    group('getDerivationPath', () {
      test('Get standard derivation path of address type', () {
        expect(WalletUtility.getDerivationPath(AddressType.p2wpkh, 0),
            "m/84'/1'/0'");
        expect(WalletUtility.getDerivationPath(AddressType.p2wsh, 0),
            "m/48'/1'/0'/2'");
        expect(WalletUtility.getDerivationPath(AddressType.p2pkh, 0),
            "m/44'/1'/0'");
        expect(WalletUtility.getDerivationPath(AddressType.p2wpkhInP2sh, 0),
            "m/49'/1'/0'");
      });
    });
    group('validateAddress', () {
      test('Validate address due to network type', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            WalletUtility.validateAddress(
                "tb1qk4z5ysfc2k72pz2ws4dhskxdq772s7uqc35dp9"),
            true);
        expect(
            WalletUtility.validateAddress(
                "bc1qwa0ccwlyn65jc3w97w0qt93x84y8r4h3ret4mz"),
            false);
        expect(
            WalletUtility.validateAddress(
                "bcrt1qjpdazsu9penqt82sr7z4ln99w8wl5dj0xmulck"),
            true);
        NetworkType.setNetworkType(NetworkType.mainnet);
        expect(
            WalletUtility.validateAddress(
                "tb1qk4z5ysfc2k72pz2ws4dhskxdq772s7uqc35dp9"),
            false);
        expect(
            WalletUtility.validateAddress(
                "bc1qwa0ccwlyn65jc3w97w0qt93x84y8r4h3ret4mz"),
            true);
        expect(
            WalletUtility.validateAddress(
                "bcrt1qjpdazsu9penqt82sr7z4ln99w8wl5dj0xmulck"),
            false);
      });
      test('Valid mainnet P2PKH address', () {
        expect(
            WalletUtility.validateAddress('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'),
            isTrue);
      });

      test('Valid mainnet P2SH address', () {
        expect(
            WalletUtility.validateAddress('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'),
            isTrue);
      });

      test('Valid mainnet Bech32 address (P2WPKH)', () {
        NetworkType.setNetworkType(NetworkType.mainnet);
        expect(
            WalletUtility.validateAddress(
                'bc1qwa0ccwlyn65jc3w97w0qt93x84y8r4h3ret4mz'),
            true);
      });

      test('Valid mainnet Bech32m address (Taproot)', () {
        NetworkType.setNetworkType(NetworkType.mainnet);
        expect(
            WalletUtility.validateAddress(
                'bc1p0n9w6rnw2t77dww8ha32mdcweggr23zdwv9772apnwmv74p22c8slav7sx'),
            isTrue);
      });

      test('Invalid mainnet address with testnet prefix', () {
        NetworkType.setNetworkType(NetworkType.mainnet);
        expect(
            WalletUtility.validateAddress(
                'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080'),
            isFalse);
      });

      test('Valid testnet P2PKH address', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            WalletUtility.validateAddress('mkD3FXLW5tXVNMTACg5pXpwmbAjR6Y8R7Y'),
            isTrue);
      });

      test('Valid testnet P2SH address', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            WalletUtility.validateAddress(
                '2N2JD6wb56AfK4tfmM6PwdVmoYk2dCKf4Br'),
            isTrue);
      });

      test('Valid testnet Bech32 address (P2WPKH)', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            WalletUtility.validateAddress(
                'tb1qckwmxscea0rjrqvrhye7djz59nev2e9wgdjvn6'),
            isTrue);
      });

      test('Valid testnet Bech32m address (Taproot)', () {
        NetworkType.setNetworkType(NetworkType.testnet);
        expect(
            WalletUtility.validateAddress(
                'tb1qckwmxscea0rjrqvrhye7djz59nev2e9wgdjvn6'),
            isTrue);
      });

      test('Invalid address with invalid prefix', () {
        expect(
            WalletUtility.validateAddress(
                'zz1qhl6rqwrd99nvky77xyykdrs9hhr2yz37m8ws44'),
            isFalse);
      });

      test('Invalid Bech32 address with wrong hrp', () {
        expect(
            WalletUtility.validateAddress(
                'bc1x508d6qejxtdg4y5r3zarvary0c5xw7kygt080'),
            isFalse);
      });

      test('Invalid Bech32 address with empty data', () {
        expect(WalletUtility.validateAddress('bc1'), isFalse);
      });

      test('Invalid Base58 address with wrong version byte', () {
        expect(
            WalletUtility.validateAddress('4A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'),
            isFalse);
      });

      test('Invalid Base58 address length', () {
        expect(WalletUtility.validateAddress('1A1zP1eP5QGefi2DMPTfTL5S'),
            isFalse); // Too short
        expect(
            WalletUtility.validateAddress(
                '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNaExtra'),
            isFalse); // Too long
      });

      test('Invalid address with non-alphanumeric characters', () {
        expect(
            WalletUtility.validateAddress(
                '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa!'),
            isFalse);
      });

      test('Valid regtest Bech32 address', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        expect(
            WalletUtility.validateAddress(
                'bcrt1qjpdazsu9penqt82sr7z4ln99w8wl5dj0xmulck'),
            isTrue);
      });

      test('Invalid regtest Bech32 address with mainnet prefix', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        expect(
            WalletUtility.validateAddress(
                'bc1qhl6rqwrd99nvky77xyykdrs9hhr2yz37m8ws44'),
            isFalse);
      });

      test('Invalid Bech32m address with incorrect data type', () {
        expect(
            WalletUtility.validateAddress(
                'bc1p5cyxnuxmeuwuvkwfem96l9yx2gk70hqn5w7z'),
            isFalse); // Data length too short
      });

      test('Invalid Bech32 address with mixed case', () {
        expect(
            WalletUtility.validateAddress(
                'Bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080'),
            isFalse); // Mixed case
      });
    });
    group('isInMnemonicWordList', () {
      test('Check mnemonic word', () {
        expect(WalletUtility.isInMnemonicWordList('abandon'), true);
        expect(WalletUtility.isInMnemonicWordList('abandonz'), false);
      });
    });
    group('validateMnemonic', () {
      test('Check mnemonic validation', () {
        expect(
            WalletUtility.validateMnemonic(
                'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon'),
            false);
        expect(
            WalletUtility.validateMnemonic(
                'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'),
            true);
      });
      test('Test mnemonic validation exception', () {
        String wrongMnemonic1 =
            'eagle hedgehog then coral type message loyal blanket hundred ritual flock zebra mammal above dial senior easy hope canoe myth neck number face abandon';
        String wrongMnemonic2 =
            'rib reward pill favorite expect elder cash patient hour bird genius myth';
        String wrongMnemonic3 =
            'wise tragic potato piece tail intact second bird ignore absent sleep attract cradle double arm';
        String wrongMnemonic4 =
            'foster across update trigger grid print choose tag water secon system town';
        expect(WalletUtility.validateMnemonic(wrongMnemonic1), false);
        expect(WalletUtility.validateMnemonic(wrongMnemonic2), false);
        expect(WalletUtility.validateMnemonic(wrongMnemonic3), false);
        expect(WalletUtility.validateMnemonic(wrongMnemonic4), false);
      });
    });
    group('validateDerivationPath', () {
      test("Valid derivation path (standard)", () {
        expect(WalletUtility.validateDerivationPath("m/44'/0'/0'/0/0"), isTrue);
      });

      test("Valid derivation path with hardened keys only", () {
        expect(WalletUtility.validateDerivationPath("m/44'/1'/0'"), isTrue);
      });

      test("Valid derivation path with no sub-paths", () {
        expect(WalletUtility.validateDerivationPath("m"), isTrue);
      });

      test("Invalid derivation path with wrong prefix", () {
        expect(
            WalletUtility.validateDerivationPath("n/44'/0'/0'/0/0"), isFalse);
      });

      test("Invalid derivation path with non-numeric segment", () {
        expect(
            WalletUtility.validateDerivationPath("m/44'/x'/0'/0/0"), isFalse);
      });

      test("Invalid derivation path with negative index", () {
        expect(
            WalletUtility.validateDerivationPath("m/44'/-1/0'/0/0"), isFalse);
      });

      test("Invalid derivation path with number out of range", () {
        expect(WalletUtility.validateDerivationPath("m/44'/2147483648/0'/0/0"),
            isFalse); // 2^31
      });

      test("Invalid derivation path with empty segment", () {
        expect(WalletUtility.validateDerivationPath("m/44'//0'/0/0"), isFalse);
      });

      test("Invalid derivation path with trailing slash", () {
        expect(
            WalletUtility.validateDerivationPath("m/44'/0'/0'/0/0/"), isFalse);
      });

      test("Invalid derivation path with missing m prefix", () {
        expect(WalletUtility.validateDerivationPath("/44'/0'/0'/0/0"), isFalse);
      });

      test("Invalid derivation path with spaces", () {
        expect(WalletUtility.validateDerivationPath("m /44' /0'/ 0'/0/0"),
            isFalse);
      });

      test("Valid derivation path with maximum number", () {
        expect(WalletUtility.validateDerivationPath("m/44'/2147483647/0'/0/0"),
            isTrue); // 2^31-1
      });
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
            Codec.encodeHex(WalletUtility.aggregatePublicKey(pubs))
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
            Codec.encodeHex(WalletUtility.aggregatePublicKey(pubs))
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
            Codec.encodeHex(WalletUtility.aggregatePublicKey(pubs))
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
            Codec.encodeHex(WalletUtility.aggregatePublicKey(pubs))
                .toUpperCase(),
            '69BC22BFA5D106306E48A20679DE1D7389386124D07571D0D872686028C26A3E');
      });
    });
  });
}
