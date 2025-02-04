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
        expect(() => AddressType.getAddressTypeFromScriptType('p2tr'),
            throwsException);
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
          SingleSignatureVault vault =
              SingleSignatureVault.fromKeyStore(keyStore);
          print(vault.derivationPath);
          print(keyStore.getPublicKey(0, isShnorr: true));
          print(AddressType.p2tr
              .getAddress(keyStore.getPublicKey(2, isShnorr: true)));
        });
        test('getWrondAddress', () {
          NetworkType.setNetworkType(NetworkType.mainnet);
          expect(
              () => AddressType.p2wsh.getAddress(
                  '039b3b694b8fc5b5e07fb069c783cac754f5d38c3e08bed1960e31fdb1dda35c24'),
              throwsException);
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
