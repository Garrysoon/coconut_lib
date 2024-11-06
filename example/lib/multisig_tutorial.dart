import 'dart:io';
import 'package:coconut_lib/coconut_lib.dart';

void main() async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  SingleSignatureVault inside_vault_1 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'ABC');

  SingleSignatureVault inside_vault_2 = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'DEF');

  SingleSignatureVault outside_vault = SingleSignatureVault.fromMnemonic(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      AddressType.p2wpkh,
      passphrase: 'DEF');

  //Generate P2WSH Keystore
  KeyStore inside_key_1 =
      KeyStore.fromSeed(inside_vault_1.keyStore.seed, AddressType.p2wsh);
  KeyStore inside_key_2 =
      KeyStore.fromSeed(inside_vault_2.keyStore.seed, AddressType.p2wsh);

  String singer_bsms =
      outside_vault.getBsmsForSigner(AddressType.p2wsh, "MyHardWallet");

//   MultisignatureVault multisignatureVault =
//       MultisignatureVault.fromKeyStoreList(
//           [inside_key_1, inside_key_2, outside_key], 2, AddressType.p2wsh);
}
