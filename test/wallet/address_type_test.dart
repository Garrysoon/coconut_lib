@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('AddressType', () {
    group('getAddressTypeByVersion', () {
      test('getAddressTypeFromScriptType', () {
        expect(AddressType.getAddressTypeFromScriptType('p2pkh'),
            AddressType.p2pkh);
        expect(
            AddressType.getAddressTypeFromScriptType('p2sh'), AddressType.p2sh);
        expect(AddressType.getAddressTypeFromScriptType('p2wpkh'),
            AddressType.p2wpkh);
        expect(AddressType.getAddressTypeFromScriptType('p2wsh'),
            AddressType.p2wsh);
        expect(
            AddressType.getAddressTypeFromScriptType('p2tr'), AddressType.p2tr);
      });

      group('isTestnetVersion', () {
        test('isTestnetVersion', () {
          expect(AddressType.isTestnetVersion(0x045f1cf6), true);
          expect(AddressType.isTestnetVersion(0x04b24746), false);
          expect(AddressType.isTestnetVersion(0x02575483), true);
          expect(AddressType.isTestnetVersion(0x02aa7ed3), false);
          expect(() => AddressType.isTestnetVersion(0x00), throwsException);
        });
      });

      group('getAddressTypeByVersion', () {
        test('getAddressTypeByVersion', () {
          expect(AddressType.getAddressTypeByVersion(0x045f1cf6),
              AddressType.p2wpkh);
          expect(AddressType.getAddressTypeByVersion(0x04b24746),
              AddressType.p2wpkh);
          expect(AddressType.getAddressTypeByVersion(0x02575483),
              AddressType.p2wsh);
          expect(AddressType.getAddressTypeByVersion(0x02aa7ed3),
              AddressType.p2wsh);
          expect(
              () => AddressType.getAddressTypeByVersion(0x00), throwsException);
        });
      });

      group('getAddress', () {
        test('getP2pkhAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.p2pkh.getAddress(
                  '038b5e44fc67861d87842e756b8249072a55a81b0daa0bd5d14919aa75c58e9daf'),
              '1HcmPiFd9zwYzPbmv3hcEhCajHcqgdLhSK');
          NetworkType.setNetworkType(NetworkType.testnet);
          expect(
              AddressType.p2pkh.getAddress(
                  '038b5e44fc67861d87842e756b8249072a55a81b0daa0bd5d14919aa75c58e9daf'),
              'mx8igmLby2NomW5Pdcfz4cQubHDYcmVmrA');
        });
        test('getP2wpkhAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.p2wpkh.getAddress(
                  '0298029ebbc7640beb3a3e8885759d5a47e3f22d632ca58bb2815e6fcf72e0df07'),
              'bc1qxv635h49ewh5qagssy3xl8gpnr45d5hdqmd0aj');
          NetworkType.setNetworkType(NetworkType.testnet);
          expect(
              AddressType.p2wpkh.getAddress(
                  '0298029ebbc7640beb3a3e8885759d5a47e3f22d632ca58bb2815e6fcf72e0df07'),
              'tb1qxv635h49ewh5qagssy3xl8gpnr45d5hd2akuxp');
        });
        test('getP2wpkhInP2shAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.p2wpkhInP2sh.getAddress(
                  '039b3b694b8fc5b5e07fb069c783cac754f5d38c3e08bed1960e31fdb1dda35c24'),
              '37VucYSaXLCAsxYyAPfbSi9eh4iEcbShgf');
        });
        test('getP2trSingleSignatureAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          KeyStore keyStore = KeyStore.fromMnemonic(
              "machine crack daughter fish credit glare raven fever tunnel delay fish record",
              AddressType.p2tr);

          // print(vault.derivationPath);
          // print(keyStore.getPublicKey(0, isSchnorr: true));
          expect(
              AddressType.p2tr
                  .getAddress(keyStore.getPublicKey(2, isSchnorr: true)),
              'bc1p4trvc4y8hu4cyj93vytg57dx5853d9qjrs9w7ctamn5gn6frgawqtkpnv8');
        });
        test('getWrondAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              () => AddressType.p2wsh.getAddress(
                  '039b3b694b8fc5b5e07fb069c783cac754f5d38c3e08bed1960e31fdb1dda35c24'),
              throwsException);
        });

        test('getP2trSingleSignatureAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.getP2trSingleSignatureAddress(
                  'cc8a4bc64d897bddc5fbc2f670f7a8ba0b386779106cf1223c6fc5d7cd6fc115'),
              'bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr');
          expect(
              AddressType.p2tr.getAddress(
                  '83dfe85a3151d2517290da461fe2815591ef69f2b18a2ce63f01697a8b313145'),
              'bc1p4qhjn9zdvkux4e44uhx8tc55attvtyu358kutcqkudyccelu0was9fqzwh');
        });
        test('getP2trScriptPathMultisignatureAddress', () {
          //TODO : need to validate the address
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.getP2trScriptPathMultisignatureAddress([
                'febe583fa77e49089f89b78fa8c116710715d6e40cc5f5a075ef1681550dd3c4',
                'd0fa46cb883e940ac3dc5421f05b03859972639f51ed2eccbf3dc5a62e2e1b15'
              ], 2),
              'bc1p2s5lw3ur53usrj7m0jytdexp26gmsyamvjwaamh8wy5qm90kfylqhq964c');
        });
      });
      group('getTaprootAddress', () {
        test('Get Taproot address with empty merkle root', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.getTaprootAddress(
                  'd6889cb081036e0faefa3a35157ad71086b123b2b144b649798b494c300a961d',
                  ''),
              'bc1p2wsldez5mud2yam29q22wgfh9439spgduvct83k3pm50fcxa5dps59h4z5');
        });

        test('Get Taproot address with script (case 1)', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.getTaprootAddress(
                  '187791b6f712a8ea41c8ecdd0ee77fab3e85263b37e1ec18a3651926b3a6cf27',
                  '5b75adecf53548f3ec6ad7d78383bf84cc57b55a3127c72b9a2481752dd88b21'),
              'bc1pz37fc4cn9ah8anwm4xqqhvxygjf9rjf2resrw8h8w4tmvcs0863sa2e586');
        });
        test('Get Taproot address with script (case 2)', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.getTaprootAddress(
                  '93478e9488f956df2396be2ce6c5cced75f900dfa18e7dabd2428aae78451820',
                  'c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b'),
              'bc1punvppl2stp38f7kwv2u2spltjuvuaayuqsthe34hd2dyy5w4g58qqfuag5');
        });
      });

      group('getMultisignatureAddress', () {
        test('getP2shAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);

          expect(
              AddressType.p2sh.getMultisignatureAddress([
                '02d22360accac12f6804a1e3bc2fa2a9e6bce1d48647f829a8fc5e64577d48ea86',
                '02d0a35af9057b528adf181a00876dd0d2cee241cf1b2ce0719e8c4ed9939b99f2',
                '02a8c51b0ba20e9262291b8002112f9892069355049cade351f15f62e64668ce38'
              ], 2),
              '37Y7Ci36ZzwmxfUt6vrnz1RDrEFp7EtdRE');
        });
        test('getP2wshAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              AddressType.p2wsh.getMultisignatureAddress([
                '02ecb68401036cf502e80e15e0876f1f62627e933c97b1d2d2ebedb9e5b88f562e',
                '021f4a8611bc27942b8f80fb25a2d66c3fd82739bb672909ec519a4f7aac36588b',
                '03c6382a22a126247191d45ef5742f8315c93e1de73eab0ac025c55bbfb18dfb54'
              ], 2),
              'bc1qa8y7pfegg6de9z5ffquq2eeqdf5qhr7dujeec3t654tcch9uvmyqyz3h36');
        });

        test('getWrongMultisigatureAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              () => AddressType.p2wpkh.getMultisignatureAddress([
                    '02ecb68401036cf502e80e15e0876f1f62627e933c97b1d2d2ebedb9e5b88f562e',
                    '021f4a8611bc27942b8f80fb25a2d66c3fd82739bb672909ec519a4f7aac36588b',
                    '03c6382a22a126247191d45ef5742f8315c93e1de73eab0ac025c55bbfb18dfb54'
                  ], 2),
              throwsException);
        });
      });
      group('operator ==', () {
        test('operator ==', () {
          expect(AddressType.p2pkh == AddressType.p2pkh, true);
          expect(AddressType.p2pkh == AddressType.p2wpkh, false);
        });
        test('hashCode', () {
          expect(
              AddressType.p2pkh.hashCode == AddressType.p2pkh.hashCode, true);
          expect(
              AddressType.p2pkh.hashCode == AddressType.p2wpkh.hashCode, false);
        });
      });
      group('toString', () {
        test('toString', () {
          expect(AddressType.p2pkh.toString(), 'P2PKH');
        });
      });
    });
  });
}
