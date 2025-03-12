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
  });
}
