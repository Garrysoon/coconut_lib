@Tags(['integration'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() async {
  SingleSignatureVault vault = SingleSignatureVault.fromMnemonic(
      'thank split shrimp error own spirit slow glow act evidence globe slight',
      AddressType.p2wpkh);

  SingleSignatureWallet wallet =
      SingleSignatureWallet.fromDescriptor(vault.descriptor);

  NodeConnector nodeConnector = await NodeConnector.connectSync(
      'regtest-electrum.coconut.onl', 60401,
      ssl: true);

  print('fetch on chain data');
  await wallet.fetchOnChainData(nodeConnector);

  print("balance : ${wallet.getBalance()}");

  List<Transfer> tList = wallet.getTransferList(cursor: 0, count: 5);
  for (Transfer t in tList) {
    print(t.blockHeight);
  }
}
