import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import 'chi_square_test.dart';
import 'context_entropy_example.dart';
import 'monte_carlo_test.dart';
import 'random_context_generator.dart';

class ContextVault {
  final List<String> contextList;
  final int requiredKey;
  final MultisignatureVault vault;
  final Uint8List publicKey;

  void removeKey(int count) {
    for (int i = 0; i < count; i++) {
      KeyStore keyStore = vault.keyStoreList[i];
      keyStore.seed = null;
    }
  }

  ContextVault(this.contextList, this.requiredKey, this.vault, this.publicKey);
}

List<ContextVault> contextVaultList = [];
List<ContextVault> thresholdKeyVaultList = [];
List<ContextVault> mixedKeyVaultList = [];

MultisignatureVault createContextEntropyVault(
    List<String> contextList, AddressType addressType,
    {int? requiredSignature}) {
  int numberOfEntropy = contextList.length;
  requiredSignature ??= contextList.length;

  List<KeyStore> keyStoreList = [];
  for (int i = 0; i < numberOfEntropy; i++) {
    keyStoreList.add(KeyStore.fromSeed(
        Seed.fromHexadecimalEntropy(Hash.sha256(contextList[i])), addressType));
  }

  return MultisignatureVault.fromKeyStoreList(keyStoreList, requiredSignature,
      addressType: addressType);
}

void createContextVaultList(int experimentCount) {
  print("0. 100 개의 엔트로피 조합을 활용한 임의의 개인키 생성 ");

  for (int i = 0; i < experimentCount; i++) {
    int totalSignature = Random().nextInt(10) + 1;
    int requiredSignature = Random().nextInt(totalSignature) + 1;
    List<int> contextIndexList =
        List.generate(totalSignature, (_) => Random().nextInt(300));
    List<String> contextList =
        contextIndexList.map((index) => entropy[index]).toList();

    //지갑 생성
    MultisignatureVault vault = createContextEntropyVault(
        contextList, AddressType.p2wsh,
        requiredSignature: requiredSignature);

    contextVaultList.add(ContextVault(contextList, requiredSignature, vault,
        Codec.decodeHex(vault.getAddregatedPublilcKey(0, false))));

    if (i < 3) {
      print("     - [$i] ${contextVaultList[i].contextList.join(", ")}");
      print(
          "       임계값 : ${contextVaultList[i].requiredKey}/${contextVaultList[i].contextList.length}");
      print("       공개키:${Codec.encodeHex(contextVaultList[i].publicKey)}");
    }
    if (i == 3) {
      print("   ...");
    }
    if (i % 100 == 0 && i != 0) {
      print("   $i개의 개인키가 생성되었습니다.");
    }
  }

  print("   -> ${contextVaultList.length}개의 개인키가 생성되었습니다.");
}

void experimentChiSquare(int experimentCount) {
  print("실험 1 : 엔트로피 복잡도 (Chi-square)");
  double sumOfPValue = 0;
  for (int i = 0; i < experimentCount; i++) {
    Uint8List entropy = contextVaultList[i].publicKey;
    final chiSq = chiSquareStatistic(entropy);
    final df = 31;
    final pValue = chiSquarePValue(chiSq, df);
    if (i < 3) {
      print("     - [$i] ${contextVaultList[i].contextList.join(", ")}");
      print("       복잡도 : $pValue");
    }
    if (i == 3) {
      print("   ...");
    }
    if (i % 100 == 0 && i != 0) {
      print("   $i개의 개인키 복잡도 테스트 완료.");
    }
    sumOfPValue += pValue;
  }
  print("   Chi-square 테스트 결과 : ${sumOfPValue / experimentCount}");
}

void experimentMonteCarlo(int experimentCount) {
  print("실험 2 : 엔트로피 복잡도 (Monte Carlo)");
  double sumOfErrorRate = 0;
  for (int i = 0; i < experimentCount; i++) {
    Uint8List entropy = contextVaultList[i].publicKey;
    double errorRate = estimateMonteCarloEntropyError(entropy,
        sampleSize: 3, iterations: 50000, repeat: 50);
    sumOfErrorRate += errorRate;
    if (i < 3) {
      print("     - [$i] ${contextVaultList[i].contextList.join(", ")}");
      print("       오차율 : $errorRate");
    }
    if (i == 3) {
      print("   ...");
    }
    if (i % 100 == 0 && i != 0) {
      print("   $i개의 개인키 오차율 테스트 완료.");
    }
  }
  print("   Monte Carlo 테스트 결과 : ${sumOfErrorRate / experimentCount}");
}

void experimentKeyRestore(int experimentCount) {
  print("실험 3 : 엔트로피 복원율(임계값까지 키 제거)");

  print("   실험을 위한 개인키 복사");
  for (int i = 0; i < contextVaultList.length; i++) {
    ContextVault originalVault = contextVaultList[i];
    // 새로운 ContextVault 객체를 생성하여 깊은 복사 수행
    ContextVault copiedVault = ContextVault(
        List<String>.from(originalVault.contextList), // List 복사
        originalVault.requiredKey,
        originalVault.vault, // MultisignatureVault는 참조 복사 (필요시 별도 처리)
        Uint8List.fromList(originalVault.publicKey) // Uint8List 복사
        );
    thresholdKeyVaultList.add(copiedVault);
  }

  print("   키 제거");
  for (int i = 0; i < thresholdKeyVaultList.length; i++) {
    ContextVault vault = thresholdKeyVaultList[i];
    int removedKeyCount = vault.contextList.length - vault.requiredKey;
    vault.removeKey(removedKeyCount);
  }

  int successCount = 0;
  print("   키 비교");
  for (int i = 0; i < experimentCount; i++) {
    ContextVault originalVault = contextVaultList[i];
    ContextVault removedVault = thresholdKeyVaultList[i];

    if (Codec.encodeHex(originalVault.publicKey) ==
        removedVault.vault.getAddregatedPublilcKey(0, false)) {
      successCount++;
    }
  }
  print("   키 복원 성공 율 : $successCount / $experimentCount");
}

void experimentKeyMixing(int experimentCount) {
  print("실험 4 : 엔트로피 복원율 (키 섞기)");
  for (int i = 0; i < contextVaultList.length; i++) {
    List<String> contextList =
        List<String>.from(contextVaultList[i].contextList);
    if (i < 3) {
      print("     - [$i] Before : ${contextList.join(", ")}");
    }
    contextList.shuffle();
    if (i < 3) {
      print("     - [$i] After : ${contextList.join(", ")}");
    }
    MultisignatureVault vault = createContextEntropyVault(
        contextList, AddressType.p2wsh,
        requiredSignature: contextVaultList[i].requiredKey);
    mixedKeyVaultList.add(ContextVault(
        contextList,
        contextVaultList[i].requiredKey,
        vault,
        Codec.decodeHex(vault.getAddregatedPublilcKey(0, false))));
  }

  print("   키 비교");
  int successCount = 0;
  for (int i = 0; i < experimentCount; i++) {
    ContextVault originalVault = contextVaultList[i];
    ContextVault mixedVault = mixedKeyVaultList[i];

    if (Codec.encodeHex(originalVault.publicKey) ==
        mixedVault.vault.getAddregatedPublilcKey(0, false)) {
      successCount++;
    }
  }
  print("   키 복원 성공 율 : $successCount / $experimentCount");
}

Future<void> experimentKeyTheft() async {
  // 이론적으로 총 6.31 x 10^17번 시도 필요
  int ex5Count = 10;
  print("실험 5 : 키 탈취에 걸리는 시간");
  String originalVaultKey = Codec.encodeHex(contextVaultList[0].publicKey);
  print("   원본 키: $originalVaultKey");
  for (int i = 0; i < ex5Count; i++) {
    List<String> targetContextList = [];
    int numberOfKey = Random().nextInt(10);
    for (int j = 0; j < numberOfKey; j++) {
      String context = await getRandomContext();
      targetContextList.add(context);
    }
    MultisignatureVault targetVault = createContextEntropyVault(
        targetContextList, AddressType.p2wsh,
        requiredSignature: numberOfKey);
    if (i < 3) {
      print("   ${i + 1} 번째 키 탈취 시도");
      print("   대조 엔트로피 생성: ${targetContextList.join(", ")}");
      print("   대조 키: ${targetVault.getAddregatedPublilcKey(0, false)}");
    }
    if (i % 1000 == 0) {
      print("   $i개의 키 탈취 시도 완료.");
    }
    if (targetVault.getAddregatedPublilcKey(0, false) == originalVaultKey) {
      print("     - [$i] 키 탈취 성공");
    }
  }
}

void experimentKeyTheftFast(int exCount) {
  final stopwatch = Stopwatch()..start();

  // 원본 키 정의
  String originalVaultKey = Codec.encodeHex(contextVaultList[0].publicKey);

  for (int i = 0; i < exCount; i++) {
    int numberOfKey = Random().nextInt(5) + 1;
    List<String> publicKeyList = [];

    // numberOfKey 만큼 랜덤 32바이트 hex 생성
    for (int j = 0; j < numberOfKey; j++) {
      List<int> randomBytes = List.generate(32, (_) => Random().nextInt(256));

      // 랜덤 개인키로부터 공개키 생성
      Uint8List publicKeyBytes =
          Ecc.pointFromScalar(Uint8List.fromList(randomBytes), true)!;
      String publicKey = Codec.encodeHex(publicKeyBytes);
      publicKeyList.add(publicKey);
    }
    String targetKey =
        Codec.encodeHex(WalletUtility.aggregatePublicKey(publicKeyList));

    if (originalVaultKey == targetKey) {
      print("     - [$i] 키 탈취 성공");
    }

    if (i % 1000 == 0 && i != 0) {
      print(
          "   $i개의 키 탈취 시도 완료. (소요시간: ${stopwatch.elapsed.inMilliseconds}ms)");
    }
  }
}

main() async {
  final stopwatch = Stopwatch()..start();

  int experimentCount = 10;
  int experimentKeyTheftCount = 10000;

  print("=== 보안 테스트 시작 ===");

  final createVaultStopwatch = Stopwatch()..start();
  createContextVaultList(experimentCount); // 회당 0.6초, 예상시간 60초
  createVaultStopwatch.stop();
  print("지갑 생성 소요시간: ${createVaultStopwatch.elapsed.inMilliseconds}ms");

  final chiSquareStopwatch = Stopwatch()..start();
  experimentChiSquare(experimentCount); // 회당 1초미만, 예상시간 10초
  chiSquareStopwatch.stop();
  print("Chi-square 테스트 소요시간: ${chiSquareStopwatch.elapsed.inMilliseconds}ms");

  final monteCarloStopwatch = Stopwatch()..start();
  experimentMonteCarlo(experimentCount); // 회당 230초, 예상시간 7시간
  monteCarloStopwatch.stop();
  print(
      "Monte Carlo 테스트 소요시간: ${monteCarloStopwatch.elapsed.inMilliseconds}ms");

  final keyRestoreStopwatch = Stopwatch()..start();
  experimentKeyRestore(experimentCount); // 회당 1초 미만
  keyRestoreStopwatch.stop();
  print("키 복원 테스트 소요시간: ${keyRestoreStopwatch.elapsed.inMilliseconds}ms");

  final keyMixingStopwatch = Stopwatch()..start();
  experimentKeyMixing(experimentCount);
  keyMixingStopwatch.stop();
  print("키 섞기 테스트 소요시간: ${keyMixingStopwatch.elapsed.inMilliseconds}ms");

  final keyTheftStopwatch = Stopwatch()..start();
  experimentKeyTheftFast(experimentKeyTheftCount); //예상시간 5시간
  keyTheftStopwatch.stop();
  print("키 탈취 테스트 소요시간: ${keyTheftStopwatch.elapsed.inMilliseconds}ms");

  stopwatch.stop();
  print("=== 전체 테스트 완료 ===");
  print(
      "총 소요시간: ${stopwatch.elapsed.inSeconds}초 (${stopwatch.elapsed.inMilliseconds}ms)");
}
