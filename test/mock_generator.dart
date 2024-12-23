import 'dart:convert';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';

enum TestWalletType { forNormal }

SingleSignatureVault getMockSingleVault(TestWalletType type) {
  SingleSignatureVault? vault;
  if (type == TestWalletType.forNormal) {
    vault = SingleSignatureVault.fromMnemonic(
        'output opera coin bottom power cable abuse bitter maximum cost gift burger',
        AddressType.p2wpkh);
  } else if (type == "random") {
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

Future<WalletStatus> getWalletStatus(TestWalletType type) async {
  WalletStatus? status;
  if (type == TestWalletType.forNormal) {
    File file = File('test/mock_data/wallet_status_for_normal.json');
    status = WalletStatus.fromJson(await file.readAsString());
  }

  return status!;
}
