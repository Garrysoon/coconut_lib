import 'dart:typed_data';
part of '../../coconut_lib.dart';

/// Represents a MuSig2 signing session.
class MuSig2Session {
  final List<String> _publicKeys;
  final int _requiredSignatures;
  final Map<String, Uint8List> _nonces = {};
  final Map<String, Uint8List> _partialSignatures = {};
  Uint8List? _aggregatedPublicKey;
  Uint8List? _messageHash;

  /// Create a new MuSig2 session.
  MuSig2Session(this._publicKeys, this._requiredSignatures) {
    if (_publicKeys.length != _requiredSignatures) {
      throw Exception(
          'The number of public keys must equal the required signatures in MuSig2');
    }
  }

  /// Generate a nonce for a specific public key.
  Uint8List generateNonce(String publicKey) {
    if (!_publicKeys.contains(publicKey)) {
      throw Exception('Public key not part of the MuSig2 session');
    }

    // Generate a random 32-byte nonce
    Uint8List nonce = Uint8List(32);
    Random().nextBytes(nonce);
    _nonces[publicKey] = nonce;
    return nonce;
  }

  /// Add a partial signature from a participant.
  void addPartialSignature(String publicKey, Uint8List signature) {
    if (!_publicKeys.contains(publicKey)) {
      throw Exception('Public key not part of the MuSig2 session');
    }
    if (!_nonces.containsKey(publicKey)) {
      throw Exception('Nonce not generated for this public key');
    }
    _partialSignatures[publicKey] = signature;
  }

  /// Set the message hash to be signed.
  void setMessageHash(Uint8List messageHash) {
    _messageHash = messageHash;
  }

  /// Get the aggregated public key for this session.
  Uint8List getAggregatedPublicKey() {
    if (_aggregatedPublicKey != null) {
      return _aggregatedPublicKey!;
    }

    // Aggregate public keys using the same logic as in MultisignatureWalletBase
    List<Uint8List> publicKeysBytes =
        _publicKeys.map((e) => Codec.decodeHex(e)).toList();
    String concatenatedPublicKey = _publicKeys.join();

    Uint8List Q = publicKeysBytes[0];
    for (int i = 0; i < publicKeysBytes.length; i++) {
      Uint8List coefficient = Uint8List(0);
      if (i == 0) {
        coefficient = Uint8List.fromList(List<int>.generate(
            32,
            (i) => int.parse(
                BigInt.one
                    .toRadixString(16)
                    .padLeft(64, '0')
                    .substring(i * 2, i * 2 + 2),
                radix: 16)));
      } else {
        String data = Hash.taggedHash(
                'KeyAgg list', Codec.decodeHex(concatenatedPublicKey)) +
            Codec.encodeHex(publicKeysBytes[i]);
        coefficient = Codec.decodeHex(
            Hash.taggedHash('KeyAgg coefficient', Codec.decodeHex(data)));
      }

      if (i == 0) {
        Q = Ecc.pointMultiplyScalar(publicKeysBytes[i], coefficient, true)!;
      } else {
        Q = Ecc.pointCombine(
            Q,
            Ecc.pointMultiplyScalar(publicKeysBytes[i], coefficient, true)!,
            true)!;
      }
    }

    _aggregatedPublicKey = Q;
    return Q;
  }

  /// Verify if all required partial signatures are present.
  bool hasAllPartialSignatures() {
    return _partialSignatures.length == _requiredSignatures;
  }

  /// Get the final aggregated signature if all partial signatures are present.
  Uint8List? getAggregatedSignature() {
    if (!hasAllPartialSignatures() || _messageHash == null) {
      return null;
    }

    // TODO: Implement signature aggregation according to MuSig2 spec
    // This will involve:
    // 1. Verifying all partial signatures
    // 2. Combining the partial signatures using the appropriate coefficients
    // 3. Applying the final tweak to the aggregated signature

    return null; // Placeholder
  }
}
