import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// SHA256 해시 함수
Uint8List sha256Hash(Uint8List data) {
  return Uint8List.fromList(sha256.convert(data).bytes);
}

/// CompactSize 형식으로 스크립트 길이를 인코딩
Uint8List encodeCompactSize(int size) {
  if (size < 0xfd) {
    return Uint8List.fromList([size]);
  } else if (size <= 0xffff) {
    return Uint8List.fromList([0xfd, size & 0xff, (size >> 8) & 0xff]);
  } else if (size <= 0xffffffff) {
    return Uint8List.fromList([
      0xfe,
      size & 0xff,
      (size >> 8) & 0xff,
      (size >> 16) & 0xff,
      (size >> 24) & 0xff
    ]);
  } else {
    throw ArgumentError("CompactSize encoding supports up to 4 bytes.");
  }
}

/// "TapLeaf" 태그 해싱을 적용하여 SHA256 해시 계산
Uint8List taggedHash(String tag, Uint8List data) {
  Uint8List tagHash = sha256Hash(Uint8List.fromList(utf8.encode(tag)));
  Uint8List prefix = Uint8List.fromList(tagHash + tagHash);
  return sha256Hash(Uint8List.fromList(prefix + data));
}

/// Bitcoin Core의 ComputeTapleafHash를 Dart로 변환
String computeTapleafHash(int leafVersion, String scriptHex) {
  // 1️⃣ Hex Script를 바이트 배열로 변환
  Uint8List scriptBytes = Uint8List.fromList(hexDecode(scriptHex));

  // 2️⃣ CompactSize로 스크립트 길이 변환
  Uint8List scriptSize = encodeCompactSize(scriptBytes.length);

  // 3️⃣ SHA256(TapLeaf || TapLeaf || leafVersion || CompactSize(script_size) || script)
  Uint8List tapleafHash = taggedHash(
      "TapLeaf", Uint8List.fromList([leafVersion] + scriptSize + scriptBytes));

  // 4️⃣ 최종 해시를 반환 (Merkle Root 용)
  return hexEncode(tapleafHash);
}

/// Hex 문자열을 바이트 리스트로 변환
Uint8List hexDecode(String hexStr) {
  return Uint8List.fromList(List<int>.generate(hexStr.length ~/ 2,
      (i) => int.parse(hexStr.substring(i * 2, i * 2 + 2), radix: 16)));
}

/// 바이트 리스트를 Hex 문자열로 변환
String hexEncode(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// ✅ 실행 예제
void main() {
  // 테스트 벡터 (Bitcoin Core Test Vectors)
  String scriptHex =
      "20b617298552a72ade070667e86ca63b8f5789a9fe8731ef91202a91c9f3459007ac";
  int leafVersion = 0xc0; // 192 (BIP341 기본 값)

  // Tapleaf Hash 계산
  String tapleafHash = computeTapleafHash(leafVersion, scriptHex);

  print("Tapleaf Hash: $tapleafHash");
  print(
      "Expected    : c525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b");
}
