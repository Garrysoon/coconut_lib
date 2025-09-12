import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Brain Wallet', () {
    test('should generate a valid brain wallet', () {
      NetworkType.setNetworkType(NetworkType.regtest);
      String keyword0 = '루이스';
      String keyword1 = '도이';
      String keyword2 = '엘라';
      KeyStore keyStore0 =
          KeyStore.fromEntropy(Hash.sha256(keyword0), AddressType.p2wpkh);
      KeyStore keyStore1 =
          KeyStore.fromEntropy(Hash.sha256(keyword1), AddressType.p2wpkh);
      KeyStore keyStore2 =
          KeyStore.fromEntropy(Hash.sha256(keyword2), AddressType.p2wpkh);

      SingleSignatureVault sVault0 =
          SingleSignatureVault.fromKeyStore(keyStore0);
      SingleSignatureVault sVault1 =
          SingleSignatureVault.fromKeyStore(keyStore1);
      SingleSignatureVault sVault2 =
          SingleSignatureVault.fromKeyStore(keyStore2);

      MultisignatureVault vault = MultisignatureVault.fromKeyStoreList([
        KeyStore.fromSignerBsms(
            sVault0.getSignerBsms(AddressType.p2trMuSig2, "")),
        KeyStore.fromSignerBsms(
            sVault1.getSignerBsms(AddressType.p2trMuSig2, "")),
        KeyStore.fromSignerBsms(
            sVault2.getSignerBsms(AddressType.p2trMuSig2, ""))
      ], 3, addressType: AddressType.p2trMuSig2);
    });
  });
}
