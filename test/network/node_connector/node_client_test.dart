@Tags(['unit', 'network'])

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('ElectrumNodeClientFactory', () {
    test('create', () async {
      var factory = ElectrumNodeClientFactory();
      var client = await factory.create('localhost', 50001);

      expect(client, isA<NodeClient>());
    });
  });
}
