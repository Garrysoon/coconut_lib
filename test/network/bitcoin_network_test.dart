@Tags(['unit', 'network'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('BitcoinNetwork', () {
    test('네트워크 변경이 정상적으로 동작해야 함', () {
      BitcoinNetwork.setNetwork(BitcoinNetwork.mainnet);
      expect(BitcoinNetwork.currentNetwork, equals(BitcoinNetwork.mainnet));

      BitcoinNetwork.setNetwork(BitcoinNetwork.testnet);
      expect(BitcoinNetwork.currentNetwork, equals(BitcoinNetwork.testnet));

      BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
      expect(BitcoinNetwork.currentNetwork, equals(BitcoinNetwork.regtest));
    });

    test('isTestnet이 올바르게 동작해야 함', () {
      expect(BitcoinNetwork.mainnet.isTestnet, isFalse);
      expect(BitcoinNetwork.testnet.isTestnet, isTrue);
      expect(BitcoinNetwork.regtest.isTestnet, isTrue);
    });

    test('getNetwork가 올바른 네트워크를 반환해야 함', () {
      expect(
          BitcoinNetwork.getNetwork('mainnet'), equals(BitcoinNetwork.mainnet));
      expect(
          BitcoinNetwork.getNetwork('testnet'), equals(BitcoinNetwork.testnet));
      expect(
          BitcoinNetwork.getNetwork('regtest'), equals(BitcoinNetwork.regtest));
    });

    test('getNetwork가 잘못된 네트워크명에 대해 예외를 발생시켜야 함', () {
      expect(() => BitcoinNetwork.getNetwork('invalid'), throwsException);
    });

    test('toString이 올바른 네트워크명을 반환해야 함', () {
      expect(BitcoinNetwork.mainnet.toString(), equals('mainnet'));
      expect(BitcoinNetwork.testnet.toString(), equals('testnet'));
      expect(BitcoinNetwork.regtest.toString(), equals('regtest'));
    });

    test('동일한 네트워크는 같다고 판단되어야 함', () {
      var mainnet1 = BitcoinNetwork('mainnet', false);
      var mainnet2 = BitcoinNetwork('mainnet', false);
      var testnet = BitcoinNetwork('testnet', true);

      expect(mainnet1 == mainnet2, isTrue);
      expect(mainnet1 == testnet, isFalse);
    });

    test('values가 모든 네트워크를 포함해야 함', () {
      var networks = BitcoinNetwork.values;
      expect(networks.length, equals(3));
      expect(networks.contains(BitcoinNetwork.mainnet), isTrue);
      expect(networks.contains(BitcoinNetwork.testnet), isTrue);
      expect(networks.contains(BitcoinNetwork.regtest), isTrue);
    });
  });
}
