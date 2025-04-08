@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
    NetworkType.setNetworkType(NetworkType.regtest);
    MultisignatureVault vault = MockFactory.createP2trMusig2Vault();

    print(vault.getAddregatedPublilcKey(0, true));
  });
}
