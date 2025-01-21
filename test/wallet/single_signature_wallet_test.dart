@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_generator.dart';

void main() async {
  late SingleSignatureWallet mockWallet;

  setUpAll(() async {
    NetworkType.setNetworkType(NetworkType.regtest);
    mockWallet = getMockSingleWallet(TestWalletType.forNormal);
  });

  group('SingleSignatureWallet', () {});
}
