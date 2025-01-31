import 'dart:typed_data';
import 'converter.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';

class Encoder {
  Encoder._();
  static int decodeVariableInteger(Uint8List s, int offset) {
    final firstByte = s[offset];
    if (firstByte < 0xfd) {
      return firstByte;
    } else if (firstByte == 0xfd) {
      return ByteData.sublistView(s, offset + 1, offset + 3)
          .getUint16(0, Endian.little);
    } else if (firstByte == 0xfe) {
      return ByteData.sublistView(s, offset + 1, offset + 5)
          .getUint32(0, Endian.little);
    } else {
      return ByteData.sublistView(s, offset + 1, offset + 9)
          .getUint64(0, Endian.little);
    }
  }

  static Uint8List encodeVariableInteger(int i) {
    if (i < 0xfd) {
      return Uint8List.fromList([i.toInt()]);
    } else if (i < 0x10000) {
      return Uint8List.fromList(
          [0xfd] + Converter.intToLittleEndianBytes(i.toInt(), 2));
    } else if (i < 0x100000000) {
      return Uint8List.fromList(
          [0xfe] + Converter.intToLittleEndianBytes(i.toInt(), 4));
    } else {
      throw ArgumentError('integer too large: $i');
    }
  }

  static String encodeBase58(Uint8List bytes) {
    String alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    BigInt num = BigInt.parse(
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);
    String base58 = '';

    while (num > BigInt.zero) {
      final BigInt mod = num % BigInt.from(58);
      base58 = alphabet[mod.toInt()] + base58;
      num ~/= BigInt.from(58);
    }

    for (final byte in bytes) {
      if (byte == 0) {
        base58 = alphabet[0] + base58;
      } else {
        break;
      }
    }

    return base58;
  }

  static String encodeBase58Checksum(Uint8List bytes) {
    var doubleHash =
        Hash.sha256fromByte(Hash.sha256fromByte(Uint8List.fromList(bytes)));
    final Uint8List checksum = Uint8List.fromList(doubleHash.sublist(0, 4));
    final Uint8List payload = Uint8List.fromList([...bytes, ...checksum]);
    return encodeBase58(payload);
  }

  static Uint8List decodeBase58(String string) {
    String alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    if (string.isEmpty) {
      throw Exception('Base58 : Not Base58 string');
    }
    List<int> bytes = [0];
    for (int i = 0; i < string.length; i++) {
      int value = alphabet.indexOf(string[i]);

      var carry = value;
      for (var j = 0; j < bytes.length; ++j) {
        carry += bytes[j] * 58;
        bytes[j] = carry & 0xff;
        carry >>= 8;
      }
      while (carry > 0) {
        bytes.add(carry & 0xff);
        carry >>= 8;
      }
    }
    // deal with leading zeros
    for (var k = 0; string[k] == '1' && k < string.length - 1; ++k) {
      bytes.add(0);
    }

    return _decodeBase58Raw(Uint8List.fromList(bytes.reversed.toList()));
  }

  static Uint8List _decodeBase58Raw(Uint8List buffer) {
    Uint8List payload = buffer.sublist(0, buffer.length - 4);
    Uint8List checksum = buffer.sublist(buffer.length - 4);
    Uint8List target =
        Uint8List.fromList(Hash.sha256fromByte(Hash.sha256fromByte(payload)));
    if (checksum[0] != target[0] ||
        checksum[1] != target[1] ||
        checksum[2] != target[2] ||
        checksum[3] != target[3]) {
      throw Exception("Base58 : Invalid checksum");
    }
    return payload;
  }

  static WIF _decodeWifRaw(Uint8List buffer, [int? version]) {
    if (version != null && buffer[0] != version) {
      throw ArgumentError("Invalid network version");
    }
    if (buffer.length == 33) {
      return WIF(
          version: buffer[0],
          privateKey: buffer.sublist(1, 33),
          compressed: false);
    }
    if (buffer.length != 34) {
      throw ArgumentError("Invalid WIF length");
    }
    if (buffer[33] != 0x01) {
      throw ArgumentError("Invalid compression flag");
    }
    return WIF(
        version: buffer[0],
        privateKey: buffer.sublist(1, 33),
        compressed: true);
  }

  static Uint8List _encodeWifRaw(
      int version, Uint8List privateKey, bool compressed) {
    if (privateKey.length != 32) {
      throw ArgumentError("Invalid privateKey length");
    }
    Uint8List result = Uint8List(compressed ? 34 : 33);
    ByteData bytes = result.buffer.asByteData();
    bytes.setUint8(0, version);
    result.setRange(1, 33, privateKey);
    if (compressed) {
      result[33] = 0x01;
    }
    return result;
  }

  static WIF decodeWif(String string, [int? version]) {
    return _decodeWifRaw(Encoder.decodeBase58(string), version);
  }

  static String encodeWif(WIF wif) {
    return Encoder.encodeBase58(
        _encodeWifRaw(wif.version, wif.privateKey, wif.compressed));
  }
}

class WIF {
  int version;
  Uint8List privateKey;
  bool compressed;
  WIF(
      {required this.version,
      required this.privateKey,
      required this.compressed});
}

void main() {
  // Example integers
  String inputString =
      'd06050454abde3bdd947312b9f54439acb097608a47b0b36a23d76820a3a4044000000006a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8dfffffffff';
  Uint8List bytes = Converter.hexToBytes(inputString);
  var scriptSize = Encoder.decodeVariableInteger(bytes, 36);
  print(scriptSize);
}
