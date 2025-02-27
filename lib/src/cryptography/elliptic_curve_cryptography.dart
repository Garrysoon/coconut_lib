// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';
import 'package:coconut_lib/src/cryptography/encoder.dart';
import 'package:coconut_lib/src/cryptography/hash.dart';
import 'package:hex/hex.dart';
import "package:pointycastle/ecc/curves/secp256k1.dart";
import "package:pointycastle/api.dart"
    show PrivateKeyParameter, PublicKeyParameter;
import 'package:pointycastle/ecc/api.dart'
    show ECPrivateKey, ECPublicKey, ECSignature, ECPoint;
import "package:pointycastle/signers/ecdsa_signer.dart";
import 'package:pointycastle/macs/hmac.dart';
import "package:pointycastle/digests/sha256.dart";

final ZERO32 = Uint8List.fromList(List.generate(32, (index) => 0));
final EC_GROUP_ORDER = HEX
    .decode("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
final EC_P = HEX
    .decode("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f");
final secp256k1 = ECCurve_secp256k1();
final n = secp256k1.n;
final G = secp256k1.G;
BigInt nDiv2 = n >> 1;
const THROW_BAD_PRIVATE = 'Expected Private';
const THROW_BAD_POINT = 'Expected Point';
const THROW_BAD_TWEAK = 'Expected Tweak';
const THROW_BAD_HASH = 'Expected Hash';
const THROW_BAD_SIGNATURE = 'Expected Signature';

bool isPrivate(Uint8List x) {
  if (!isScalar(x)) return false;
  return _compare(x, ZERO32) > 0 && // > 0
      _compare(x, EC_GROUP_ORDER as Uint8List) < 0; // < G
}

bool isPoint(Uint8List p) {
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

bool isScalar(Uint8List x) {
  return x.length == 32;
}

bool isOrderScalar(x) {
  if (!isScalar(x)) return false;
  return _compare(x, EC_GROUP_ORDER as Uint8List) < 0; // < G
}

bool isSignature(Uint8List value) {
  Uint8List r = value.sublist(0, 32);
  Uint8List s = value.sublist(32, 64);

  return value.length == 64 &&
      _compare(r, EC_GROUP_ORDER as Uint8List) < 0 &&
      _compare(s, EC_GROUP_ORDER as Uint8List) < 0;
}

bool _isPointCompressed(Uint8List p) {
  return p[0] != 0x04;
}

bool assumeCompression(bool? value, Uint8List? pubkey) {
  if (value == null && pubkey != null) return _isPointCompressed(pubkey);
  if (value == null) return true;
  return value;
}

Uint8List? pointFromScalar(Uint8List d, bool compressed) {
  if (!isPrivate(d)) throw ArgumentError(THROW_BAD_PRIVATE);
  BigInt dd = fromBuffer(d);
  ECPoint pp = (G * dd) as ECPoint;
  if (pp.isInfinity) return null;
  return getEncoded(pp, compressed);
}

Uint8List? pointAddScalar(Uint8List p, Uint8List tweak, bool isCompressed) {
  if (!isPoint(p)) throw ArgumentError(THROW_BAD_POINT);
  if (!isOrderScalar(tweak)) throw ArgumentError(THROW_BAD_TWEAK);

  Uint8List adjustedP = (p.length == 32) ? Uint8List.fromList([0x02, ...p]) : p;
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

Uint8List? pointNegate(Uint8List p) {
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

Uint8List? privateAdd(Uint8List d, Uint8List tweak) {
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

Uint8List? privateNegate(Uint8List d) {
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

Uint8List sign(Uint8List hash, Uint8List x,
    {isSchnorr = false, Uint8List? auxRand}) {
  if (isSchnorr) {
    return _signSchnorr(hash, x, auxRand: auxRand);
  } else {
    return _signECDSA(hash, x);
  }
}

Uint8List _signECDSA(Uint8List hash, Uint8List x) {
  if (!isScalar(hash)) throw ArgumentError(THROW_BAD_HASH);
  if (!isPrivate(x)) throw ArgumentError(THROW_BAD_PRIVATE);
  ECSignature sig = deterministicGenerateK(hash, x);
  Uint8List buffer = Uint8List(64);
  buffer.setRange(0, 32, _encodeBigInt(sig.r));
  BigInt s;
  if (sig.s.compareTo(nDiv2) > 0) {
    s = n - sig.s;
  } else {
    s = sig.s;
  }
  buffer.setRange(32, 64, _encodeBigInt(s));
  return buffer;
}

//
Uint8List _signSchnorr(Uint8List msg, Uint8List seckey, {Uint8List? auxRand}) {
  if (!isPrivate(seckey)) throw ArgumentError(THROW_BAD_PRIVATE);
  if (msg.length != 32) throw ArgumentError("Message must be 32 bytes");
  if (auxRand != null && auxRand.length != 32) {
    throw ArgumentError("auxRand must be 32 bytes");
  }

  BigInt d0 = fromBuffer(seckey);
  if (d0 <= BigInt.zero || d0 >= n) {
    throw ArgumentError("Secret key out of range");
  }

  ECPoint? P = G * d0;
  if (P == null || P.isInfinity) {
    throw Exception("Failed to derive public key.");
  }

  Uint8List P_x = getEncoded(P, false).sublist(1, 33);

  Uint8List aux = auxRand ?? Uint8List(32);
  Uint8List t = Uint8List(32);
  Uint8List hashAux = Encoder.decodeHex(Hash.taggedHash("BIP0340/aux", aux));
  Uint8List dBytes = toBuffer(d0);
  for (int i = 0; i < 32; i++) {
    t[i] = dBytes[i] ^ hashAux[i];
  }

  Uint8List k0Bytes = Encoder.decodeHex(Hash.taggedHash(
      "BIP0340/nonce", Uint8List.fromList([...t, ...P_x, ...msg])));
  BigInt k0 = fromBuffer(k0Bytes) % n;
  if (k0 == BigInt.zero) {
    throw Exception("Failure. This happens only with negligible probability.");
  }

  ECPoint? R = G * k0;
  if (R == null || R.isInfinity) throw Exception("Failed to generate R point.");

  Uint8List R_x = getEncoded(R, false).sublist(1, 33);

  Uint8List eBytes = Encoder.decodeHex(Hash.taggedHash(
      "BIP0340/challenge", Uint8List.fromList([...R_x, ...P_x, ...msg])));
  BigInt e = fromBuffer(eBytes) % n;

  BigInt s = (k0 + e * d0) % n;

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

  if (!verify(msg, getEncoded(P, true).sublist(1), signature,
          isSchnorr: true, parity: 0) &&
      !verify(msg, getEncoded(P, true).sublist(1), signature,
          isSchnorr: true, parity: 1)) {
    throw Exception("The created signature does not pass verification.");
  }

  return signature;
}

bool verify(Uint8List msg, Uint8List q, Uint8List signature,
    {bool isSchnorr = false, int? parity}) {
  if (!isScalar(msg)) throw ArgumentError(THROW_BAD_HASH);
  if (!isPoint(q)) throw ArgumentError(THROW_BAD_POINT);
  if (!isSignature(signature)) throw ArgumentError(THROW_BAD_SIGNATURE);

  if (isSchnorr) {
    if (parity == null) {
      throw ArgumentError(
          "parity must be provided for schnorr signature verification");
    }
    Uint8List R_x = signature.sublist(0, 32);
    Uint8List sBytes = signature.sublist(32, 64);
    BigInt s = fromBuffer(sBytes);
    if (s >= n) return false;

    Uint8List pubkeyWithPrefix = Uint8List.fromList([0x02, ...q]);
    if (parity == 1) {
      pubkeyWithPrefix = Uint8List.fromList([0x03, ...q]);
    }
    ECPoint? P = decodeFrom(pubkeyWithPrefix);
    if (P == null || P.isInfinity) return false;

    Uint8List eBytes = Encoder.decodeHex(Hash.taggedHash(
        "BIP0340/challenge", Uint8List.fromList([...R_x, ...q, ...msg])));
    BigInt e = fromBuffer(eBytes) % n;

    ECPoint? R_prime = (G * s)! + (P * (n - e));
    if (R_prime == null || R_prime.isInfinity) return false;

    Uint8List R_prime_x = getEncoded(R_prime, false).sublist(1, 33);
    bool isValid = R_prime_x.toString() == R_x.toString();
    return isValid;
  } else {
    ECPoint? Q = decodeFrom(q);
    BigInt r = fromBuffer(signature.sublist(0, 32));
    BigInt s = fromBuffer(signature.sublist(32, 64));

    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(false, PublicKeyParameter(ECPublicKey(Q, secp256k1)));

    return signer.verifySignature(msg, ECSignature(r, s));
  }
}

/// Decode a BigInt from bytes in big-endian encoding.
BigInt _decodeBigInt(List<int> bytes) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

/// Encode a BigInt into bytes using big-endian encoding.
Uint8List _encodeBigInt(BigInt number) {
  var byteMask = BigInt.from(0xff);
  final negativeFlag = BigInt.from(0x80);
  int needsPaddingByte;
  int rawSize;

  if (number > BigInt.zero) {
    rawSize = (number.bitLength + 7) >> 3;
    needsPaddingByte =
        ((number >> (rawSize - 1) * 8) & negativeFlag) == negativeFlag ? 1 : 0;

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

BigInt fromBuffer(Uint8List d) {
  return _decodeBigInt(d);
}

Uint8List toBuffer(BigInt d) {
  return _encodeBigInt(d);
}

ECPoint? decodeFrom(Uint8List P) {
  return secp256k1.curve.decodePoint(P);
}

Uint8List getEncoded(ECPoint? P, compressed) {
  return P!.getEncoded(compressed);
}

ECSignature deterministicGenerateK(Uint8List hash, Uint8List x) {
  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  var pkp = PrivateKeyParameter(ECPrivateKey(_decodeBigInt(x), secp256k1));
  signer.init(true, pkp);
  return signer.generateSignature(hash) as ECSignature;
}

int _compare(Uint8List a, Uint8List b) {
  BigInt aa = fromBuffer(a);
  BigInt bb = fromBuffer(b);
  if (aa == bb) return 0;
  if (aa > bb) return 1;
  return -1;
}
