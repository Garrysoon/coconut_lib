import 'dart:math';
import 'dart:typed_data';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';
import 'dart:math' as math;

import '../mock_factory.dart';
import 'context_vault_generator.dart';

//알고리즘 출처 : https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.chisquare.html
double chiSquareStatistic(Uint8List data) {
  const int numBuckets = 256;
  final List<int> frequencies = List.filled(numBuckets, 0);

  for (final byte in data) {
    frequencies[byte]++;
  }

  final int total = data.length;
  final double expected = total / numBuckets;
  double chiSquare = 0.0;

  for (int i = 0; i < numBuckets; i++) {
    final observed = frequencies[i];
    chiSquare += pow(observed - expected, 2) / expected;
  }

  return chiSquare;
}

//오차 함수 근사 공식
double erf(double x) {
  // constants
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  final sign = x < 0 ? -1 : 1;
  final absX = x.abs();

  final t = 1.0 / (1.0 + p * absX);
  final y = 1.0 -
      ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * exp(-absX * absX);

  return sign * y;
}

//카이 제곱 분포 누적분포함수 https://www.rdocumentation.org/packages/fastmatrix/versions/0.5-7721/topics/wilson.hilferty
double chiSquarePValue(double chiSq, int df) {
  final z = (pow(chiSq / df, 1 / 3) - 1 + 2 / (9 * df)) / sqrt(2 / (9 * df));
  // print((z / sqrt(2)));
  final p = 1 - 0.5 * (1 + erf(z / sqrt(2)));
  return p;
}

void main() {
  group('Chi-square Entropy Complexity Test', () {
    test('Validate algorithm (uniform entropy)', () {
      //균등 분포된 엔트로피 [0,1,2,3,4,5,6,7,8,9,10, ... 255]
      final Uint8List uniformEntropy =
          Uint8List.fromList(List.generate(256, (i) => i));

      final chiSq = chiSquareStatistic(uniformEntropy);
      final pVal = chiSquarePValue(chiSq, 255);
      print(pVal);
      expect(chiSq, 0);
      expect(pVal, 1.0000);
    });

    test('Validate algorithm (uniform shuffled entropy)', () {
      // 반복적 엔트로피
      final List<int> data_1 = List.generate(128, (i) => i);
      final List<int> data_2 = List.generate(128, (i) => i);

      final List<int> data = [...data_1, ...data_2];

      final Uint8List uniformShuffledEntropy = Uint8List.fromList(data);

      final chiSq = chiSquareStatistic(uniformShuffledEntropy);
      final pVal = chiSquarePValue(chiSq, uniformShuffledEntropy.length);
      // print(pVal);
      expect((0.4 < pVal && pVal < 0.6), true);
    });

    test('Entropy Complexity Test (Chi-square)', () {
      double sumOfPValue = 0;
      for (int i = 0; i < 1000; i++) {
        MultisignatureVault vault = ContextVaultGenerator.getVaultList(i);
        //엔트로피(공개키) 추출
        String publicKey = vault.getAddregatedPublilcKey(0, false);
        Uint8List entropy = Codec.decodeHex(publicKey);
        final chiSq = chiSquareStatistic(entropy);
        final df = 31;
        final pValue = chiSquarePValue(chiSq, df);
        sumOfPValue += pValue;
      }

      expect((sumOfPValue / 1000) < 0.0001, true);
    });
  });
}
