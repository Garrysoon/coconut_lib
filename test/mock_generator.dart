import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';

enum TestWalletType {
  /// Regtest, 트랜잭션과 UTXO가 수십개 포함된 싱글 시그 지갑
  forNormal,

  /// 랜덤 생성된 싱글 시그 지갑 (트랜잭션, UTXO 없음)
  random
}

SingleSignatureVault getMockSingleVault(TestWalletType type) {
  SingleSignatureVault? vault;
  if (type == TestWalletType.forNormal) {
    vault = SingleSignatureVault.fromMnemonic(
        'machine crack daughter fish credit glare raven fever tunnel delay fish record',
        AddressType.p2wpkh);
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

Future<WalletStatus> getMockWalletStatus(TestWalletType type) async {
  WalletStatus? status;
  if (type == TestWalletType.forNormal) {
    File file = File('test/mock_data/wallet_status_for_normal.json');
    status = WalletStatus.fromJson(await file.readAsString());
  }

  return status!;
}
