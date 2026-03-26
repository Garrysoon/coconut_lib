part of '../../coconut_lib.dart';

abstract class TaprootWalletBase extends WalletBase {
  final List<KeyStore> _keyStoreList;
  final List<Policy> _policyList;
  final bool _isVault;

  /// Get the list of keyStores.
  List<KeyStore> get keyStoreList => _keyStoreList;

  /// Check if this is a vault.
  bool get isVault => _isVault;

  /// Get the list of miniscripts.
  List<Policy> get policyList => _policyList;

  /// @nodoc
  TaprootWalletBase(this._keyStoreList, this._policyList,
      String _derivationPath, this._isVault)
      : super(AddressType.p2tr, _derivationPath) {
    if (!_addressType.isTaproot) {
      throw Exception('Address type must be Taproot.');
    }

    _keyStoreList
        .sort((a, b) => a.masterFingerprint.compareTo(b.masterFingerprint));

    for (KeyStore keyStore in _keyStoreList) {
      if (NetworkType.currentNetworkType.isTestnet !=
          AddressType.isTestnetVersion(keyStore.extendedPublicKey.version)) {
        throw Exception('Network type mismatch.');
      }
    }

    // Check derivation path
    final segments = derivationPath.split('/');
    if (segments.length < 3 || segments[0] != 'm') {
      throw Exception('Invalid derivation path.');
    }
    final coinTypeSegment = segments[2];

    final coinType =
        int.tryParse(coinTypeSegment.replaceAll(RegExp(r"[h']"), ""));

    if (coinType == 1 && !NetworkType.currentNetworkType.isTestnet) {
      throw Exception('Invalid derivation path.');
    } else if (coinType == 0 && NetworkType.currentNetworkType.isTestnet) {
      throw Exception('Invalid derivation path.');
    }

    _descriptor = Descriptor.forTaproot(_addressType, _keyStoreList,
        _policyList, _derivationPath.replaceAll("m/", ""));
  }

  /// Get the address of the given index.
  @override
  String getAddress(int addressIndex, {bool isChange = false}) {
    Uint8List internalKey =
        getAggregatedPublicKey(addressIndex, isChange: isChange, isXOnly: true);
    Uint8List merkleRoot = Uint8List(0);

    if (_policyList.isNotEmpty) {
      merkleRoot = getMerkleRoot(addressIndex, isChange: isChange);
    }
    return _addressType.getTaprootAddress(Codec.encodeHex(internalKey),
        merkleRoot: Codec.encodeHex(merkleRoot));
  }

  @override
  String getAddressWithDerivationPath(String derivationPath) {
    if (!WalletUtility.validateDerivationPath(_derivationPath)) {
      throw Exception("Invalid derivation path (e.g., m/44'/0'/0'/0/0)");
    }

    if (!derivationPath.startsWith(_derivationPath)) {
      throw Exception("Derivation path does not match");
    }
    int addressIndex =
        WalletUtility.getAccountIndexFromDerivationPath(derivationPath);
    bool isChange = WalletUtility.isChangeFromDerivationPath(derivationPath);
    return getAddress(addressIndex, isChange: isChange);
  }

  @override
  String getKeyOriginExpression() {
    List<String> keyOriginExpressionList = [];
    for (KeyStore keyStore in keyStoreList) {
      keyOriginExpressionList
          .add(Descriptor.getKeyOriginExpression(keyStore, derivationPath));
    }
    return keyOriginExpressionList.join(',');
  }

  @override
  bool hasPublicKeyInPsbt(String psbt) {
    return _keyStoreList.any((keyStore) => keyStore.hasPublicKeyInPsbt(psbt));
  }

  @override
  String addSignatureToPsbt(String psbt) {
    Psbt psbtObject = Psbt.parse(psbt);
    if (psbtObject.addressType != addressType) {
      throw Exception('Address Type is not matched.');
    }

    if (psbtObject.inputs.length !=
        psbtObject.unsignedTransaction!.inputs.length) {
      throw Exception('Not enought psbt inputs or transaction inputs');
    }

    for (int inputIndex = 0;
        inputIndex < psbtObject.inputs.length;
        inputIndex++) {
      //in every input
      PsbtInput psbtInput = psbtObject.inputs[inputIndex];
      if (psbtInput.requiredSignature <= psbtInput.signedCount) {
        continue;
      }
      //get sigHash
      late String sigHash;
      MuSig2SessionContext? sessionContext;
      if (!addressType.isTaproot) {
        //ECDSA
        if (addressType != AddressType.p2wsh) {
          throw Exception('Not support witness script for this address type.');
        }
        TransactionOutput utxo = psbtInput.witnessUtxo!;
        String? witnessScript = psbtInput.witnessScript!.rawSerialize();
        sigHash = psbtObject.unsignedTransaction!.getSigHash(
            inputIndex, utxo, addressType,
            witnessScript: witnessScript);
      } else {
        //Taproot
        if (addressType != AddressType.p2tr) {
          throw Exception('Not support witness script for this address type.');
        }
        List<TransactionOutput> utxoList = [];
        for (int j = 0;
            j < psbtObject.unsignedTransaction!.inputs.length;
            j++) {
          utxoList.add(psbtObject.inputs[j].witnessUtxo!);
        }
        sigHash = psbtObject.unsignedTransaction!
            .getTaprootSigHash(inputIndex, utxoList);

        sessionContext = MuSig2SessionContext(
            psbtInput.muSig2ParticipantPubkeys!
                .map((e) => Codec.decodeHex(e))
                .toList(),
            Codec.decodeHex(psbtInput.getAggregatedPublicNonce()),
            Codec.decodeHex(psbtInput.muSig2AggregatedPublicKey!),
            Codec.decodeHex(sigHash),
            applyTaprootTweak: true);
      }

      List<DerivationPath>? derivationPathList;
      if (!addressType.isTaproot) {
        derivationPathList = psbtInput.bip32Derivation;
      } else {
        derivationPathList = psbtInput.tapBip32Derivation;
      }
      for (DerivationPath derivationPath in derivationPathList!) {
        if (psbtInput.requiredSignature <= psbtInput.signedCount) {
          break;
        }
        for (KeyStore keyStore in keyStoreList) {
          if (!keyStore.hasSeed) {
            continue;
          }
          if (derivationPath.masterFingerprint == keyStore.masterFingerprint) {
            // print("add signature to psbt ${keyStore.seed.passphrase}");
            keyStore.addSignatureToPsbtInput(
                psbtInput, addressType, derivationPath.path, sigHash,
                aggregatedPublicKey: psbtInput.muSig2AggregatedPublicKey!,
                sessionContext: sessionContext);
            break;
          }
        }
      }
    }
    return psbtObject.serialize();
  }

  String getCoordinatorBsms() {
    Bsms bsms = Bsms(
        coordinator: Coordinator(getAddress(0), Descriptor.parse(descriptor)));
    return bsms.serializeCoordinator();
  }

  Uint8List getAggregatedPublicKey(int addressIndex,
      {bool isChange = false, isXOnly = false}) {
    List<Uint8List> publicKeyList = _keyStoreList
        .map((keyStore) => keyStore.getPublicKeyBytes(addressIndex,
            isChange: isChange, isXOnly: false))
        .toList();
    Uint8List aggregatedPublicKey = WalletUtility.aggregatePublicKey(
        publicKeyList,
        isSort: true,
        isXOnly: isXOnly);
    return aggregatedPublicKey;
  }

  Uint8List getMerkleRoot(int addressIndex, {bool isChange = false}) {
    if (_policyList.isEmpty) {
      return Uint8List(0);
    }
    List<Uint8List> leafHashes = [];
    for (Policy policy in _policyList) {
      Uint8List leafHash = _getTapleafHash(
          0xc0, policy.toScript(addressIndex, isChange: isChange).serialize());
      leafHashes.add(leafHash);
    }
    return _calculateMerkleRoot(leafHashes);
  }

  static Uint8List _calculateMerkleRoot(List<Uint8List> leafHashes) {
    // 단일 leaf인 경우 해당 leaf hash를 반환
    if (leafHashes.length == 1) {
      return leafHashes[0];
    }

    // Merkle tree 구성
    List<Uint8List> currentLevel =
        leafHashes.map((e) => Uint8List.fromList(e)).toList();

    while (currentLevel.length > 1) {
      final List<Uint8List> nextLevel = [];

      for (int i = 0; i < currentLevel.length; i += 2) {
        if (i + 1 == currentLevel.length) {
          // 홀수 개인 경우 마지막 요소를 그대로 전달
          nextLevel.add(currentLevel[i]);
          continue;
        }

        final left = currentLevel[i];
        final right = currentLevel[i + 1];
        nextLevel.add(_tapBranchHash(left, right));
      }

      currentLevel = nextLevel;
    }

    return currentLevel.first;
  }

  static Uint8List _tapBranchHash(Uint8List a, Uint8List b) {
    final compare = _lexicographicCompare(a, b);
    final first = compare <= 0 ? a : b;
    final second = compare <= 0 ? b : a;

    return _taggedHash('TapBranch', _concat(first, second));
  }

  static int _lexicographicCompare(Uint8List a, Uint8List b) {
    final minLen = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLen; i++) {
      if (a[i] != b[i]) {
        return a[i] < b[i] ? -1 : 1;
      }
    }
    if (a.length == b.length) return 0;
    return a.length < b.length ? -1 : 1;
  }

  static Uint8List _concat(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length + b.length);
    out.setRange(0, a.length, a);
    out.setRange(a.length, a.length + b.length, b);
    return out;
  }

  static Uint8List _getTapleafHash(int version, String script) {
    Uint8List scriptBytes = Codec.decodeHex(script);
    Uint8List scriptSize = _encodeCompactSize(scriptBytes.length);
    Uint8List tapleafHash = _taggedHash(
        "TapLeaf", Uint8List.fromList([version] + scriptSize + scriptBytes));
    return tapleafHash;
  }

  /// Encode compact size for script serialization.
  static Uint8List _encodeCompactSize(int size) {
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

  /// Calculate tagged hash (BIP-340 style).
  static Uint8List _taggedHash(String tag, Uint8List data) {
    Uint8List tagHash =
        Hash.sha256fromByte(Uint8List.fromList(utf8.encode(tag)));
    Uint8List prefix = Uint8List.fromList(tagHash + tagHash);
    return Hash.sha256fromByte(Uint8List.fromList(prefix + data));
  }
}
