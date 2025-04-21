@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Descriptor', () {
    group('Descriptor.forSingleSignature', () {
      test('Generate p2wpkh descriptor', () {
        Descriptor descriptor = Descriptor.forSingleSignature(
            AddressType.p2wpkh,
            "vpub5ZZ1q76vi2LR9PeQDoV13u8TZwsyqKa7yBfD3GnPPvBjVU9ZnBTMkwzCHCVBZaPHDKJNEdMKo8MTyrQ9234idzSG9nHFD6hsUB8HJ14NBg7",
            "84'/1'/0'",
            "98C7D774");

        String target =
            "wpkh([98C7D774/84'/1'/0']vpub5ZZ1q76vi2LR9PeQDoV13u8TZwsyqKa7yBfD3GnPPvBjVU9ZnBTMkwzCHCVBZaPHDKJNEdMKo8MTyrQ9234idzSG9nHFD6hsUB8HJ14NBg7/<0;1>/*)#7ra9g9d8";
        expect(descriptor, isA<Descriptor>());
        expect(descriptor.serialize(), target);
      });
      test('Generate nested segwit descriptor', () {
        Descriptor descriptor = Descriptor.forSingleSignature(
            AddressType.p2wpkhInP2sh,
            "xpub6CorSC5E8wkNboiq84Ndxvm3w4ccSA4MbEva8khZ4a5Cxk8hQYwrsJoPsmL8KsmCeFWzD4irCJdEqcd7kKRi5SAg355pTxTgHW2eVzQu2dd",
            "49'/1'/0'",
            "33a0cbfd");

        String target =
            "sh(wpkh([33a0cbfd/49'/1'/0']xpub6CorSC5E8wkNboiq84Ndxvm3w4ccSA4MbEva8khZ4a5Cxk8hQYwrsJoPsmL8KsmCeFWzD4irCJdEqcd7kKRi5SAg355pTxTgHW2eVzQu2dd/<0;1>/*))#63c9rvn6";
        expect(descriptor, isA<Descriptor>());
        expect(descriptor.serialize(), target);
      });
    });
    group('Descriptor.forMultisignature', () {
      test('Generate p2wsh wallet descriptor', () {
        String desc =
            'wsh(sortedmulti(2,[e50bd392/48h/0h/0h/2h]xpub6FPPhpChFv7pQE7D19ZNGoFcCUzmMdwEMwqGFshE7SCfBiN5YqpejTKkshCS3sawXF98w7j5YeaYmnVdcMuX4wLr2pwiUaccvb4WsF1w5Kz/<0;1>/*,[906222f7/48h/0h/0h/2h]xpub6EgRoGnrQpGy55qdvYXqCspbx3M4zwEJqqMY4Gvf8wTd927pAoiknQBWvLpk6gh1tWJErqgW6S4QDJykGedZ7ngV2TbRG25wUEpnCox9dKA/<0;1>/*,[476ec2dc/48h/0h/0h/2h]xpub6ERySjYpfyoWiREzdy5hZFjzkPWQK5GzUiPppcqdYm1qqbi5H8tpUeX93LG1MzQLn4Dj5iMwydhnFLqWvHHJk2ZHiKD9gYZh6YbVR1VQT1V/<0;1>/*))#x9cc762c';
        List<String> pubList = [
          'xpub6FPPhpChFv7pQE7D19ZNGoFcCUzmMdwEMwqGFshE7SCfBiN5YqpejTKkshCS3sawXF98w7j5YeaYmnVdcMuX4wLr2pwiUaccvb4WsF1w5Kz',
          'xpub6EgRoGnrQpGy55qdvYXqCspbx3M4zwEJqqMY4Gvf8wTd927pAoiknQBWvLpk6gh1tWJErqgW6S4QDJykGedZ7ngV2TbRG25wUEpnCox9dKA',
          'xpub6ERySjYpfyoWiREzdy5hZFjzkPWQK5GzUiPppcqdYm1qqbi5H8tpUeX93LG1MzQLn4Dj5iMwydhnFLqWvHHJk2ZHiKD9gYZh6YbVR1VQT1V'
        ];
        Descriptor descriptor = Descriptor.forMultisignature(AddressType.p2wsh,
            pubList, "48h/0h/0h/2h", ['e50bd392', '906222f7', '476ec2dc'], 2);
        // print(descriptor.serialize());
        expect(descriptor, isA<Descriptor>());
        expect(descriptor.serialize(), desc);
      });
    });
    group('Descriptor.parse(String descriptor)', () {
      test('Parse p2wpkh descriptor', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/0/*)#tdf2kj7c";
        final descriptor = Descriptor.parse(bip84Descriptor);
        expect(descriptor, isA<Descriptor>());
        expect(descriptor.scriptType, 'wpkh');
      });
      test('Parse p2wpkh descriptor (ignore checksum)', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/0/*)";
        final descriptor =
            Descriptor.parse(bip84Descriptor, ignoreChecksum: true);
        expect(descriptor, isA<Descriptor>());
        expect(descriptor.scriptType, 'wpkh');
      });
      test('parse nested segwit descriptor', () {
        String desc =
            'sh(wpkh([33a0cbfd/49h/0h/0h]xpub6CorSC5E8wkNboiq84Ndxvm3w4ccSA4MbEva8khZ4a5Cxk8hQYwrsJoPsmL8KsmCeFWzD4irCJdEqcd7kKRi5SAg355pTxTgHW2eVzQu2dd/<0;1>/*))#z3ulg0nr';
        // sh(wpkh([33a0cbfd/49h/0h/0h]xpub6CorSC5E8wkNboiq84Ndxvm3w4ccSA4MbEva8khZ4a5Cxk8hQYwrsJoPsmL8KsmCeFWzD4irCJdEqcd7kKRi5SAg355pTxTgHW2eVzQu2dd/<0;1>/*/<0;1>/*))#ghuqfgdf
        Descriptor descriptor = Descriptor.parse(desc);
        expect(descriptor, isA<Descriptor>());
        expect(descriptor.serialize(), desc);
      });
      test('Checksum error exception', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/0/*)#tdf2kj7a";
        expect(() => Descriptor.parse(bip84Descriptor), throwsException);
      });
    });
    group('getDerivationPath', () {
      test('Get derivation path', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/0/*)#tdf2kj7c";
        final descriptor = Descriptor.parse(bip84Descriptor);
        expect(descriptor.getDerivationPath(0), "m/84'/1'/0'");
      });
    });
    group('getFingerprint', () {
      test('Get fingerprint', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/0/*)#tdf2kj7c";
        final descriptor = Descriptor.parse(bip84Descriptor);
        expect(descriptor.getFingerprint(0), '98c7d774');
      });
    });
    group('getPublicKey', () {
      test('Get extended public key', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/0/*)#tdf2kj7c";
        final descriptor = Descriptor.parse(bip84Descriptor);
        expect(descriptor.getPublicKey(0),
            'tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm');
      });
    });
    group('serialize', () {
      test('Serialize p2wpkh', () {
        const bip84Descriptor =
            "wpkh([98c7d774/84'/1'/0']tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm/<0;1>/*)#rha32pam";
        final descriptor = Descriptor.forSingleSignature(
            AddressType.p2wpkh,
            'tpubDDbAxgGSifNq7nDVLi3LfzeqF1GXhx4BM3HwxcdJVqhPLxSjMida9WyJZeV95teMpW4tMA4KFYtcSc7srHjz7uFkx4RQ4T15baqyqBdYTgm',
            "84'/1'/0'",
            '98c7d774');
        String result = descriptor.serialize();
        //print(result);
        expect(result, bip84Descriptor);
      });
      test('Serialize p2wsh', () {
        String desc =
            'wsh(sortedmulti(2,[e50bd392/48h/0h/0h/2h]xpub6FPPhpChFv7pQE7D19ZNGoFcCUzmMdwEMwqGFshE7SCfBiN5YqpejTKkshCS3sawXF98w7j5YeaYmnVdcMuX4wLr2pwiUaccvb4WsF1w5Kz/<0;1>/*,[906222f7/48h/0h/0h/2h]xpub6EgRoGnrQpGy55qdvYXqCspbx3M4zwEJqqMY4Gvf8wTd927pAoiknQBWvLpk6gh1tWJErqgW6S4QDJykGedZ7ngV2TbRG25wUEpnCox9dKA/<0;1>/*,[476ec2dc/48h/0h/0h/2h]xpub6ERySjYpfyoWiREzdy5hZFjzkPWQK5GzUiPppcqdYm1qqbi5H8tpUeX93LG1MzQLn4Dj5iMwydhnFLqWvHHJk2ZHiKD9gYZh6YbVR1VQT1V/<0;1>/*))#x9cc762c';
        List<String> pubList = [
          '[e50bd392/48h/0h/0h/2h]xpub6FPPhpChFv7pQE7D19ZNGoFcCUzmMdwEMwqGFshE7SCfBiN5YqpejTKkshCS3sawXF98w7j5YeaYmnVdcMuX4wLr2pwiUaccvb4WsF1w5Kz/<0;1>/*',
          '[906222f7/48h/0h/0h/2h]xpub6EgRoGnrQpGy55qdvYXqCspbx3M4zwEJqqMY4Gvf8wTd927pAoiknQBWvLpk6gh1tWJErqgW6S4QDJykGedZ7ngV2TbRG25wUEpnCox9dKA/<0;1>/*',
          '[476ec2dc/48h/0h/0h/2h]xpub6ERySjYpfyoWiREzdy5hZFjzkPWQK5GzUiPppcqdYm1qqbi5H8tpUeX93LG1MzQLn4Dj5iMwydhnFLqWvHHJk2ZHiKD9gYZh6YbVR1VQT1V/<0;1>/*'
        ];
        Descriptor descriptor =
            Descriptor('wsh', pubList, requiredSignatures: 2);
        expect(descriptor.serialize(), desc);
      });

      test('Serialize nested segwit', () {
        String desc =
            'sh(wpkh([33a0cbfd/49h/0h/0h]xpub6CorSC5E8wkNboiq84Ndxvm3w4ccSA4MbEva8khZ4a5Cxk8hQYwrsJoPsmL8KsmCeFWzD4irCJdEqcd7kKRi5SAg355pTxTgHW2eVzQu2dd/<0;1>/*))#z3ulg0nr';
        List<String> pubList = [
          '[33a0cbfd/49h/0h/0h]xpub6CorSC5E8wkNboiq84Ndxvm3w4ccSA4MbEva8khZ4a5Cxk8hQYwrsJoPsmL8KsmCeFWzD4irCJdEqcd7kKRi5SAg355pTxTgHW2eVzQu2dd/<0;1>/*'
        ];
        Descriptor descriptor =
            Descriptor('sh-wpkh', pubList, requiredSignatures: 2);
        expect(descriptor.serialize(), desc);
        //final descriptor =
      });
    });
  });
}
