// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of '../../coconut_lib.dart';

class Ecc {
  static final ZERO32 = Uint8List.fromList(List.generate(32, (index) => 0));
  static final EC_GROUP_ORDER = HEX.decode(
      "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
  static final EC_P = HEX.decode(
      "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f");
  static final secp256k1 = ECCurve_secp256k1();
  static final n = secp256k1.n;
  static final G = secp256k1.G;
  static BigInt nDiv2 = n >> 1;
  static const THROW_BAD_PRIVATE = 'Expected Private';
  static const THROW_BAD_POINT = 'Expected Point';
  static const THROW_BAD_TWEAK = 'Expected Tweak';
  static const THROW_BAD_HASH = 'Expected Hash';
  static const THROW_BAD_SIGNATURE = 'Expected Signature';

  static bool isPrivate(Uint8List x) {
    if (!isScalar(x)) return false;
    return _compare(x, ZERO32) > 0 && // > 0
        _compare(x, EC_GROUP_ORDER as Uint8List) < 0; // < G
  }

  static bool isPoint(Uint8List p) {
    if (p.length == 32) {
      return _compare(p, ZERO32) != 0 && _compare(p, EC_P as Uint8List) < 0;
    }
    if (p.length < 33) {
      return false;
    }
    var t = p[0];
    var x = p.sublist(1, 33);

    if (_compare(x, ZERO32) == 0) {
      return false;
    }
    if (_compare(x, EC_P as Uint8List) == 1) {
      return false;
    }
    try {
      decodeFrom(p);
    } catch (err) {
      return false;
    }
    if ((t == 0x02 || t == 0x03) && p.length == 33) {
      return true;
    }
    var y = p.sublist(33);
    if (_compare(y, ZERO32) == 0) {
      return false;
    }
    if (_compare(y, EC_P as Uint8List) == 1) {
      return false;
    }
    if (t == 0x04 && p.length == 65) {
      return true;
    }
    return false;
  }

  static bool isScalar(Uint8List x) {
    return x.length == 32;
  }

  static bool isOrderScalar(x) {
    if (!isScalar(x)) return false;
    return _compare(x, EC_GROUP_ORDER as Uint8List) < 0; // < G
  }

  static bool isSignature(Uint8List value) {
    Uint8List r = value.sublist(0, 32);
    Uint8List s = value.sublist(32, 64);

    return value.length == 64 &&
        _compare(r, EC_GROUP_ORDER as Uint8List) < 0 &&
        _compare(s, EC_GROUP_ORDER as Uint8List) < 0;
  }

  static bool _isPointCompressed(Uint8List p) {
    return p[0] != 0x04;
  }

  static bool assumeCompression(bool? value, Uint8List? pubkey) {
    if (value == null && pubkey != null) return _isPointCompressed(pubkey);
    if (value == null) return true;
    return value;
  }

  static Uint8List compressPoint(Uint8List point, {bool isXOnly = false}) {
    ECPoint ecPoint;

    if (point.length == 32) {
      // x-only → assume even y (try 0x02, fallback to 0x03)
      try {
        ecPoint =
            secp256k1.curve.decodePoint(Uint8List.fromList([0x02, ...point]))!;
      } catch (_) {
        ecPoint =
            secp256k1.curve.decodePoint(Uint8List.fromList([0x03, ...point]))!;
      }
    } else if (point.length == 33 || point.length == 65) {
      ecPoint = secp256k1.curve.decodePoint(point)!;
    } else {
      throw ArgumentError(
          "Unsupported public key format (length: ${point.length})");
    }

    if (isXOnly) {
      return ecPoint.getEncoded(false).sublist(1, 33); // x-only
    } else {
      return ecPoint.getEncoded(true); // compressed
    }
  }

  static Uint8List? pointFromScalar(Uint8List d, bool compressed) {
    if (!isPrivate(d)) throw ArgumentError(THROW_BAD_PRIVATE);
    BigInt dd = fromBuffer(d);
    ECPoint pp = (G * dd) as ECPoint;
    if (pp.isInfinity) return null;
    return getEncoded(pp, compressed);
  }

  static Uint8List? pointMultiplyScalar(
      Uint8List p, Uint8List tweak, bool compressed) {
    Uint8List adjustedP =
        (p.length == 32) ? Uint8List.fromList([0x02, ...p]) : p;

    BigInt tt = fromBuffer(tweak);
    ECPoint? pp = (decodeFrom(adjustedP)! * tt) as ECPoint;
    if (pp.isInfinity) return null;
    return getEncoded(pp, compressed);
  }

  static Uint8List? pointCombine(Uint8List p, Uint8List q, bool compressed) {
    if (!isPoint(p)) throw ArgumentError(THROW_BAD_POINT);
    if (!isPoint(q)) throw ArgumentError(THROW_BAD_POINT);

    ECPoint? pp = decodeFrom(p);
    ECPoint? qq = decodeFrom(q);
    ECPoint? pq = (pp! + qq!) as ECPoint;
    if (pq.isInfinity) return null;
    return getEncoded(pq, compressed);
  }

  static Uint8List? pointAddScalar(
      Uint8List p, Uint8List tweak, bool isCompressed) {
    if (!isPoint(p)) throw ArgumentError(THROW_BAD_POINT);
    if (!isOrderScalar(tweak)) throw ArgumentError(THROW_BAD_TWEAK);

    Uint8List adjustedP =
        (p.length == 32) ? Uint8List.fromList([0x02, ...p]) : p;
    bool compressed = assumeCompression(isCompressed, adjustedP);

    ECPoint? pp = decodeFrom(adjustedP);
    if (pp == null || pp.isInfinity) throw ArgumentError("Invalid public key");

    BigInt tt = fromBuffer(tweak);
    if (tt == BigInt.zero) return getEncoded(pp, compressed);

    ECPoint qq = (G * tt)!;
    ECPoint uu = (pp + qq)!;
    if (uu.isInfinity) return null;

    Uint8List encoded = getEncoded(uu, compressed);
    return encoded;
  }

  static Uint8List? pointNegate(Uint8List p) {
    if (!isPoint(p)) throw ArgumentError(THROW_BAD_POINT);

    BigInt order = fromBuffer(EC_GROUP_ORDER as Uint8List);

    ECPoint? P = decodeFrom(p);
    if (P == null || P.isInfinity) return null;

    BigInt? x = P.x!.toBigInteger();
    BigInt? y = P.y!.toBigInteger();
    BigInt negY = (order - y!) % order;

    ECPoint negP = secp256k1.curve.createPoint(x!, negY);

    bool compressed = _isPointCompressed(p);
    return getEncoded(negP, compressed);
  }

  static Uint8List? privateAdd(Uint8List d, Uint8List tweak) {
    if (!isPrivate(d)) throw ArgumentError(THROW_BAD_PRIVATE);
    if (!isOrderScalar(tweak)) throw ArgumentError(THROW_BAD_TWEAK);
    BigInt dd = fromBuffer(d);
    BigInt tt = fromBuffer(tweak);
    Uint8List dt = toBuffer((dd + tt) % n);

    if (dt.length < 32) {
      Uint8List padLeadingZero = Uint8List(32 - dt.length);
      dt = Uint8List.fromList(padLeadingZero + dt);
    }

    if (!isPrivate(dt)) return null;
    return dt;
  }

  static Uint8List? privateNegate(Uint8List d) {
    if (!isOrderScalar(d)) throw ArgumentError(THROW_BAD_TWEAK);
    BigInt dd = fromBuffer(EC_GROUP_ORDER as Uint8List);
    BigInt tt = fromBuffer(d);
    Uint8List dt = toBuffer((dd - tt) % n);

    if (dt.length < 32) {
      Uint8List padLeadingZero = Uint8List(32 - dt.length);
      dt = Uint8List.fromList(padLeadingZero + dt);
    }

    if (!isPrivate(dt)) return null;
    return dt;
  }

  static Uint8List signEcdsa(Uint8List message, Uint8List secretKey) {
    if (!isScalar(message)) throw ArgumentError(THROW_BAD_HASH);
    if (!isPrivate(secretKey)) throw ArgumentError(THROW_BAD_PRIVATE);
    ECSignature sig = deterministicGenerateK(message, secretKey);
    Uint8List buffer = Uint8List(64);
    buffer.setRange(0, 32, _encodeBigInt(sig.r));
    BigInt s;
    if (sig.s.compareTo(nDiv2) > 0) {
      s = n - sig.s;
    } else {
      s = sig.s;
    }
    buffer.setRange(32, 64, _encodeBigInt(s));
    // print("Signature : ${Codec.encodeHex(buffer)}");
    return buffer;
  }

  static Uint8List signSchnorr(Uint8List message, Uint8List secretKey,
      {Uint8List? auxRand}) {
    if (!isPrivate(secretKey)) throw ArgumentError(THROW_BAD_PRIVATE);
    if (message.length != 32) throw ArgumentError("Message must be 32 bytes");
    if (auxRand != null && auxRand.length != 32) {
      throw ArgumentError("auxRand must be 32 bytes");
    }

    BigInt d0 = fromBuffer(secretKey);
    if (d0 <= BigInt.zero || d0 >= n) {
      throw ArgumentError("Secret key out of range");
    }

    ECPoint? P = G * d0;
    if (P == null || P.isInfinity) {
      throw Exception("Failed to derive public key.");
    }

    Uint8List P_x = getEncoded(P, false).sublist(1, 33);

    Uint8List aux = auxRand ??
        Uint8List.fromList(
            List.generate(32, (_) => Random.secure().nextInt(256)));
    Uint8List t = Uint8List(32);
    Uint8List hashAux = Codec.decodeHex(Hash.taggedHash("BIP0340/aux", aux));
    Uint8List dBytes = toBuffer(d0);
    for (int i = 0; i < 32; i++) {
      t[i] = dBytes[i] ^ hashAux[i];
    }

    Uint8List k0Bytes = Codec.decodeHex(Hash.taggedHash(
        "BIP0340/nonce", Uint8List.fromList([...t, ...P_x, ...message])));
    BigInt k0 = fromBuffer(k0Bytes) % n;
    if (k0 == BigInt.zero) {
      throw Exception(
          "Failure. This happens only with negligible probability.");
    }

    ECPoint? R = G * k0;
    if (R == null || R.isInfinity) {
      throw Exception("Failed to generate R point.");
    }
    if (R.y!.toBigInteger()!.isOdd) {
      k0 = n - k0;
      R = G * k0;
    }

    Uint8List R_x = getEncoded(R, false).sublist(1, 33);

    Uint8List eBytes = Codec.decodeHex(Hash.taggedHash(
        "BIP0340/challenge", Uint8List.fromList([...R_x, ...P_x, ...message])));
    BigInt e = fromBuffer(eBytes) % n;

    BigInt s = (k0 + e * d0) % n;

    // Convert s to hex
    Uint8List sBytes = toBuffer(s);
    if (sBytes.length < 32) {
      Uint8List paddedS = Uint8List(32);
      paddedS.setAll(32 - sBytes.length, sBytes);
      sBytes = paddedS;
    } else if (sBytes.length > 32) {
      throw Exception("s value is too large!");
    }

    Uint8List signature = Uint8List.fromList([...R_x, ...sBytes]);

    // print("Signature: ${Encoder.encodeHex(signature)}");
    // print("Public Key: ${Encoder.encodeHex(getEncoded(P, true))}");
    // print("Message: ${Encoder.encodeHex(msg)}");

    if (!verifySchnorr(message, getEncoded(P, true).sublist(1), signature)) {
      throw Exception("The created signature does not pass verification.");
    }

    return signature;
  }

  static bool verifyEcdsa(
      Uint8List message, Uint8List publicKey, Uint8List signature) {
    if (!isScalar(message)) throw ArgumentError(THROW_BAD_HASH);
    if (!isPoint(publicKey)) throw ArgumentError(THROW_BAD_POINT);
    if (!isSignature(signature)) throw ArgumentError(THROW_BAD_SIGNATURE);

    ECPoint? Q = decodeFrom(publicKey);
    BigInt r = fromBuffer(signature.sublist(0, 32));
    BigInt s = fromBuffer(signature.sublist(32, 64));

    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(false, PublicKeyParameter(ECPublicKey(Q, secp256k1)));

    return signer.verifySignature(message, ECSignature(r, s));
  }

  static bool verifySchnorr(
      Uint8List message, Uint8List publicKey, Uint8List signature) {
    if (!isScalar(message)) throw ArgumentError(THROW_BAD_HASH);
    if (!isPoint(publicKey)) throw ArgumentError(THROW_BAD_POINT);
    if (!isSignature(signature)) throw ArgumentError(THROW_BAD_SIGNATURE);

    Uint8List R_x = signature.sublist(0, 32);
    Uint8List sBytes = signature.sublist(32, 64);
    BigInt s = fromBuffer(sBytes);
    if (s >= n) return false;

    Uint8List pubkeyWithPrefix = Uint8List.fromList([0x02, ...publicKey]);

    ECPoint? P = decodeFrom(pubkeyWithPrefix);
    if (P == null || P.isInfinity) return false;

    Uint8List eBytes = Codec.decodeHex(Hash.taggedHash("BIP0340/challenge",
        Uint8List.fromList([...R_x, ...publicKey, ...message])));
    BigInt e = fromBuffer(eBytes) % n;

    ECPoint? R_prime = (G * s)! + (P * (n - e));
    if (R_prime == null || R_prime.isInfinity) return false;

    Uint8List R_prime_x = getEncoded(R_prime, false).sublist(1, 33);
    bool isValid = R_prime_x.toString() == R_x.toString();
    return isValid;
  }

  /// Decode a BigInt from bytes in big-endian encoding.
  static BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  /// Encode a BigInt into bytes using big-endian encoding.
  static Uint8List _encodeBigInt(BigInt number) {
    var byteMask = BigInt.from(0xff);
    final negativeFlag = BigInt.from(0x80);
    int needsPaddingByte;
    int rawSize;

    if (number > BigInt.zero) {
      rawSize = (number.bitLength + 7) >> 3;
      needsPaddingByte =
          ((number >> (rawSize - 1) * 8) & negativeFlag) == negativeFlag
              ? 1
              : 0;

      if (rawSize < 32) {
        needsPaddingByte = 1;
      }
    } else {
      needsPaddingByte = 0;
      rawSize = (number.bitLength + 8) >> 3;
    }

    final size = rawSize < 32 ? rawSize + needsPaddingByte : rawSize;
    var result = Uint8List(size);
    for (int i = 0; i < size; i++) {
      result[size - i - 1] = (number & byteMask).toInt();
      number = number >> 8;
    }
    return result;
  }

  static BigInt fromBuffer(Uint8List d) {
    return _decodeBigInt(d);
  }

  static Uint8List toBuffer(BigInt d) {
    return _encodeBigInt(d);
  }

  static ECPoint? decodeFrom(Uint8List P) {
    return secp256k1.curve.decodePoint(P);
  }

  static Uint8List getEncoded(ECPoint? P, compressed) {
    return P!.getEncoded(compressed);
  }

  static ECSignature deterministicGenerateK(Uint8List hash, Uint8List x) {
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    var pkp = PrivateKeyParameter(ECPrivateKey(_decodeBigInt(x), secp256k1));
    signer.init(true, pkp);
    return signer.generateSignature(hash) as ECSignature;
  }

  static int _compare(Uint8List a, Uint8List b) {
    BigInt aa = fromBuffer(a);
    BigInt bb = fromBuffer(b);
    if (aa == bb) return 0;
    if (aa > bb) return 1;
    return -1;
  }

  static Uint8List signSchnorrForMuSig2(
      Uint8List message, // 32B
      Uint8List aggregatedPubNonce, // 32B x-only (R.x)
      Uint8List privateKey, // 32B
      Uint8List secretNonce, // 32B
      Uint8List publicKey, // 32B
      List<Uint8List> participantPublicKeys, // List of 32B
      {bool isFullSignature = true} // New parameter to control return format
      ) {
    if (message.length != 32) {
      throw ArgumentError("sighash must be 32 bytes (got ${message.length})");
    }
    if (aggregatedPubNonce.length != 66) {
      throw ArgumentError(
          "aggregatedPubNonce must be 66 bytes (got ${aggregatedPubNonce.length})");
    }
    if (privateKey.length != 32) {
      throw ArgumentError(
          "privateKey must be 32 bytes (got ${privateKey.length})");
    }
    if (secretNonce.length != 97) {
      throw ArgumentError(
          "secret nonce must be 97 bytes (got ${secretNonce.length})");
    }
    if (publicKey.length != 32 && publicKey.length != 33) {
      throw ArgumentError(
          "public key must be 32 or 33 bytes (got ${publicKey.length})");
    }

    if (publicKey.length == 32) {
      publicKey = Uint8List.fromList([0x02, ...publicKey]);
    }

    for (int i = 0; i < participantPublicKeys.length; i++) {
      if (participantPublicKeys[i].length == 32) {
        participantPublicKeys[i][0] = 2;
      } else if (participantPublicKeys[i].length != 33) {
        throw ArgumentError(
            "participantPublicKeys must be 32 or 33 bytes (got ${participantPublicKeys[i].length})");
      }
    }

    //get sessiont context
    Uint8List q = WalletUtility.aggregatePublicKey(
        participantPublicKeys.map((e) => Codec.encodeHex(e)).toList(), false);
    late BigInt b;
    late ECPoint r;
    late BigInt e;

    b = fromBuffer(Codec.decodeHex(Hash.taggedHash(
        "MuSig/noncecoef",
        Uint8List.fromList(
            [...aggregatedPubNonce, ...q.sublist(1), ...message]))));

    final r1 = decodeFrom(aggregatedPubNonce.sublist(0, 33))!;
    final r2 = decodeFrom(aggregatedPubNonce.sublist(33, 66))!;

    r = (r1 + r2 * b)!;

    // Get R_x (32 bytes) from r point
    Uint8List R_x = getEncoded(r, false).sublist(1, 33);

    e = fromBuffer(Codec.decodeHex(Hash.taggedHash("BIP0340/challenge",
        Uint8List.fromList([...R_x, ...q.sublist(1), ...message]))));

    //calculate a
    late BigInt a;
    Uint8List L = Codec.decodeHex(Hash.taggedHash('KeyAgg list',
        Uint8List.fromList(participantPublicKeys.expand((x) => x).toList())));
    late Uint8List secondKey;
    for (int keyIndex = 1;
        keyIndex < participantPublicKeys.length;
        keyIndex++) {
      if (participantPublicKeys[0] != participantPublicKeys[keyIndex]) {
        secondKey = participantPublicKeys[keyIndex];
      }
    }
    if (publicKey == secondKey) {
      a = BigInt.one;
    } else {
      a = fromBuffer(Codec.decodeHex(
              Hash.taggedHash('KeyAgg coefficient', L + publicKey))) %
          n;
    }

    // g
    BigInt g = BigInt.one;
    if (decodeFrom(q)!.y!.toBigInteger()!.isOdd) {
      g = n - BigInt.one;
    }

    //calculate d
    BigInt d = g * fromBuffer(privateKey) % n;

    //calculate s
    BigInt k1 =
        Converter.hexToBigDec(Codec.encodeHex(secretNonce.sublist(0, 32)));
    BigInt k2 =
        Converter.hexToBigDec(Codec.encodeHex(secretNonce.sublist(32, 64)));

    if (r.y!.toBigInteger()!.isOdd) {
      k1 = n - k1;
      k2 = n - k2;
    }

    BigInt s = (k1 + b * k2 + e * a * d) % n;

    // Convert s to hex
    Uint8List sBytes = toBuffer(s);
    if (sBytes.length < 32) {
      Uint8List paddedS = Uint8List(32);
      paddedS.setAll(32 - sBytes.length, sBytes);
      sBytes = paddedS;
    } else if (sBytes.length > 32) {
      throw Exception("s value is too large!");
    }

    if (isFullSignature) {
      // Return R_x || s (64 bytes)
      final signature = Uint8List.fromList([...R_x, ...sBytes]);
      return signature;
    } else {
      // Return only s (32 bytes)
      return sBytes;
    }
  }

  static Uint8List getAggregatedSignatureForMuSig2(
    Uint8List aggregatedPubKey,
    Uint8List aggregatedPubNonce,
    Uint8List message,
    List<Uint8List> signatureList,
  ) {
    if (aggregatedPubKey.length != 32 && aggregatedPubKey.length != 33) {
      throw ArgumentError(
          "public key must be 32 or 33 bytes (got ${aggregatedPubKey.length})");
    }
    if (aggregatedPubNonce.length != 66) {
      throw ArgumentError(
          "aggregatedPubNonce must be 66 bytes (got ${aggregatedPubNonce.length})");
    }
    if (message.length != 32) {
      throw ArgumentError("message must be 32 bytes (got ${message.length})");
    }
    if (aggregatedPubKey.length == 32) {
      aggregatedPubKey = Uint8List.fromList([0x02, ...aggregatedPubKey]);
    }
    late BigInt b;
    late ECPoint r;
    late BigInt e;
    final BigInt tacc = BigInt.from(0);

    b = fromBuffer(Codec.decodeHex(Hash.taggedHash(
        "MuSig/noncecoef",
        Uint8List.fromList([
          ...aggregatedPubNonce,
          ...aggregatedPubKey.sublist(1),
          ...message
        ]))));

    final r1 = decodeFrom(aggregatedPubNonce.sublist(0, 33))!;
    final r2 = decodeFrom(aggregatedPubNonce.sublist(33, 66))!;

    r = (r1 + r2 * b)!;

    // Get R_x (32 bytes) from r point
    Uint8List R_x = getEncoded(r, false).sublist(1, 33);

    e = fromBuffer(Codec.decodeHex(Hash.taggedHash(
        "BIP0340/challenge",
        Uint8List.fromList(
            [...R_x, ...aggregatedPubKey.sublist(1), ...message]))));
    BigInt s = BigInt.zero;
    for (int i = 0; i < signatureList.length; i++) {
      Uint8List signature = signatureList[i];
      if (signature.length == 64) {
        s += fromBuffer(signature.sublist(32, 64));
      } else {
        s += fromBuffer(signature);
      }
      s = s % n;
    }
    BigInt g = BigInt.one;
    if (decodeFrom(aggregatedPubKey)!.y!.toBigInteger()!.isOdd) {
      g = n - BigInt.one;
    }
    s = (s + e * g * tacc) % n;
    return Uint8List.fromList(R_x + Codec.decodeHex(Converter.bigDecToHex(s)));
  }
}
