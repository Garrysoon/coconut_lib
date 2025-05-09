# Coconut_lib

The Coconut_lib is a development tool for mobile air gap Bitcoin wallets. It is written in [`Dart`](https://dart.dev/).
Coconut Vault and Coconut Wallet were created using this library.
Download from Appstore and Play Store.

- [Coconut Vault (for iOS)](https://apps.apple.com/us/app/6651839033)
- [Coconut Wallet (for iOS)](https://apps.apple.com/us/app/6654902298)
- [Coconut Vault (for Android)](https://play.google.com/store/apps/details?id=onl.coconut.vault.regtest)
- [Coconut Wallet (for Android)](https://play.google.com/store/apps/details?id=onl.coconut.wallet.regtest)

And visit tutorial page for Self-custody we provided. (www.coconut.onl)

> ⚠ The Coconut_lib is still a project under development.
> Therefore, we are not responsible for any problems that may arise while using it.
> Please review it carefully and use it.

## About

The Coconut_lib provides the base code for developing Bitcoin vaults and wallets based on Bitcoin airgap.
Since coconut_lib is developed in [`Dart`](https://dart.dev/), it is specialized for developing applications for iPhone and Android by utilizing the [`Flutter`](https://flutter.dev/).
In particular, The Coconut_lib designed to develop air-gap-based vault and wallet apps separately by clearly distinguishing the vault area and wallet area.
You can use the Coconut_lib to create your own air-gap based vault and wallet.

"Don't trust, verify and develop!"

## Architecture

- [wallet](https://github.com/noncelab/coconut_lib/blob/main/lib/src/wallet): Provides a cryptography-based key management method. Create two apps instancing the Wallet and Vault classes.
  ![image](doc/design/wallet_class_diagram.jpg)
- [transaction](https://github.com/noncelab/coconut_lib/blob/main/lib/src/transaction): Provides code related to Bitcoin scripts and transactions. Also use PSBT(BIP-0174) to communicate vaults and wallets.
  ![image](doc/design/transaction_class_diagram.jpg)

> For more development information, visit the [coconut_lib docs](https://pub.dev/documentation/coconut_lib/latest/coconut_lib/coconut_lib-library.html).

## Example

```dart
import 'package:coconut_lib/coconut_lib.dart';

import '../../test/mock_factory.dart';

void main() async {
  print("0. Set the Bitcoin Network");
  NetworkType.setNetworkType(NetworkType.regtest);

  print("1-1. Create a single signature vault");
  Seed seed = Seed.fromMnemonic(
      'thank split shrimp error own spirit slow glow act evidence globe slight');

  SingleSignatureVault singleSignatureVault =
      SingleSignatureVault.fromSeed(seed);
  print(
      ' - Master Fingerprint: ${singleSignatureVault.keyStore.masterFingerprint}');

  print("1-2. Create a 2-of-3 Multisignature vault");
  SingleSignatureVault insideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      passphrase: 'ABC');

  SingleSignatureVault outsideVault1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      passphrase: 'DEF');

  SingleSignatureVault outsideVault2 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      passphrase: 'GHI');

  //Generate P2WSH Keystore
  KeyStore insideKey1 =
      KeyStore.fromSeed(insideVault1.keyStore.seed, AddressType.p2wsh);
  KeyStore outsideKey1 = KeyStore.fromSignerBsms(
      outsideVault1.getSignerBsms(AddressType.p2wsh, "OutsideSigner1"));
  KeyStore outsideKey2 = KeyStore.fromSignerBsms(
      outsideVault2.getSignerBsms(AddressType.p2wsh, "OutsideSigner2"));

  MultisignatureVault multisignatureVault =
      MultisignatureVault.fromKeyStoreList(
          [insideKey1, outsideKey1, outsideKey2], 2);

  // Share Coordinator BSMS with Outside Signers
  MultisignatureVault outsideMultisignatureVault =
      MultisignatureVault.fromCoordinatorBsms(
          multisignatureVault.getCoordinatorBsms());

  // Find Seed in Outside Vault and bind it to KeyStore
  outsideMultisignatureVault.bindSeedToKeyStore(outsideVault1.keyStore.seed);

  print(
      ' - Master Fingerprint of Key Store [0]: ${multisignatureVault.keyStoreList[0].masterFingerprint}');
  print(
      ' - Master Fingerprint of Key Store [1]: ${multisignatureVault.keyStoreList[1].masterFingerprint}');
  print(
      ' - Master Fingerprint of Key Store [2]: ${multisignatureVault.keyStoreList[2].masterFingerprint}');

  print("2-1. Sync to the single signature wallet");
  // Repository.initialize('Coconut_Wallet');
  SingleSignatureWallet singleSignatureWallet =
      SingleSignatureWallet.fromDescriptor(singleSignatureVault.descriptor);
  print(
      ' - Extended Public Key: ${singleSignatureWallet.keyStore.extendedPublicKey.serialize()}');

  print("2-2. Sync to the multisignature wallet");
  MultisignatureWallet multisignatureWallet;

  Descriptor descriptor = Descriptor.parse(multisignatureVault.descriptor);
  if (descriptor.scriptType == 'wsh') {
    multisignatureWallet =
        MultisignatureWallet.fromDescriptor(multisignatureVault.descriptor);
    // } else if (descriptor.scriptType == 'wpkh') {
    //   watchOnlyWallet =
    //       SingleSignatureWallet.fromDescriptor(multisignatureVault.descriptor);
  } else {
    throw Exception('Unsupported Address Type');
  }
  print(
      ' - Extended Public Key of Key Store [0]: ${multisignatureWallet.keyStoreList[0].extendedPublicKey.serialize()}');
  print(
      ' - Extended Public Key of Key Store [1]: ${multisignatureWallet.keyStoreList[1].extendedPublicKey.serialize()}');
  print(
      ' - Extended Public Key of Key Store [2]: ${multisignatureWallet.keyStoreList[2].extendedPublicKey.serialize()}');

  print(
      "4. Send Bitcoin from the single signature wallet to the multisignature wallet");
  String receiverAddress = multisignatureWallet.getAddress(0);
  String changeAddress = singleSignatureWallet.getAddress(0, isChange: true);
  int sendingAmount = 1000;
  double feeRate = 3.0;
  List<Utxo> utxosForSingleSignatureWallet = [
    Utxo('5c5fa04bc94647ee339083d6fd381a3b1ac4de7d7bfa966788971d62072a1e66', 1,
        100000000, "m/84'/1'/0'/0/68")
  ];
  print(' - Generating unsigned PSBT');
  List<Utxo> utxoList = [
    Utxo('393a2d56f910019a6df975672989a449648f355b1fb7889fb831f0402c5550f3', 0,
        21000, "m/84'/1'/0'/0/0")
  ];
  Transaction unsignedTransaction = Transaction.forSinglePayment(utxoList,
      receiverAddress, "m/84'/1'/0'/1/0", 2000, 2, singleSignatureWallet);
  String unsignedPsbt =
      Psbt.fromTransaction(unsignedTransaction, singleSignatureWallet)
          .serialize();

  print(' - Add signature from vault');
  String signedPsbt = singleSignatureVault.addSignatureToPsbt(unsignedPsbt);
  Psbt walletReceivedPsbt = Psbt.parse(signedPsbt);
  Transaction signedTransaction = walletReceivedPsbt
      .getSignedTransaction(singleSignatureWallet.addressType);
  print(' - Final Transaction : ${signedTransaction.serialize()}');
}
```

## Tests

### Generate Mock Classes

```sh
dart pub run build_runner build
```

### Unit Test

```sh
dart test -t unit
```

### E2E Test

```sh
dart test -t e2e
```

### Coverage

The following tools are required to generate test coverage (for MacOS):

```sh
dart pub global activate coverage

brew install lcov
```

To generate test coverage, run the following command:

```sh
sh ./generate_unit_coverage.sh
```

## Bip Support List

- [BIP-11](https://github.com/bitcoin/bips/blob/master/bip-0011.mediawiki): M-of-N Standard Transactions
- [BIP-32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki): Hierarchical Deterministic Wallets
- [BIP-39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki): Mnemonic code for generating deterministic keys
- [BIP-44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki): Multi-Account Hierarchy for Deterministic Wallets
- [BIP-48](https://github.com/bitcoin/bips/blob/master/bip-0048.mediawiki): Multi-Script Hierarchy for Multi-Sig Wallets
- [BIP-67](https://github.com/bitcoin/bips/blob/master/bip-0067.mediawiki): Deterministic Multisig Key Sorting
- [BIP-84](https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki): Derivation scheme for P2WPKH based accounts
- [BIP-86](https://github.com/bitcoin/bips/blob/master/bip-0086.mediawiki): Key Derivation for Single Key P2TR Outputs
- [BIP-129](https://github.com/bitcoin/bips/blob/master/bip-0129.mediawiki): Bitcoin Secure Multisig Setup (BSMS)
- [BIP-142](https://github.com/bitcoin/bips/blob/master/bip-0142.mediawiki): Address Format for Segregated Witness
- [BIP-143](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki): Transaction Signature Verification for Version 0 Witness Program
- [BIP-173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki): Base32 address format for native v0-16 witness outputs
- [BIP-174](https://github.com/bitcoin/bips/blob/master/bip-0174.mediawiki): Partially Signed Bitcoin Transaction Format
- [BIP-327](https://github.com/bitcoin/bips/blob/master/bip-0327.mediawiki): MuSig2 for BIP340-compatible Multi-Signatures
- [BIP-340](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki): Schnorr Signatures for secp256k1
- [BIP-341](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki): SegWit version 1 spending rules
- [BIP-370](https://github.com/bitcoin/bips/blob/master/bip-0370.mediawiki): PSBT Version 2
- [BIP-371](https://github.com/bitcoin/bips/blob/master/bip-0371.mediawiki): Taproot Fields for PSBT
- [BIP-380](https://github.com/bitcoin/bips/blob/master/bip-0380.mediawiki): Output Script Descriptors General Operation
- [BIP-381](https://github.com/bitcoin/bips/blob/master/bip-0381.mediawiki): Non-Segwit Output Script Descriptors
- [BIP-382](https://github.com/bitcoin/bips/blob/master/bip-0382.mediawiki): Segwit Output Script Descriptors
- [BIP-383](https://github.com/bitcoin/bips/blob/master/bip-0383.mediawiki): Multisig Output Script Descriptors

## Contribution

Reference [CONTRIBUTING](https://github.com/noncelab/coconut_lib/blob/main/.github/CONTRIBUTING.md)

## Bug report and Contact us

- Github Issue, PR
- [hello@noncelab.com](mailto:hello@noncelab.com)
- coconut.onl

## License

Reference [LICENSE](https://github.com/noncelab/coconut_lib/blob/main/LICENSE)
