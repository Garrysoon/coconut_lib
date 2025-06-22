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
          KeyStore.fromEntropy(Hash.sha256(keyword0), AddressType.p2trMuSig2);
      KeyStore keyStore1 =
          KeyStore.fromEntropy(Hash.sha256(keyword1), AddressType.p2trMuSig2);
      KeyStore keyStore2 =
          KeyStore.fromEntropy(Hash.sha256(keyword2), AddressType.p2trMuSig2);

      MultisignatureVault vault = MultisignatureVault.fromKeyStoreList(
          [keyStore0, keyStore1, keyStore2], 3,
          addressType: AddressType.p2trMuSig2);

      MultisignatureWallet wallet =
          MultisignatureWallet.fromDescriptor(vault.descriptor);

      print(vault.getAddress(0));
      print(wallet.getAddress(0));

      // Psbt psbt = Psbt.fromTransaction(Transaction.forSinglePayment(utxoList, receiveAddress, changeAddressDerivationPath, amount, feeRate, wallet), wallet)

// 84079059
// 31b68a0cd0b90b1afeab55ba5b1b79a1ec838ca476d66049f8f4834e796705f8
// m/86'/1'/0'/0/0
// 3c71beb5eee9ae6709d31db6659956a7574f895d934ea9228060c98ffea91a22
// 84079059
// m/86'/1'/0'
    });
  });
}
