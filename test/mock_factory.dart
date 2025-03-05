import 'dart:math';

import 'package:coconut_lib/coconut_lib.dart';

enum TestWalletType {
  /// Regtest, 트랜잭션과 UTXO가 수십개 포함된 싱글 시그 지갑
  forNormal,

  /// 랜덤 생성된 싱글 시그 지갑 (트랜잭션, UTXO 없음)
  random
}

abstract class MockFactory {
  static SingleSignatureVault createP2wpkhVault(
      {TestWalletType testWalletType = TestWalletType.forNormal,
      String passphrase = ''}) {
    SingleSignatureVault? vault;
    if (testWalletType == TestWalletType.forNormal) {
      vault = SingleSignatureVault.fromMnemonic(
          'machine crack daughter fish credit glare raven fever tunnel delay fish record',
          passphrase: passphrase);
    } else if (testWalletType == TestWalletType.random) {
      vault = SingleSignatureVault.random();
    }
    return vault!;
  }

  static SingleSignatureVault createP2trKeyPathSpendingVault(
      {TestWalletType testWalletType = TestWalletType.forNormal,
      String passphrase = ''}) {
    SingleSignatureVault? vault;
    if (testWalletType == TestWalletType.forNormal) {
      vault = SingleSignatureVault.fromMnemonic(
          'machine crack daughter fish credit glare raven fever tunnel delay fish record',
          addressType: AddressType.p2trKeyPathSpending,
          passphrase: passphrase);
    } else if (testWalletType == TestWalletType.random) {
      vault = SingleSignatureVault.random();
    }
    return vault!;
  }

  static MultisignatureVault createP2wshVault(
      {TestWalletType testWalletType = TestWalletType.forNormal}) {
    final vault1 =
        createP2wpkhVault(testWalletType: testWalletType, passphrase: 'A');
    final vault2 =
        createP2wpkhVault(testWalletType: testWalletType, passphrase: 'B');
    final vault3 =
        createP2wpkhVault(testWalletType: testWalletType, passphrase: 'C');

    KeyStore keyStore1 =
        KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2wsh);
    KeyStore keyStore2 =
        KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2wsh);
    KeyStore keyStore3 =
        KeyStore.fromSeed(vault3.keyStore.seed, AddressType.p2wsh);

    MultisignatureVault vault = MultisignatureVault.fromKeyStoreList(
        [keyStore1, keyStore2, keyStore3], 2);

    return vault;
  }

  static Utxo createUtxo(
      {int amount = 100000,
      String derivationPath = "m/84'/1'/0'/0/0",
      String entropy = ''}) {
    if (entropy.isEmpty) {
      entropy = "FakeTransactionHash${Random().nextInt(100000)}";
    }
    String fakeTransactionHash = Hash.sha256(entropy);
    return Utxo(fakeTransactionHash, 0, amount, derivationPath);
  }

  static List<Utxo> createUtxoList(
      {int count = 10, String derivationPath = "m/84'/1'/0'/0/0"}) {
    List<Utxo> utxos = [];
    for (int i = 0; i < count; i++) {
      utxos.add(createUtxo(
          entropy: "utxo #${i.toString()}", derivationPath: derivationPath));
    }
    return utxos;
  }

  static Psbt createP2wpkhUnsignedPsbt() {
    SingleSignatureVault vault = createP2wpkhVault();
    Transaction tx = Transaction.forSinglePayment(
        createUtxoList(count: 1),
        vault.getAddress(1),
        vault.getAddress(1, isChange: true),
        15000,
        3,
        vault);
    return Psbt.fromTransaction(tx, vault);
  }

  static Psbt createP2wshUnsignedPsbt() {
    MultisignatureVault vault = createP2wshVault();
    Transaction tx = Transaction.forSinglePayment(
        createUtxoList(count: 2, derivationPath: "m/48'/1'/0'/2'/0/0"),
        vault.getAddress(1),
        vault.getAddress(1, isChange: true),
        15000,
        3,
        vault);
    return Psbt.fromTransaction(tx, vault);
  }

  static Psbt createP2wshSignedPsbt() {
    MultisignatureVault vault = createP2wshVault();
    Transaction tx = Transaction.forSinglePayment(
        createUtxoList(count: 2, derivationPath: "m/48'/1'/0'/2'/0/0"),
        vault.getAddress(1),
        vault.getAddress(1, isChange: true),
        15000,
        3,
        vault);
    Psbt unsignedPsbt = Psbt.fromTransaction(tx, vault);

    return Psbt.parse(vault.addSignatureToPsbt(unsignedPsbt.serialize()));
  }

  static Psbt createP2wpkhSignedPsbt() {
    SingleSignatureVault vault = createP2wpkhVault();
    Transaction tx = Transaction.forSinglePayment(
        createUtxoList(count: 1),
        vault.getAddress(1),
        vault.getAddress(1, isChange: true),
        15000,
        3,
        vault);
    Psbt unsignedPsbt = Psbt.fromTransaction(tx, vault);

    return Psbt.parse(vault.addSignatureToPsbt(unsignedPsbt.serialize()));
  }

  Transaction getMockTransaction(String scriptPubKey, int amount,
      {bool isCoinbase = false, AddressType? addressType}) {
    addressType ??= AddressType.p2wpkh;

    late String address;
    if (addressType == AddressType.p2wpkh) {
      address = addressType.getAddress(scriptPubKey);
    } else if (addressType == AddressType.p2wsh) {
      address = addressType.getMultisignatureAddress([scriptPubKey], 1);
    }

    List<TransactionInput> inputs = [];

    if (isCoinbase) {
      inputs.add(TransactionInput.forPayment(
          '0000000000000000000000000000000000000000000000000000000000000000',
          4294967295));
    } else {
      inputs.add(
          TransactionInput.forPayment(Hash.sha256('$scriptPubKey$amount'), 0));
    }

    List<TransactionOutput> outputs = [
      TransactionOutput.forPayment(amount, address),
    ];

    return Transaction.withInputsAndOutputs(inputs, outputs, addressType);
  }
}
