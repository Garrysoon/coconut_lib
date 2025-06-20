import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../mock_factory.dart';
import 'context_vault_generator.dart';

double monteCarloEntropy(Uint8List data, int sampleSize, int iterations) {
  final rand = Random.secure();
  final int maxStart = data.length - sampleSize;
  final Map<String, int> freq = {};

  for (int i = 0; i < iterations; i++) {
    final start = rand.nextInt(maxStart);
    final sub = data.sublist(start, start + sampleSize);
    final key = sub.join(',');

    freq[key] = (freq[key] ?? 0) + 1;
  }

  double entropy = 0.0;
  final total = freq.values.reduce((a, b) => a + b);
  for (var count in freq.values) {
    final p = count / total;
    entropy -= p * (log(p) / ln2);
  }

  final maxEntropy = log(pow(256, sampleSize)) / ln2;
  return entropy / maxEntropy;
}

/// 평균과 표준편차를 계산해 오차 수준 출력
double estimateMonteCarloEntropyError(Uint8List data,
    {int sampleSize = 3, int iterations = 10000, int repeat = 30}) {
  final List<double> entropyList = [];

  for (int i = 0; i < repeat; i++) {
    entropyList.add(monteCarloEntropy(data, sampleSize, iterations));
  }

  final mean = entropyList.reduce((a, b) => a + b) / repeat;
  final stddev = sqrt(
      entropyList.map((e) => pow(e - mean, 2)).reduce((a, b) => a + b) /
          repeat);
  final errorRate = (stddev / mean);

  return errorRate;
}

void main() {
  group('Monte Carlo Entropy Complexity Test', () {
    test('Monte Carlo function validation (worst case)', () {
      final data = Uint8List.fromList([
        55, 55, 55, 55, 55, 55, 55, 55,
        55, 55, 55, 55, 55, 55, 55, 55,
        55, 55, 55, 55, 55, 55, 55, 55,
        55, 55, 55, 55, 55, 55,
        // 2 bytes of entropy chaos
        123, 8
      ]);
      //암호 엔트로피 평가 도구 기준(entropy.js 등)
      double errorRate = estimateMonteCarloEntropyError(data,
          sampleSize: 3, iterations: 50000, repeat: 50);
      // print(errorRate);
      expect(errorRate > 0.01, true); // 1% 이상의 허용오차
    });

    test('Monte Carlo function validation (random case)', () {
      final random = Random.secure();
      final data =
          Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
      double errorRate = estimateMonteCarloEntropyError(data,
          sampleSize: 3, iterations: 50000, repeat: 50);
      // print(errorRate);
      expect(errorRate < 0.0001, true); // 0.01% 이하의 허용오차
    });
    test('Entropy Complexity Test (Monte Carlo)', () async {
      int testCount = 5;
      final stopwatch = Stopwatch()..start();

      final futures = List.generate(testCount, (i) async {
        //지갑 생성
        MultisignatureVault vault = ContextVaultGenerator.getVaultList(i);
        //엔트로피(공개키) 추출
        String publicKey = vault.getAddregatedPublilcKey(0, false);
        Uint8List entropy = Codec.decodeHex(publicKey);
        double errRate = estimateMonteCarloEntropyError(entropy,
            sampleSize: 3, iterations: 50000, repeat: 50);
        print(errRate);
        return errRate;
      });

      final results = await Future.wait(futures);
      final sumOfErrorRate = results.reduce((a, b) => a + b);

      stopwatch.stop();
      print(
          'Monte Carlo test execution time: ${stopwatch.elapsed.inSeconds} seconds');
      expect((sumOfErrorRate / testCount) < 0.0001, true);
    });
  });
}
