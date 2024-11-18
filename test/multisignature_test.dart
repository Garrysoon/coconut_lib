@Tags(['integration'])
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

main() async {
  group('Multisig Vault Generation', () {
    late SingleSignatureVault insideVault1;
    late SingleSignatureVault insideVault2;
    late SingleSignatureVault outsideVault;
    late MultisignatureVault multisignatureVault;

    setUpAll(() {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);

      insideVault1 = SingleSignatureVault.fromMnemonic(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          AddressType.p2wpkh,
          passphrase: 'ABC');

      insideVault2 = SingleSignatureVault.fromMnemonic(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          AddressType.p2wpkh,
          passphrase: 'DEF');

      outsideVault = SingleSignatureVault.fromMnemonic(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          AddressType.p2wpkh,
          passphrase: 'GHI');

      KeyStore insideKey1 =
          KeyStore.fromSeed(insideVault1.keyStore.seed, AddressType.p2wsh);
      KeyStore insideKey2 =
          KeyStore.fromSeed(insideVault2.keyStore.seed, AddressType.p2wsh);
      String signerBsms =
          outsideVault.getSignerBsms(AddressType.p2wsh, "outside signer");
      KeyStore outsideKey = KeyStore.fromSignerBsms(signerBsms);

      multisignatureVault = MultisignatureVault.fromKeyStoreList(
          [insideKey1, insideKey2, outsideKey], 2, AddressType.p2wsh);
    });

    test('bsms signer test', () {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);

      String signer =
          outsideVault.getSignerBsms(AddressType.p2wsh, "outside signer");
      String expectResult =
          "BSMS 1.0\n00\n[62A936C3/48'/0'/0'/2']Zpub75QytCyD9mNTr1wyi59JAhU2uiPedspk18djeteoeC6tJ7MdpuKbBRUA33CW49y5FDkpPqLDjujDVaNAGB9XVw44q8X2Hzif5DSTQyhgTES\noutside signer";

      expect(signer, expectResult);
    });

    test('bsms coordinator test', () {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);
      String expectedCoordinator =
          "BSMS 1.0\nwsh(sortedmulti(2,[AEF5B293/48'/0'/0'/2']Zpub75AQJSQLp25LUmJX2fUUMJjP4fcQhwaqH32iSNckTrZrjy3omBpb1ghSNtSZpCzvzhLha7r3JA7uG4wQyDkn87qHgpPZfTHBdvghvVhL2t1/<0;1>/*,[BAD41B33/48'/0'/0'/2']Zpub74NK7csp5wpD3dmr6bwweenNKDSERwQfisZCL8JpZ2TQ64E4oHm8pesNzTytfhfpfp6XzwumdxSKgLSjogTG6r6zVd1mSgGz67zK3Me9qrQ/<0;1>/*,[62A936C3/48'/0'/0'/2']Zpub75QytCyD9mNTr1wyi59JAhU2uiPedspk18djeteoeC6tJ7MdpuKbBRUA33CW49y5FDkpPqLDjujDVaNAGB9XVw44q8X2Hzif5DSTQyhgTES/<0;1>/*))#3zwl8rzh\n/0/*,/1/*\nbc1qq4t09zkp4f422qrcqmg0xx79h5n9ujtql5rcvwc0kykwfv3rwxgqkss9ct";
      expect(multisignatureVault.getCoordinatorBsms(), expectedCoordinator);
    });

    test('p2wsh address test', () {
      Address address = multisignatureVault.getAddressList(0, 1, false)[0];
      // print(address.address + " " + address.derivationPath);
      // print(multisignatureVault.derivationPath);
      String expectAddress =
          'bc1qq4t09zkp4f422qrcqmg0xx79h5n9ujtql5rcvwc0kykwfv3rwxgqkss9ct';
      expect(address.address, expectAddress);

      Address changeAddress = multisignatureVault.getAddressList(0, 1, true)[0];
      // print(address.address + " " + address.derivationPath);
      // print(multisignatureVault.derivationPath);
      String expectChangeAddress =
          'bc1qjy9t4rl9npfu5r47k9gqkk7znt8hyuf28vd6jx3wuheu2dhc0esq3085ck';
      expect(changeAddress.address, expectChangeAddress);
    });
  });

  group('Import Watch-only Wallet', () {
    late MultisignatureVault multisignatureVault;

    setUpAll(() {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);

      SingleSignatureVault insideVault1 = SingleSignatureVault.fromMnemonic(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          AddressType.p2wpkh,
          passphrase: 'ABC');

      SingleSignatureVault insideVault2 = SingleSignatureVault.fromMnemonic(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          AddressType.p2wpkh,
          passphrase: 'DEF');

      SingleSignatureVault outsideVault = SingleSignatureVault.fromMnemonic(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          AddressType.p2wpkh,
          passphrase: 'GHI');

      KeyStore insideKey1 =
          KeyStore.fromSeed(insideVault1.keyStore.seed, AddressType.p2wsh);
      KeyStore insideKey2 =
          KeyStore.fromSeed(insideVault2.keyStore.seed, AddressType.p2wsh);
      String signerBsms =
          outsideVault.getSignerBsms(AddressType.p2wsh, "outside signer");
      KeyStore outsideKey = KeyStore.fromSignerBsms(signerBsms);

      multisignatureVault = MultisignatureVault.fromKeyStoreList(
          [insideKey1, insideKey2, outsideKey], 2, AddressType.p2wsh);
    });
    test('descriptor import', () {
      MultisignatureWallet watchOnlyWallet =
          MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);

      print(watchOnlyWallet.getReceiveAddress());

      print(watchOnlyWallet.addressBook.getDerivationPath(
          "bc1qq4t09zkp4f422qrcqmg0xx79h5n9ujtql5rcvwc0kykwfv3rwxgqkss9ct"));

      for (KeyStore keyStore in watchOnlyWallet.keyStoreList) {
        print(keyStore.getPublicKeyWithDerivationPath("m/48'/0'/0'/2'/0/0"));
      }
      //0243e06ee8ac1c4bc931e9fedb36b5894d57df88ea3d754d9d70e889c6753b9180
      //02fc46321ca9cb7a884a15ac3ef4e61b043730c3e7a327e4cf8decae423309f4e6
      //03349e1dc9b10b42bddeed6f272df55f622259d3e318cb1cb520ed374c18d68771
    });
  });

  group('generate transaction test', () {
    test('parsing p2wsh psbt', () {
      String psbtText =
          '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';
      PSBT psbt = PSBT.parse(psbtText);
      Transaction tx = psbt.getSignedTransaction(AddressType.p2wsh);
    });

    test('parsing p2wsh transcation', () {
      String txText =
          '020000000001010352b32fb6e9405e7a1ccf3d3fcedd6139fa179e085093fdc96fbe66bb75281f0000000000ffffffff02e803000000000000220020b4cf7e9b2be791bb72a0a7f9b83c8c3a4f5166a2d41124181ab39e2a00691a6c663c0f00000000002200204ef6c79d9dc579ef93f19b3663558c3e7619aa0d06cf6590ca22362bf564191c04004730440220052909149c0f5118cbef28d5fa9db831c49635ac4b2a9e6f9b2cd5d8ce753d97022072608b452aa959e5787699df467134dfadc571f8fb6d8c33043c9956f63d9d0d01483045022100a99ea7fa25b493664455e66bfde160091adc7820f3a784ad901a70a0d9bd14a70220406cf63060ce7ffeaa7f524ba39c65c0ac90f9897e7bd4962c85feaf011f8b8c0169522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae00000000';
      Transaction tx = Transaction.parse(txText);
      expect(tx.inputs[0].witnessList[3],
          '522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae');
    });
  });
}
