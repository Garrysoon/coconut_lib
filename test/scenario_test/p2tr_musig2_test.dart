@Tags(['scenario'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';

void main() {
  test('Add signature to psbt scenario', () {
    NetworkType.setNetworkType(NetworkType.regtest);
    MultisignatureVault vault = MockFactory.createP2trMusig2Vault();

    Psbt unsignedPsbt = MockFactory.createP2trMuSigUnsignedPsbt();
    print(unsignedPsbt.getAggregatedPublicNonce(0));
  });
}
