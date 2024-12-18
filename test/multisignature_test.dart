@Tags(['integration'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/utils/converter.dart';
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

      // print(insideKey1.masterFingerprint);
      // print(insideKey2.masterFingerprint);
      // print(outsideKey.masterFingerprint);

      multisignatureVault = MultisignatureVault.fromKeyStoreList(
          [insideKey1, insideKey2, outsideKey], 2, AddressType.p2wsh);

      // for (KeyStore keyStore in multisignatureVault.keyStoreList) {
      //   print(keyStore.masterFingerprint);
      // }

      // print(multisignatureVault.descriptor);
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
      // print(multisignatureVault.getCoordinatorBsms());
      MultisignatureVault vault = MultisignatureVault.fromCoordinatorBsms(
          multisignatureVault.getCoordinatorBsms());
      expect(vault.keyStoreList[0].masterFingerprint,
          multisignatureVault.keyStoreList[0].masterFingerprint);
      expect(vault.keyStoreList[1].masterFingerprint,
          multisignatureVault.keyStoreList[1].masterFingerprint);
      expect(vault.keyStoreList[2].masterFingerprint,
          multisignatureVault.keyStoreList[2].masterFingerprint);
    });

    test('p2wsh address test', () {
      Address address = multisignatureVault.getAddressList(0, 1, false)[0];

      String expectAddress =
          'bc1qq4t09zkp4f422qrcqmg0xx79h5n9ujtql5rcvwc0kykwfv3rwxgqkss9ct';
      expect(address.address, expectAddress);

      Address changeAddress = multisignatureVault.getAddressList(0, 1, true)[0];
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

      String target =
          '03349e1dc9b10b42bddeed6f272df55f622259d3e318cb1cb520ed374c18d68771';
      expect(
          watchOnlyWallet.keyStoreList[2]
              .getPublicKeyWithDerivationPath("m/48'/0'/0'/2'/0/0"),
          target);
    });
  });

  group('generate transaction test', () {
    test('parsing p2wsh psbt', () {
      String psbtText =
          'cHNidP8BAH0CAAAAAdxQWy5b0fLi67CqwPaZJz+Bl17oJkIZBrf7PTAh+JzkAAAAAAD/////AqAPAAAAAAAAFgAUlioXqG/x1MpFWpRnLOeYzD5PBmPusckBAAAAACIAIDuDrSYPbHWsQ9OeDaat1p5BTYIdI6zGvOQpL/uC/AYOAAAAAAABAOoCAAAAAAEBaA1G4sLKcjse+QjcTWYKoeE6rxlxISFtfqDr3/E8aeoBAAAAAP////8CgMPJAQAAAAAiACC0z36bK+eRu3Kgp/m4PIw6T1FmotQRJBgas54qAGkabH6fkgMAAAAAFgAU5kZwJXJsdVyQqE+hHg86jurt6CgCRzBEAiBlFZFcgnMmbMK5IFpzCj/Bm0pVB86bQt1OkMnZKZamYAIgSwxSM1/msrZLFGDWVVPWw5439GYKK31X9wz34sNOo8kBIQPCond2MmhddvawSMYUd/kRF3AsPuq6at0z6Acm0f7pHAAAAAABASuAw8kBAAAAACIAILTPfpsr55G7cqCn+bg8jDpPUWai1BEkGBqznioAaRpsIgYC5jlBml55ag+2rsLFoKXXRBbqQFwn7Szu1IEht67e+lYcrvWykzAAAIABAACAAAAAgAIAAIAAAAAAAAAAACIGAy6I7zD1MWzw73U4lCh/AVcCUK27Yt5QIDXgznx6gC/aHLrUGzMwAACAAQAAgAAAAIACAACAAAAAAAAAAAAiBgPUZBeqQc4Wta0N3HFE9LOs8Sy0rQsgx13BdBA5T5eVBBxiqTbDMAAAgAEAAIAAAACAAgAAgAAAAAAAAAAAAQVpUiEC5jlBml55ag+2rsLFoKXXRBbqQFwn7Szu1IEht67e+lYhAy6I7zD1MWzw73U4lCh/AVcCUK27Yt5QIDXgznx6gC/aIQPUZBeqQc4Wta0N3HFE9LOs8Sy0rQsgx13BdBA5T5eVBFOuIgIC5jlBml55ag+2rsLFoKXXRBbqQFwn7Szu1IEht67e+lZHMEQCIChGhpy/t36QC+Jmsm3R5rn9Ha7GXZ5pnQtLtkGoYnDdAiABaynzlzC4H4I8ZKCf3qRlMi+uG/cXzMZTGrJSTIIEsgEiAgMuiO8w9TFs8O91OJQofwFXAlCtu2LeUCA14M58eoAv2kgwRQIhAJE3gBsUtQiaErwqoa+9wE3TZu2EbY4EJ0Cd6VybQ+lWAiAa+5b/njd+s8dCfJyhuz2Q3ejjEbQYyP2cH/iheqsOqAEAAQMEoA8AAAEEFxYAFJYqF6hv8dTKRVqUZyznmMw+TwZjAAEDBO6xyQEBBCMiACA7g60mD2x1rEPTng2mrdaeQU2CHSOsxrzkKS/7gvwGDiICAn8u6cowPfhFODSD8uROhx5/X6uL2VUEjCUTi1wFsl6ZHK71spMwAACAAQAAgAAAAIACAACAAQAAAAEAAAAiAgLeA01FD/Czt+GY+483ZukHLclOy+hbaN0ot1Vwg8L7Ixy61BszMAAAgAEAAIAAAACAAgAAgAEAAAABAAAAIgICxEQltOLyh0Khlo5lmK6avPlnQSCt+fohJF7f4anSxl0cYqk2wzAAAIABAACAAAAAgAIAAIABAAAAAQAAAAAA';
      PSBT psbt = PSBT.parse(psbtText);
      String targetScript =
          '69522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae';
      expect(psbt.inputs[0].witnessScript!.serialize(), targetScript);
    });

    test('parsing p2wsh transcation', () {
      String txText =
          '020000000001010352b32fb6e9405e7a1ccf3d3fcedd6139fa179e085093fdc96fbe66bb75281f0000000000ffffffff02e803000000000000220020b4cf7e9b2be791bb72a0a7f9b83c8c3a4f5166a2d41124181ab39e2a00691a6c663c0f00000000002200204ef6c79d9dc579ef93f19b3663558c3e7619aa0d06cf6590ca22362bf564191c04004730440220052909149c0f5118cbef28d5fa9db831c49635ac4b2a9e6f9b2cd5d8ce753d97022072608b452aa959e5787699df467134dfadc571f8fb6d8c33043c9956f63d9d0d01483045022100a99ea7fa25b493664455e66bfde160091adc7820f3a784ad901a70a0d9bd14a70220406cf63060ce7ffeaa7f524ba39c65c0ac90f9897e7bd4962c85feaf011f8b8c0169522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae00000000';
      Transaction tx = Transaction.parse(txText);
      expect(tx.inputs[0].witnessList[3],
          '522102e639419a5e796a0fb6aec2c5a0a5d74416ea405c27ed2ceed48121b7aedefa5621032e88ef30f5316cf0ef753894287f01570250adbb62de502035e0ce7c7a802fda2103d46417aa41ce16b5ad0ddc7144f4b3acf12cb4ad0b20c75dc17410394f97950453ae');
    });

    test('witness script validator', () {
      String badPublicKeyOrder =
          '0653210378eee0245a53a7adcd2cfefc4bf5d13ee1a70c4ca5d4df1c9b1bccafed26e5fa2103b0f61d342e1c217e6d40a1d7b95a2ded2b14f4b4a2c9f4a381e3e5837eba629b2102868fd6ae25b2fe30a5020418e0b5e8f31c5a63b50a6907c9dba50001cbcc6aa353ae';
      expect(
          () => WitnessScript.parse(
              "${Converter.decToHex((badPublicKeyOrder.length / 2).ceil())}$badPublicKeyOrder"),
          throwsException);

      String noMultisigOperation =
          '53210378eee0245a53a7adcd2cfefc4bf5d13ee1a70c4ca5d4df1c9b1bccafed26e5fa2103b0f61d342e1c217e6d40a1d7b95a2ded2b14f4b4a2c9f4a381e3e5837eba629b2102868fd6ae25b2fe30a5020418e0b5e8f31c5a63b50a6907c9dba50001cbcc6aa353';
      expect(
          () => WitnessScript.parse(
              "${Converter.decToHex((noMultisigOperation.length / 2).ceil())}$noMultisigOperation"),
          throwsException);

      String wrongSignatureLength =
          '53210378eee0245a53a7adcd2cfefc4bf5d13ee1a70c4ca5d4df1c9b1bccafed26e5fa2103b0f61d342e1c217e6d40a1d7b95a2ded2b14f4b4a2c9f4a381e3e5837eba629b200286d6ae25b2fe30a5020418e0b5e8f31c5a63b50a6907c9dba50001cbcc6aa353ae';
      expect(
          () => WitnessScript.parse(
              "${Converter.decToHex((wrongSignatureLength.length / 2).ceil())}$wrongSignatureLength"),
          throwsException);

      String clean =
          '532102868fd6ae25b2fe30a5020418e0b5e8f31c5a63b50a6907c9dba50001cbcc6aa3210378eee0245a53a7adcd2cfefc4bf5d13ee1a70c4ca5d4df1c9b1bccafed26e5fa2103b0f61d342e1c217e6d40a1d7b95a2ded2b14f4b4a2c9f4a381e3e5837eba629b53ae';
      // Converter.decToHex((clean.length / 2).ceil());
      expect(
          () => WitnessScript.parse(
              "${Converter.decToHex((clean.length / 2).ceil())}$clean"),
          returnsNormally);
    });
  });

  group('psbt test', () {
    late SingleSignatureVault insideVault1;
    late SingleSignatureVault insideVault2;
    late SingleSignatureVault outsideVault;
    late MultisignatureVault multisignatureVault;
    late MultisignatureWallet wallet;
    late MultisignatureVault outsideMultisignatureVault;

    setUpAll(() async {
      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

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

      outsideMultisignatureVault = MultisignatureVault.fromCoordinatorBsms(
          multisignatureVault.getCoordinatorBsms());
      outsideMultisignatureVault.bindSeedToKeyStore(outsideVault.keyStore.seed);

      wallet =
          MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);
      // print(wallet.getAddress(0));
      NodeConnector nodeConnector = await NodeConnector.connectSync(
          'regtest-electrum.coconut.onl', 60401,
          ssl: true);

      /// fetch on chain data
      await wallet.fetchOnChainData(nodeConnector);

      if (wallet.getBalance() < 10000) {
        throw Exception('Insufficient balance to test');
      }
    });

    test('psbt sign flag test', () async {
      Transaction tx = Transaction.forPayment(
          "bcrt1q3e20um9mrcwpl34agd07v0t76hg48n97ufjwe20mku7n5nqll32sxawr52",
          1000,
          1,
          wallet);
      PSBT unsignedPSBT = PSBT.fromTransaction(tx, wallet);

      expect(unsignedPSBT.isSigned(multisignatureVault.keyStoreList[0]), false);
      expect(unsignedPSBT.isSigned(multisignatureVault.keyStoreList[1]), false);
      expect(unsignedPSBT.isSigned(multisignatureVault.keyStoreList[2]), false);

      String signed0 = multisignatureVault.keyStoreList[0]
          .addSignatureToPsbt(unsignedPSBT.serialize());

      PSBT signed0Psbt = PSBT.parse(signed0);

      expect(signed0Psbt.isSigned(multisignatureVault.keyStoreList[0]), true);
      expect(signed0Psbt.isSigned(multisignatureVault.keyStoreList[1]), false);
      expect(signed0Psbt.isSigned(multisignatureVault.keyStoreList[2]), false);

      String signed1 = multisignatureVault.keyStoreList[1]
          .addSignatureToPsbt(unsignedPSBT.serialize());
      PSBT signed1Psbt = PSBT.parse(signed1);

      expect(signed1Psbt.isSigned(multisignatureVault.keyStoreList[0]), false);
      expect(signed1Psbt.isSigned(multisignatureVault.keyStoreList[1]), true);
      expect(signed1Psbt.isSigned(multisignatureVault.keyStoreList[2]), false);

      String signed02 = outsideMultisignatureVault.addSignatureToPsbt(signed0);
      PSBT signed02Psbt = PSBT.parse(signed02);

      expect(signed02Psbt.isSigned(multisignatureVault.keyStoreList[0]), true);
      expect(signed02Psbt.isSigned(multisignatureVault.keyStoreList[1]), false);
      expect(signed02Psbt.isSigned(multisignatureVault.keyStoreList[2]), true);

      KeyStore notImportedKeyStore = KeyStore.random(AddressType.p2wsh);
      expect(signed02Psbt.isSigned(notImportedKeyStore), false);
    });

    test('signature sorting test', () {
      Transaction tx = Transaction.forPayment(
          "bcrt1q3e20um9mrcwpl34agd07v0t76hg48n97ufjwe20mku7n5nqll32sxawr52",
          1000,
          1,
          wallet);
      PSBT unsignedPSBT = PSBT.fromTransaction(tx, wallet);

      String signed0 = multisignatureVault.keyStoreList[0]
          .addSignatureToPsbt(unsignedPSBT.serialize());
      String signed1 = multisignatureVault.keyStoreList[1]
          .addSignatureToPsbt(unsignedPSBT.serialize());

      PSBT signed0Psbt = PSBT.parse(signed0);
      PSBT signed1Psbt = PSBT.parse(signed1);

      String signed01 = multisignatureVault.keyStoreList[1]
          .addSignatureToPsbt(signed0Psbt.serialize());

      String signed10 = multisignatureVault.keyStoreList[0]
          .addSignatureToPsbt(signed1Psbt.serialize());

      // print(signed10);

      PSBT signed01Psbt = PSBT.parse(signed01);
      PSBT signed10Psbt = PSBT.parse(signed10);

      Transaction signed01Tx =
          signed01Psbt.getSignedTransaction(wallet.addressType);
      Transaction signed10Tx =
          signed10Psbt.getSignedTransaction(wallet.addressType);

      expect(signed01Tx.inputs[0].witnessList[1],
          signed10Tx.inputs[0].witnessList[1]);

      expect(signed01Tx.inputs[0].witnessList[2],
          signed10Tx.inputs[0].witnessList[2]);
    });
  });
}
