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
- [network](https://github.com/noncelab/coconut_lib/blob/main/lib/src/network): Provide you with the code to communicate with a Bitcoin node. Feel free to send Bitcoins through the RegTest we provide.

> For more development information, visit the [coconut_lib docs](https://pub.dev/documentation/coconut_lib/latest/coconut_lib/coconut_lib-library.html).

## Example

```dart
import 'dart:io';
import 'package:coconut_lib/coconut_lib.dart';

void main() async {
  /*
  This shows the process from creating a Bitcoin wallet in the Coconut Library to sending Bitcoin.
  Please check that the roles of the Vault and the Wallet are separate.
  Enjoy Bitcoin programming with Coconut Library!
  */

  /// >> In Vault
  /// choose the Bitcoin Network
  // BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);
  // BitcoinNetwork.setNetwork(BitcoinNetwork.testnet);
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  /// generate air-gapped vault
  /// random vault
  // SingleSignatureVault randomMnemonicVault =
  //     SingleSignatureVault.random(AddressType.p2wpkh);
  // print("Generated Mnemonic : ${randomMnemonicVault.keyStore.seed.mnemonic}");

  /// mnemonic vault
  SingleSignatureVault mnemonicVault = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'ABC');

  // >> In Wallet
  /// import expub to watch-only wallet with descriptor(BIP-0380)
  SingleSignatureWallet watchOnlyWallet =
      SingleSignatureWallet.fromDescriptor(mnemonicVault.descriptor);

  /// Obtain the bitcoin from faucet
  print("address : ${watchOnlyWallet.getAddress(0)}");

  /// connect to the node and fetch transaction data
  Repository.initialize('Coconut_Tutorial'); // db for tx history
  NodeConnector nodeConnector = await NodeConnector.connectSync(
      'regtest-electrum.coconut.onl', 60401,
      ssl: true); // node connection
  var syncResult = await nodeConnector.fetch(watchOnlyWallet); // fetch tx data
  if (syncResult.isFailure) {
    throw Exception(" - Sync failed : ${syncResult.error}");
  } else {
    print(' - Transaction Sync Success');
    await Repository()
        .sync(watchOnlyWallet, syncResult.value!); // save tx data into db
  }

  /// and then, check the balance
  print("balance : ${watchOnlyWallet.getBalance()}");

  /// create a PSBT(BIP-0174) to my another address
  PSBT unsignedPSBT = PSBT.forSending(
      "bcrt1qyyl6eld8zq0zgh5jf8u5n3lv4jz9tjzeny2lq9", 1000, 3, watchOnlyWallet);

  /// >> In Vault
  /// vault can sign the PSBT
  String signedPsbt =
      mnemonicVault.addSignatureToPsbt(unsignedPSBT.serialize());

  /// >> In Wallet
  // watchOnlyWallet can broadcast the signed transaction
  PSBT signedPSBT =
      PSBT.parse(signedPsbt); // parse the PSBT received from vault
  Transaction completedTx = signedPSBT
      .getSignedTransaction(watchOnlyWallet.addressType); // transaction object
  Result result =
      await nodeConnector.broadcast(completedTx.serialize()); // broadcast
  print(' - Transaction is broadcasted: ${result.value}');

  /// need to sync again
  var finalSyncResult =
      await nodeConnector.fetch(watchOnlyWallet); // fetch tx data
  if (syncResult.isFailure) {
    throw Exception(" - Sync failed : ${finalSyncResult.error}");
  } else {
    print(' - Transaction Sync Success');
    await Repository()
        .sync(watchOnlyWallet, finalSyncResult.value!); // save tx data into db
  }

  /// check the balance again
  print("balance : ${watchOnlyWallet.getBalance()}");

  exit(0);
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
- [BIP-129](https://github.com/bitcoin/bips/blob/master/bip-0129.mediawiki): Bitcoin Secure Multisig Setup (BSMS)
- [BIP-142](https://github.com/bitcoin/bips/blob/master/bip-0142.mediawiki): Address Format for Segregated Witness
- [BIP-143](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki): Transaction Signature Verification for Version 0 Witness Program
- [BIP-173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki): Base32 address format for native v0-16 witness outputs
- [BIP-174](https://github.com/bitcoin/bips/blob/master/bip-0174.mediawiki): Partially Signed Bitcoin Transaction Format
- [BIP-370](https://github.com/bitcoin/bips/blob/master/bip-0370.mediawiki): PSBT Version 2
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
