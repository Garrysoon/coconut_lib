import 'dart:convert';
import 'dart:typed_data';
import 'package:coconut_lib/src/cryptography/converter.dart';
import 'package:crypto/crypto.dart';
import 'package:coconut_lib/src/cryptography/elliptic_curve_cryptography.dart'
    as ecc;
import 'package:bech32m_i/bech32m_i.dart' as bech32m;

Uint8List hashTapTweak(Uint8List pubkey, Uint8List? merkleRoot) {
  // Merkle Root가 없으면 32바이트 0으로 설정
  // merkleRoot ??= Uint8List(32);

  // "TapTweak" 태그 해시 계산
  var tag = sha256.convert(utf8.encode("TapTweak")).bytes;
  var tagHash = Uint8List.fromList(tag + tag);

  // 공개 키와 Merkle Root 연결 후 SHA-256 적용
  Uint8List combined;
  if (merkleRoot == null) {
    combined = Uint8List.fromList(pubkey);
  } else {
    combined = Uint8List.fromList(pubkey + merkleRoot);
  }

  // Uint8List combined = Uint8List.fromList(pubkey);
  var tweakHash = sha256.convert(Uint8List.fromList(tagHash + combined)).bytes;
  print(tweakHash);
  return Uint8List.fromList(tweakHash);
}

String getP2trAddress(String publicKey) {
  Uint8List internalKey = Converter.hexToBytes(publicKey);
  if (internalKey.length != 32) {
    throw ArgumentError("Public Key must be a 32-byte x-only public key.");
  }

  Uint8List compressedPubKey = Uint8List(33);
  compressedPubKey[0] = 0x02;
  compressedPubKey.setRange(1, 33, internalKey);

  Uint8List hashTapTweek = hashTapTweak(internalKey, null);
  print("tweak : ${Converter.bytesToHex(hashTapTweek)}");

  Uint8List tweakPoint = ecc.pointFromScalar(hashTapTweek, true)!;
  print("tweakPoint : ${Converter.bytesToHex(tweakPoint)}");

  Uint8List outputKey =
      ecc.pointAddScalar(compressedPubKey, hashTapTweek, true)!;
  print("outputKey : ${Converter.bytesToHex(outputKey)}(${outputKey.length})");

  bech32m.Bech32mCodec codec = bech32m.Bech32mCodec();
  return codec.encode(bech32m.Bech32m('bc', [0x01] + outputKey));
}

void main() {
  // 예제 공개 키 (x-only Taproot key, 32 bytes)
  getP2trAddress(
      'cc8a4bc64d897bddc5fbc2f670f7a8ba0b386779106cf1223c6fc5d7cd6fc115');
}
