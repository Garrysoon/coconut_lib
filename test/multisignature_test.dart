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
          outsideVault.getBsmsForSigner(AddressType.p2wsh, "outside signer");
      KeyStore outsideKey = KeyStore.fromBsmsSigner(signerBsms);

      multisignatureVault = MultisignatureVault.fromKeyStoreList(
          [insideKey1, insideKey2, outsideKey], 2, AddressType.p2wsh);
    });

    test('bsms signer test', () {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);

      String signer =
          outsideVault.getBsmsForSigner(AddressType.p2wsh, "outside signer");
      String expectResult =
          "BSMS 1.0\n00\n[62A936C3/48'/0'/0'/2']Zpub75QytCyD9mNTr1wyi59JAhU2uiPedspk18djeteoeC6tJ7MdpuKbBRUA33CW49y5FDkpPqLDjujDVaNAGB9XVw44q8X2Hzif5DSTQyhgTES\noutside signer";

      expect(signer, expectResult);
    });

    test('bsms coordinator test', () {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);
      String expectedCoordinator =
          "BSMS 1.0\nwsh(sortedmulti(2,[AEF5B293/48'/0'/0'/2']Zpub75AQJSQLp25LUmJX2fUUMJjP4fcQhwaqH32iSNckTrZrjy3omBpb1ghSNtSZpCzvzhLha7r3JA7uG4wQyDkn87qHgpPZfTHBdvghvVhL2t1/<0;1>/*,[BAD41B33/48'/0'/0'/2']Zpub74NK7csp5wpD3dmr6bwweenNKDSERwQfisZCL8JpZ2TQ64E4oHm8pesNzTytfhfpfp6XzwumdxSKgLSjogTG6r6zVd1mSgGz67zK3Me9qrQ/<0;1>/*,[62A936C3/48'/0'/0'/2']Zpub75QytCyD9mNTr1wyi59JAhU2uiPedspk18djeteoeC6tJ7MdpuKbBRUA33CW49y5FDkpPqLDjujDVaNAGB9XVw44q8X2Hzif5DSTQyhgTES/<0;1>/*))#3zwl8rzh\n/0/*,/1/*\nbc1qq4t09zkp4f422qrcqmg0xx79h5n9ujtql5rcvwc0kykwfv3rwxgqkss9ct";
      expect(multisignatureVault.getBsmsForCoordinator(), expectedCoordinator);
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
          outsideVault.getBsmsForSigner(AddressType.p2wsh, "outside signer");
      KeyStore outsideKey = KeyStore.fromBsmsSigner(signerBsms);

      multisignatureVault = MultisignatureVault.fromKeyStoreList(
          [insideKey1, insideKey2, outsideKey], 2, AddressType.p2wsh);
    });
    test('descriptor import', () {
      MultisignatureWallet watchOnlyWallet =
          MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);

      String address = watchOnlyWallet.getAddress(0);
      expect(address,
          'bc1qq4t09zkp4f422qrcqmg0xx79h5n9ujtql5rcvwc0kykwfv3rwxgqkss9ct');
    });
  });

  group('generate psbt', () {
    MultisignatureWallet wallet;
    setUpAll(() {
      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

      wallet = MultisignatureWallet.fromDescriptor(
          "wsh(sortedmulti(2,[AEF5B293/48'/0'/0'/2']Zpub75AQJSQLp25LUmJX2fUUMJjP4fcQhwaqH32iSNckTrZrjy3omBpb1ghSNtSZpCzvzhLha7r3JA7uG4wQyDkn87qHgpPZfTHBdvghvVhL2t1/<0;1>/*,[BAD41B33/48'/0'/0'/2']Zpub74NK7csp5wpD3dmr6bwweenNKDSERwQfisZCL8JpZ2TQ64E4oHm8pesNzTytfhfpfp6XzwumdxSKgLSjogTG6r6zVd1mSgGz67zK3Me9qrQ/<0;1>/*,[62A936C3/48'/0'/0'/2']Zpub75QytCyD9mNTr1wyi59JAhU2uiPedspk18djeteoeC6tJ7MdpuKbBRUA33CW49y5FDkpPqLDjujDVaNAGB9XVw44q8X2Hzif5DSTQyhgTES/<0;1>/*))#3zwl8rzh");
    });

    group('fee estimation', () {});
  });
}
