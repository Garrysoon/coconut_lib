part of '../../coconut_lib.dart';

/// @nodoc
const hightstBit = 0x80000000;

/// @nodoc
const uint31Max = 2147483647; // 2^31 - 1
/// @nodoc
const uint32Max = 4294967295; // 2^32 - 1

/// Represents a hierarchical deterministic wallet.
class HDWallet {
  Uint8List? _d;
  // ignore: non_constant_identifier_names
  Uint8List? _Q;
  Uint8List _chainCode;
  int _depth = 0;
  int _index = 0;
  Uint8List _parentFingerprint = Uint8List.fromList([0, 0, 0, 0, 0]);

  /// @nodoc
  HDWallet(this._d, this._Q, this._chainCode);

  /// @nodoc
  Uint8List get publicKey {
    _Q ??= Ecc.pointFromScalar(_d!, true)!;
    return _Q!;
  }

  /// @nodoc
  Uint8List? get privateKey => _d;

  /// @nodoc
  Uint8List get fingerprint =>
      Hash.sha160fromHex(HEX.encode(publicKey)).sublist(0, 4);

  /// @nodoc
  Uint8List get chainCode => _chainCode;

  /// @nodoc
  int get depth => _depth;

  /// @nodoc
  int get index => _index;

  /// @nodoc
  Uint8List get parentFingerprint => _parentFingerprint;

  /// @nodoc
  bool isNeutered() {
    return _d == null;
  }

  /// @nodoc
  HDWallet neutered() {
    final neutered = HDWallet.fromPublicKey(publicKey, chainCode);
    neutered._depth = depth;
    neutered._index = index;
    neutered._parentFingerprint = parentFingerprint;
    return neutered;
  }

  /// @nodoc
  String toBase58(int version) {
    Uint8List buffer = Uint8List(78);
    ByteData bytes = buffer.buffer.asByteData();
    bytes.setUint32(0, version);
    bytes.setUint8(4, depth);
    bytes.setUint32(5, parentFingerprint.buffer.asByteData().getUint32(0));
    bytes.setUint32(9, index);
    buffer.setRange(13, 45, chainCode);
    if (!isNeutered()) {
      bytes.setUint8(45, 0);
      buffer.setRange(46, 78, privateKey!);
    } else {
      buffer.setRange(45, 78, publicKey);
    }

    Uint8List hash =
        Uint8List.fromList(Hash.sha256fromByte(Hash.sha256fromByte(buffer)));
    Uint8List combine = Uint8List.fromList(
        [buffer, hash.sublist(0, 4)].expand((i) => i).toList(growable: false));
    return Codec.encodeBase58(combine);
  }

  /// get master private WIF format
  String getMasterPrivateKey() {
    if (privateKey == null) {
      throw Exception("HDWallet : Missing private key");
    }
    return Codec.encodeWif(
        WIF(version: 0x80, privateKey: privateKey!, compressed: true));
  }

  /// @nodoc
  HDWallet derive(int index) {
    if (index > uint32Max || index < 0) throw ArgumentError("Expected UInt32");
    final isHardened = index >= hightstBit;
    Uint8List data = Uint8List(37);
    if (isHardened) {
      if (isNeutered()) {
        throw Exception("Missing private key for hardened child key");
      }
      data[0] = 0x00;
      data.setRange(1, 33, privateKey!);
      data.buffer.asByteData().setUint32(33, index);
    } else {
      data.setRange(0, 33, publicKey);
      data.buffer.asByteData().setUint32(33, index);
    }
    final I = Hash.hmacSha512(chainCode, data);
    final il = I.sublist(0, 32);
    final ir = I.sublist(32);
    if (!Ecc.isPrivate(il)) {
      return derive(index + 1);
    }
    HDWallet hd;
    if (!isNeutered()) {
      final ki = Ecc.privateAdd(privateKey!, il);
      if (ki == null) return derive(index + 1);
      hd = HDWallet.fromPrivateKey(ki, ir);
    } else {
      final ki = Ecc.pointAddScalar(publicKey, il, true);
      if (ki == null) return derive(index + 1);
      hd = HDWallet.fromPublicKey(ki, ir);
    }
    hd._depth = depth + 1;
    hd._index = index;
    hd._parentFingerprint = fingerprint;
    return hd;
  }

  /// @nodoc
  HDWallet deriveHardened(int index) {
    if (index > uint31Max || index < 0) throw ArgumentError("Expected UInt31");
    return derive(index + hightstBit);
  }

  /// @nodoc
  HDWallet derivePath(String path) {
    final regex = RegExp(r"^(m\/)?(\d+'?\/)*\d+'?$");
    if (!regex.hasMatch(path)) {
      throw Exception("Invalid Path");
    }
    List<String> splitPath = path.split("/");
    if (splitPath[0] == "m") {
      if (parentFingerprint.buffer.asByteData().getUint32(0) != 0) {
        throw Exception("Expected master, got child");
      }
      splitPath = splitPath.sublist(1);
    }
    return splitPath.fold(this, (HDWallet prevHd, String indexStr) {
      int index;
      if (indexStr.substring(indexStr.length - 1) == "'") {
        index = int.parse(indexStr.substring(0, indexStr.length - 1));
        return prevHd.deriveHardened(index);
      } else {
        index = int.parse(indexStr);
        return prevHd.derive(index);
      }
    });
  }

  Uint8List signEcdsa(Uint8List message) {
    return Converter.rawToDerSignature(Ecc.signEcdsa(message, privateKey!));
  }

  Uint8List signSchnorr(Uint8List message, bool applyTweak,
      {Uint8List? auxRand}) {
    Uint8List secretKey = applyTweak ? getTweakedPrivateKey() : privateKey!;
    return Ecc.signSchnorr(message, secretKey, auxRand: auxRand);
  }

  Uint8List signSchnorrForMuSig2(
      Uint8List message,
      Uint8List aggregatedPublicKey,
      Uint8List aggregatedPublicNonce,
      Uint8List secretNonce,
      List<Uint8List> participantPublicKeys) {
    if (secretNonce.length < 64) {
      throw ArgumentError("Secret nonce too short: ${secretNonce.length}");
    }

    return Ecc.signSchnorrForMuSig2(
        message,
        aggregatedPublicKey,
        aggregatedPublicNonce,
        privateKey!,
        secretNonce,
        Ecc.compressPoint(publicKey, isXOnly: true),
        participantPublicKeys);
  }

  // Returns the tweaked private key for Taproot/MuSig2.
  Uint8List getTweakedPrivateKey(
      {Uint8List? merkleRoot, Uint8List? aggregatedPublicKey}) {
    // print("prv:" + Encoder.encodeHex(publicKey));
    if (privateKey == null) {
      throw Exception("HDWallet: Private key is not available.");
    }
    merkleRoot ??= Uint8List(0);
    Uint8List keyToTweak = aggregatedPublicKey ?? publicKey.sublist(1);
    Uint8List hashTapTweak =
        Hash.hashTapTweak('TapTweak', keyToTweak, merkleRoot);

    Uint8List? evenPrivateKey = privateKey;

    if (publicKey[0] == 0x03) {
      // print("negate priv origin");
      evenPrivateKey = Ecc.privateNegate(privateKey!)!;
    }

    Uint8List tweakedPrivateKey =
        Ecc.privateAdd(evenPrivateKey!, hashTapTweak)!;

    Uint8List? tweakedPublicKey = Ecc.pointFromScalar(tweakedPrivateKey, true);
    if (tweakedPublicKey![0] == 0x03) {
      // print("negate priv tweak");
      tweakedPrivateKey = Ecc.privateNegate(tweakedPrivateKey)!;
    }

    // print("Tweaked pub Key from tweaked private key : " +
    //     Encoder.encodeHex(
    //         ecc.pointFromScalar(tweakedPrivateKey, true) as List<int>));
    // print("Tweaked pub Key from origin public key : " +
    //     Encoder.encodeHex(getTweakedPublicKey(merkleRoot: merkleRoot)));

    return tweakedPrivateKey;
  }

  Uint8List getTweakedPublicKey(
      {Uint8List? merkleRoot, Uint8List? aggregatedPublicKey}) {
    // print("pub:" + Encoder.encodeHex(publicKey));
    Uint8List keyToTweak = aggregatedPublicKey ?? publicKey.sublist(1);
    merkleRoot ??= Uint8List(0);

    Uint8List hashTapTweak =
        Hash.hashTapTweak('TapTweak', keyToTweak, merkleRoot);

    Uint8List evenPublicKey = publicKey;
    if (publicKey[0] == 0x03) {
      // print("negate pub origin");
      evenPublicKey = Ecc.pointNegate(publicKey)!.sublist(1);
    }

    Uint8List tweakedPubKey =
        Ecc.pointAddScalar(evenPublicKey, hashTapTweak, true)!;
    // print("pub:" + Encoder.encodeHex(tweakedPubKey));
    if (tweakedPubKey[0] == 0x03) {
      // print("negate pub tweak");

      tweakedPubKey = Ecc.pointNegate(tweakedPubKey)!;
    }
    // print("PUB : " + Encoder.encodeHex(tweakedPubKey.sublist(1)));
    return tweakedPubKey.sublist(1);
  }

  verifyEcdsa(Uint8List message, Uint8List signature) {
    return Ecc.verifyEcdsa(message, publicKey, signature);
  }

  verifySchnorr(Uint8List message, Uint8List signature, bool applyTweak,
      {Uint8List? merkleRoot}) {
    if (applyTweak) {
      return Ecc.verifySchnorr(
          message, getTweakedPublicKey(merkleRoot: merkleRoot), signature);
    } else {
      return Ecc.verifySchnorr(message, publicKey, signature);
    }
  }

  /// @nodoc
  factory HDWallet.fromPublicKey(Uint8List publicKey, Uint8List chainCode) {
    if (!Ecc.isPoint(publicKey)) {
      throw ArgumentError("Point is not on the curve");
    }
    return HDWallet(null, publicKey, chainCode);
  }

  /// @nodoc
  factory HDWallet.fromPrivateKey(Uint8List privateKey, Uint8List chainCode) {
    if (privateKey.length != 32) {
      throw Exception(
          "Expected property privateKey of type Buffer(Length: 32)");
    }
    if (!Ecc.isPrivate(privateKey)) {
      throw ArgumentError("Private key not in range [1, n]");
    }
    return HDWallet(privateKey, null, chainCode);
  }

  /// @nodoc
  factory HDWallet.fromRootSeed(String seed) {
    Uint8List seedBytes = Uint8List.fromList(HEX.decode(seed));

    if (seedBytes.length < 16) {
      throw Exception("Seed should be at least 128 bits");
    }
    if (seedBytes.length > 64) {
      throw Exception(" Seed should be at most 512 bits");
    }
    final I = Hash.hmacSha512(utf8.encode("Bitcoin seed"), seedBytes);
    final privateKey = I.sublist(0, 32);
    final chainCode = I.sublist(32);
    final publicKey = Ecc.pointFromScalar(privateKey, true)!;

    return HDWallet(privateKey, publicKey, chainCode);
  }

  /// @nodoc
  String toJson() {
    if (privateKey != null) {
      return jsonEncode({
        'privateKey': Codec.encodeHex(privateKey!),
        'publicKey': Codec.encodeHex(publicKey),
        'chainCode': Codec.encodeHex(chainCode),
      });
    } else {
      return jsonEncode({
        'publicKey': Codec.encodeHex(publicKey),
        'chainCode': Codec.encodeHex(chainCode),
      });
    }
  }

  /// @nodoc
  factory HDWallet.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    if (map.containsKey('privateKey')) {
      return HDWallet(Codec.decodeHex(map['privateKey']),
          Codec.decodeHex(map['publicKey']), Codec.decodeHex(map['chainCode']));
    } else {
      return HDWallet.fromPublicKey(
          Codec.decodeHex(map['publicKey']), Codec.decodeHex(map['chainCode']));
    }
  }
}
