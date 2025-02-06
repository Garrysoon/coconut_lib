import 'dart:convert';
import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'package:pointycastle/export.dart';
import 'converter.dart';

class Hash {
  Hash._();
  static String sha256(String input) {
    var bytes = utf8.encode(input);
    var digest = SHA256Digest().process(bytes);
    return Converter.bytesToHex(digest);
  }

  static String sha256fromHex(String hex) {
    Uint8List decoded = Uint8List.fromList(HEX.decode(hex));
    var hashed = SHA256Digest().process(decoded);
    return Converter.bytesToHex(hashed);
  }

  static Uint8List sha256fromByte(Uint8List bytes) {
    return SHA256Digest().process(bytes);
  }

  static Uint8List hmacSha512(Uint8List key, Uint8List data) {
    var hmacSha512 = HMac(SHA512Digest(), 128)
      ..init(KeyParameter(key)); // HMAC-SHA-512 생성
    // var hmacSha512 = crypto.Hmac(crypto.sha512, key); // HMAC-SHA-512 생성
    var digest = hmacSha512.process(data); // 데이터에 대한 HMAC-SHA-512 계산
    return digest; // 계산된 해시를 문자열로 반환
  }

  static Uint8List sha160fromHex(String hex) {
    var decoded = Uint8List.fromList(HEX.decode(hex));
    final hashed = sha256fromByte(decoded);
    // final hashed = crypto.sha256.convert(decoded);
    final ripemd = RIPEMD160Digest().process(hashed);
    return ripemd;
  }

  static Uint8List sha160fromByte(Uint8List hex) {
    final hashed = sha256fromByte(hex);
    // final hashed = crypto.sha256.convert(decoded);
    final ripemd = RIPEMD160Digest().process(hashed);
    return ripemd;
  }

  static pbkdf2(String secret, String salt) {
    PBKDF2KeyDerivator derivator =
        PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));

    final saltList = Uint8List.fromList(utf8.encode(salt));
    derivator.reset();
    derivator.init(Pbkdf2Parameters(saltList, 2048, 64));
    var array = derivator.process(Uint8List.fromList(secret.codeUnits));
    return array.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }

  static Uint8List hashTapTweak(Uint8List pubkey, Uint8List? merkleRoot) {
    // var tag = sha256.convert(utf8.encode("TapTweak")).bytes;
    var tag = sha256fromByte(utf8.encode("TapTweak"));
    var tagHash = Uint8List.fromList(tag + tag);
    Uint8List combined;
    if (merkleRoot == null) {
      combined = Uint8List.fromList(pubkey);
    } else {
      combined = Uint8List.fromList(pubkey + merkleRoot);
    }
    // var tweakHash =
    //     sha256.convert(Uint8List.fromList(tagHash + combined)).bytes;

    var tweakHash = sha256fromByte(Uint8List.fromList(tagHash + combined));
    return Uint8List.fromList(tweakHash);
  }
}
