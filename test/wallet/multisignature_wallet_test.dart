@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  late MultisignatureWallet mockWallet;

  setUpAll(() async {
    NetworkType.setNetworkType(NetworkType.regtest);
    mockWallet = getMockMultisignatureWallet(TestWalletType.forNormal);
  });
  group('MultisignatureWallet', () {});
}
