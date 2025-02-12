import 'package:coconut_lib/coconut_lib.dart';

void main() {
  NetworkType.setNetworkType(NetworkType.regtest);
  SingleSignatureVault vault =
      SingleSignatureVault.random(addressType: AddressType.p2tr);
  // print(vault.descriptor);

  SingleSignatureWallet wallet =
      SingleSignatureWallet.fromDescriptor(vault.descriptor);
  print(wallet.getAddress(0));

  print(WalletUtility.validateAddress(
      "bcrt1pzqhzg546n8lkv7uptg32luwwle582fs503a0tnq3whcg7ul7tflsm4pmtx"));
}
