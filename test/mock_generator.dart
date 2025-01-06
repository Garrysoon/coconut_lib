import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_lib/src/network/electrum/electrum_response_types.dart';

enum TestWalletType {
  /// Regtest, 트랜잭션과 UTXO가 수십개 포함된 싱글 시그 지갑
  forNormal,

  /// 랜덤 생성된 싱글 시그 지갑 (트랜잭션, UTXO 없음)
  random
}

SingleSignatureVault getMockSingleVault(TestWalletType type,
    {String passphrase = ''}) {
  SingleSignatureVault? vault;
  if (type == TestWalletType.forNormal) {
    vault = SingleSignatureVault.fromMnemonic(
        'machine crack daughter fish credit glare raven fever tunnel delay fish record',
        AddressType.p2wpkh,
        passphrase: passphrase);
  } else if (type == TestWalletType.random) {
    vault = SingleSignatureVault.random(AddressType.p2wpkh);
  }
  return vault!;
}

SingleSignatureWallet getMockSingleWallet(TestWalletType type) {
  SingleSignatureVault vault = getMockSingleVault(type);
  SingleSignatureWallet wallet =
      SingleSignatureWallet.fromDescriptor(vault.descriptor);
  return wallet;
}

Future<WalletStatus> getMockWalletStatus(TestWalletType type,
    {bool isMultisig = false}) async {
  WalletStatus? status;
  if (type == TestWalletType.forNormal) {
    File file = File(
        'test/mock_data/wallet_status_for_normal${isMultisig ? '_multisig' : ''}.json');
    status = WalletStatus.fromJson(await file.readAsString());
  } else if (type == TestWalletType.random) {
    status = WalletStatus(
      transactionList: [],
      utxoList: [],
      balance: Balance(0, 0),
      blockHeaderMap: {},
      receiveAddressBalanceMap: {},
      changeAddressBalanceMap: {},
      receiveUsedIndexList: [],
      changeUsedIndexList: [],
      receiveMaxGap: 0,
      changeMaxGap: 0,
    );
  }

  return status!;
}

MultisignatureVault getMockMultisignatureVault(TestWalletType type) {
  final vault1 = getMockSingleVault(type, passphrase: '1');
  final vault2 = getMockSingleVault(type, passphrase: '2');
  final vault3 = getMockSingleVault(type, passphrase: '3');

  KeyStore keyStore1 =
      KeyStore.fromSeed(vault1.keyStore.seed, AddressType.p2wsh);
  KeyStore keyStore2 =
      KeyStore.fromSeed(vault2.keyStore.seed, AddressType.p2wsh);
  KeyStore keyStore3 =
      KeyStore.fromSeed(vault3.keyStore.seed, AddressType.p2wsh);

  MultisignatureVault vault = MultisignatureVault.fromKeyStoreList(
      [keyStore1, keyStore2, keyStore3], 2, AddressType.p2wsh);

  return vault;
}

MultisignatureWallet getMockMultisignatureWallet(TestWalletType type) {
  MultisignatureVault vault = getMockMultisignatureVault(type);
  MultisignatureWallet wallet =
      MultisignatureWallet.fromDescriptor(vault.descriptor);

  return wallet;
}

Transaction getMockTransaction(String scriptPubKey, int amount) {
  var address = AddressType.p2wpkh.getAddress(scriptPubKey);

  return Transaction.withDefault(
      [], [TransactionOutput.forPayment(amount, address)], AddressType.p2wpkh);
}

BlockHeaderSubscribe getMockBlockHeaderSubscribe({int height = 1000}) {
  // TODO: height 에 따라 다른 블록 헤더 생성
  return BlockHeaderSubscribe(
      height: height,
      hex:
          '000000202a25b55e70596e07b52b0fba74fbe464e2e6677deb1cd8bd47670a7b6e8b027be601172e5dc38d15db848dcc66f5c75369765ea86d9c2f03dbbc35b46c218e6eec699d66ffff7f2001000000');
}
