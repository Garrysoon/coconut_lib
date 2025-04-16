part of '../../coconut_lib.dart';

/// Key Store is consist of fingerprint, exPub and seed.
class KeyStore {
  String _masterFingerprint;
  HDWallet _hdWallet;
  HDWallet _hdWalletReceive;
  HDWallet _hdWalletChange;
  ExtendedPublicKey _extendedPublicKey;
  Seed? _seed;

  /// The fingerprint of the key store.
  String get masterFingerprint => _masterFingerprint;

  HDWallet get hdWallet => _hdWallet;

  /// @nodoc
  HDWallet getChildHdWallet(bool isChange) =>
      isChange ? _hdWalletChange : _hdWalletReceive;

  /// The extended public key of the key store.
  ExtendedPublicKey get extendedPublicKey => _extendedPublicKey;

  /// The seed of the key store.
  Seed get seed => _seed!;

  /// Set the seed of the key store.
  set seed(Seed? seed) {
    _seed = seed;
  }

  /// Check if the key store has seed.
  bool get hasSeed => _seed != null;

  /// @nodoc
  KeyStore(this._masterFingerprint, this._hdWallet, this._extendedPublicKey,
      [this._seed])
      : _hdWalletReceive = _hdWallet.derive(0),
        _hdWalletChange = _hdWallet.derive(1);

  /// Create a key store from a seed.
  factory KeyStore.fromSeed(Seed seed, AddressType addressType,
      {int accountIndex = 0}) {
    bool isTestnet = NetworkType.currentNetworkType.isTestnet;
    HDWallet rootWallet = HDWallet.fromRootSeed(seed.rootSeed);
    String fingerprint = Codec.encodeHex(rootWallet.fingerprint).toUpperCase();

    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    HDWallet wallet = rootWallet.derivePath(derivationPath);
    int version = isTestnet
        ? addressType.versionForTestnet
        : addressType.versionForMainnet;
    ExtendedPublicKey extendedPublicKey = ExtendedPublicKey.fromHdWallet(
        wallet, version, wallet.parentFingerprint);
    return KeyStore(fingerprint, wallet, extendedPublicKey, seed);
  }

  /// Create a key store from a mnemonic.
  factory KeyStore.fromMnemonic(String mnemonicWords, AddressType addressType,
      {String passphrase = '', int accountIndex = 0}) {
    Seed seed = Seed.fromMnemonic(mnemonicWords, passphrase: passphrase);

    return KeyStore.fromSeed(seed, addressType, accountIndex: accountIndex);
  }

  /// Create a key store from a random.
  factory KeyStore.random(AddressType addressType,
      {int mnemonicLength = 24, String passphrase = '', int accountIndex = 0}) {
    if (mnemonicLength != 12 &&
        mnemonicLength != 15 &&
        mnemonicLength != 18 &&
        mnemonicLength != 21 &&
        mnemonicLength != 24) {
      throw Exception('MnemonicLength must be 12, 15, 18, 21, or 24.');
    }

    Seed seed =
        Seed.random(mnemonicLength: mnemonicLength, passphrase: passphrase);
    return KeyStore.fromSeed(seed, addressType, accountIndex: accountIndex);
  }

  /// Create a key store from a entropy.
  factory KeyStore.fromEntropy(String entropy, AddressType addressType,
      {String passphrase = '', int accountIndex = 0}) {
    Seed seed = Seed.fromHexadecimalEntropy(entropy, passphrase: passphrase);
    return KeyStore.fromSeed(seed, addressType, accountIndex: accountIndex);
  }

  factory KeyStore.fromExtendedPublicKey(String extendedPublicKey) {
    ExtendedPublicKey exPub = ExtendedPublicKey.parse(extendedPublicKey);
    HDWallet wallet = HDWallet.fromPublicKey(exPub.publicKey, exPub.chainCode);
    return KeyStore(exPub.parentFingerprint, wallet, exPub);
  }

  factory KeyStore.fromSignerBsms(String signer) {
    Bsms bsms = Bsms.parseSigner(signer);
    // KeyStore(fingerprint, wallet, extendedPublicKey)
    HDWallet wallet = HDWallet.fromPublicKey(
        bsms.signer!.extendedPublicKey.publicKey,
        bsms.signer!.extendedPublicKey.chainCode);
    return KeyStore(
        bsms.signer!.masterFingerPrint, wallet, bsms.signer!.extendedPublicKey);
  }

  /// Get the private key of the key store using index.
  String getPrivateKey(int index,
      {bool isChange = false,
      bool applyTweak = false,
      bool isXOnly = false,
      Uint8List? merkleRoot,
      Uint8List? aggregatedPublicKey}) {
    if (!hasSeed) throw Exception('No private key in this key store');
    HDWallet child = getChildHdWallet(isChange).derive(index);
    Uint8List privKey = child.getPrivateKey(applyTweak, isXOnly,
        merkleRoot: merkleRoot, aggregatedPublicKey: aggregatedPublicKey);
    return Codec.encodeHex(privKey);

    // if (applyTweak) {
    //   privKey = child.getTweakedPrivateKey(
    //       merkleRoot: merkleRoot, aggregatedPublicKey: aggregatedPublicKey);
    // } else {
    //   privKey = child.privateKey!;
    // }
  }

//sign.
  // String sign(String message, int addressIndex,
  //     {bool isChange = false, isSchnorr = false}) {
  //   if (!hasSeed) throw Exception('No private key in this key store');
  //   HDWallet child = getChildHdWallet(isChange).derive(addressIndex);
  //   Uint8List signature = child.sign(Uint8List.fromList(HEX.decode(message)),
  //       isShnorr: isSchnorr);
  //   String sig;
  //   if (!isSchnorr) {
  //     // String r = Codec.encodeHex(signature.sublist(0, 32));
  //     // if (int.parse(r.substring(0, 2), radix: 16) & 0x80 != 0) {
  //     //   r = '00$r';
  //     // }
  //     // String rLength = Converter.decToHex(r.length ~/ 2);
  //     // String s = Codec.encodeHex(signature.sublist(32, 64));
  //     // String sLength = Converter.decToHex(s.length ~/ 2);
  //     // String rs = '02$rLength${r}02$sLength$s';
  //     // sig = '30${Converter.decToHex(rs.length ~/ 2)}${rs}01';
  //     sig = Codec.encodeHex(Converter.rawToDerSignature(signature));
  //   } else {
  //     sig = Codec.encodeHex(signature);
  //   }
  //   return sig;
  // }

//sign with derivation path.
  // String signWithDerivationPath(String message, String derivationPath,
  //     {bool isSchnorr = false}) {
  //   if (!WalletUtility.validateDerivationPath(derivationPath)) {
  //     throw Exception('Invalid derivation path');
  //   }
  //   List<String> pathList = derivationPath.split('/');
  //   int index = int.parse(pathList.last);
  //   int changeIndex = int.parse(pathList[pathList.length - 2]);
  //   return sign(message, index,
  //       isChange: changeIndex == 1, isSchnorr: isSchnorr);
  // }

  /// Get the public key of the key store using index.
  String getPublicKey(int addressIndex,
      {bool isChange = false,
      isXOnly = false,
      applyTweak = false,
      Uint8List? merkleRoot,
      Uint8List? aggregatedPublicKey}) {
    HDWallet child = getChildHdWallet(isChange).derive(addressIndex).neutered();

    Uint8List publicKey = child.getPublicKey(applyTweak, isXOnly,
        merkleRoot: merkleRoot, aggregatedPublicKey: aggregatedPublicKey);

    return Codec.encodeHex(publicKey);
    // if (isXOnly) {
    // if (applyTweak) {
    //   pubKey = child.getTweakedPublicKey(
    //       merkleRoot: merkleRoot, aggregatedPublicKey: aggregatedPublicKey);
    // } else {
    //   pubKey = child.publicKey;
    // }
    // if (isXOnly) {
    //   return Codec.encodeHex(pubKey.sublist(1));
    // } else {
    //   return Codec.encodeHex(pubKey);
    // }
  }

  ///Check if the PSBT can be signed from this vault.
  bool canSignToPsbt(String psbt) {
    Psbt psbtObj = Psbt.parse(psbt);

    if (psbtObj.inputs[0].bip32Derivation != null) {
      for (int i = 0; i < psbtObj.unsignedTransaction!.inputs.length; i++) {
        PsbtInput thisInput = psbtObj.inputs[i];
        for (int j = 0; j < thisInput.derivationPathList.length; j++) {
          String publicKeyInPsbt = thisInput.derivationPathList[j].publicKey;
          String publicKey = getPublicKey(
              thisInput.derivationPathList[j].accountIndex,
              isChange: thisInput.derivationPathList[j].isChange);
          if (publicKeyInPsbt.length != publicKey.length) {
            publicKey = publicKey.substring(2);
          }
          if (thisInput.derivationPathList[j].masterFingerprint ==
                  masterFingerprint &&
              publicKeyInPsbt == publicKey) {
            return true;
          }
        }
      }
      return false;
    } else if (psbtObj.inputs[0].tapBip32Derivation != null) {
      // taproot
      for (int i = 0; i < psbtObj.unsignedTransaction!.inputs.length; i++) {
        PsbtInput thisInput = psbtObj.inputs[i];
        for (int j = 0; j < thisInput.tapBip32Derivation!.length; j++) {
          String publicKeyInPsbt = thisInput.tapBip32Derivation![j].publicKey;
          String publicKey = getPublicKey(
              thisInput.tapBip32Derivation![j].accountIndex,
              isChange: thisInput.tapBip32Derivation![j].isChange);
          if (publicKeyInPsbt.length != publicKey.length) {
            publicKey = publicKey.substring(2);
          }
          if (thisInput.tapBip32Derivation![j].masterFingerprint ==
                  masterFingerprint &&
              publicKeyInPsbt == publicKey) {
            return true;
          }
        }
      }
      return false;
    } else {
      throw Exception("Derivation path is not included in psbt.");
    }
  }

  String addMuSig2PublicNonceToPsbt(String psbt) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed');
    }
    Psbt psbtObject = Psbt.parse(psbt);
    if (psbtObject.addressType != AddressType.p2trMuSig2) {
      throw Exception('Only musig2 needs public nonce.');
    }
    if (canSignToPsbt(psbtObject.serialize()) == false) {
      throw Exception('This vault can not sign this PSBT');
    }
    if (psbtObject.inputs.length !=
        psbtObject.unsignedTransaction!.inputs.length) {
      throw Exception('Not enought psbt inputs or transaction inputs');
    }

    List<TransactionOutput> utxoList = [];
    for (int j = 0; j < psbtObject.unsignedTransaction!.inputs.length; j++) {
      utxoList.add(psbtObject.inputs[j].witnessUtxo!);
    }
    // add nonce every input
    for (int inputIndex = 0;
        inputIndex < psbtObject.unsignedTransaction!.inputs.length;
        inputIndex++) {
      PsbtInput psbtInput = psbtObject.inputs[inputIndex];

      String sigHash = psbtObject.unsignedTransaction!
          .getTaprootSigHash(inputIndex, utxoList);
      String derivationPath = psbtInput.derivationPathList[inputIndex].path;
      int accountIndex =
          WalletUtility.getAccountIndexFromDerivationPath(derivationPath);
      bool isChange = WalletUtility.isChangeFromDerivationPath(derivationPath);
      String publicKey = getPublicKey(accountIndex, isChange: isChange);
      if (publicKey != getPublicKey(accountIndex, isChange: isChange)) {
        continue;
      }
      String publicNonce = getMuSig2PublicNonce(
          sigHash,
          psbtObject.inputs[inputIndex].muSig2AggregatedPublicKey!,
          accountIndex,
          isChange);
      psbtObject.addMuSig2PubNonce(inputIndex, publicKey, publicNonce);
    }
    return psbtObject.serialize();
  }

  ///add signature to PSBT if it's possible.
  String addSignatureToPsbt(String psbt, AddressType addressType) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed.');
    }
    Psbt psbtObject = Psbt.parse(psbt);
    if (psbtObject.addressType != addressType) {
      throw Exception('Address Type is not matched.');
    }
    if (canSignToPsbt(psbtObject.serialize()) == false) {
      throw Exception('This vault can not sign this PSBT');
    }
    if (psbtObject.inputs.length !=
        psbtObject.unsignedTransaction!.inputs.length) {
      throw Exception('Not enought psbt inputs or transaction inputs');
    }

    for (int inputIndex = 0;
        inputIndex < psbtObject.unsignedTransaction!.inputs.length;
        inputIndex++) {
      PsbtInput psbtInput = psbtObject.inputs[inputIndex];

      if (psbtInput.requiredSignature <= psbtInput.signedCount) {
        continue;
      }

      // 1. Generate sig hash
      late String sigHash;

      if (!addressType.isTaproot) {
        // ECDSA
        TransactionOutput utxo = psbtInput.witnessUtxo!;
        if (addressType == AddressType.p2wsh) {
          String? witnessScript = psbtInput.witnessScript!.rawSerialize();
          sigHash = psbtObject.unsignedTransaction!.getSigHash(
              inputIndex, utxo, addressType,
              witnessScript: witnessScript);
        } else {
          sigHash = psbtObject.unsignedTransaction!
              .getSigHash(inputIndex, utxo, addressType);
        }
      } else {
        // Taproot
        List<TransactionOutput> utxoList = [];
        for (int j = 0;
            j < psbtObject.unsignedTransaction!.inputs.length;
            j++) {
          utxoList.add(psbtObject.inputs[j].witnessUtxo!);
        }
        sigHash = psbtObject.unsignedTransaction!
            .getTaprootSigHash(inputIndex, utxoList);
      }

      // 2. Calculate signatures and get public keys

      Map<String, String> signatureMap = {};
      for (int pathIndex = 0;
          pathIndex < psbtInput.derivationPathList.length;
          pathIndex++) {
        if (psbtInput.derivationPathList[pathIndex].masterFingerprint !=
            masterFingerprint) {
          continue;
        }
        String derivationPath = psbtInput.derivationPathList[pathIndex].path;
        int accountIndex =
            WalletUtility.getAccountIndexFromDerivationPath(derivationPath);
        bool isChange =
            WalletUtility.isChangeFromDerivationPath(derivationPath);
        HDWallet hdWallet = getChildHdWallet(isChange).derive(accountIndex);
        String pub = getPublicKey(
            psbtInput.derivationPathList[pathIndex].accountIndex,
            isChange: psbtInput.derivationPathList[pathIndex].isChange,
            applyTweak: addressType.applyTweak);

        if (!addressType.isTaproot) {
          // ECDSA
          signatureMap[pub] =
              Codec.encodeHex(hdWallet.signEcdsa(Codec.decodeHex(sigHash)));
        } else {
          //Schnorr
          if (addressType == AddressType.p2trKeyPathSpending) {
            signatureMap[pub] = Codec.encodeHex(hdWallet.signSchnorr(
                Codec.decodeHex(sigHash), addressType.applyTweak));
          } else if (addressType == AddressType.p2trMuSig2) {
            //MuSig2
            if (psbtInput.tapBip32Derivation!.length !=
                psbtInput.muSig2PubNonces!.length) {
              throw Exception("Not enough public nonce.");
            }
            Uint8List aggregatedPubKey =
                Codec.decodeHex(psbtInput.muSig2AggregatedPublicKey!);
            Uint8List aggregatedPubNonce =
                Codec.decodeHex(psbtInput.getAggregatedPublicNonce());
            Uint8List secretNonce = Codec.decodeHex(getMuSig2SecretNonce(
                sigHash,
                psbtInput.muSig2AggregatedPublicKey!,
                accountIndex,
                isChange));

            String signature = Codec.encodeHex(hdWallet.signSchnorrForMuSig2(
                Codec.decodeHex(sigHash),
                aggregatedPubKey,
                aggregatedPubNonce,
                secretNonce,
                psbtInput.muSig2ParticipantPubkeys!
                    .map((e) => Codec.decodeHex(e))
                    .toList()));

            signatureMap[pub] = signature;
          }
        }
      }

      // 3. Validate signature
      for (String pub in signatureMap.keys) {
        Uint8List signature = Codec.decodeHex(signatureMap[pub]!);
        Uint8List publicKey = Codec.decodeHex(pub);
        if (!addressType.isTaproot) {
          // ECDSA
          if (!Ecc.verifyEcdsa(Codec.decodeHex(sigHash), publicKey,
              Converter.derToRawSignature(signature))) {
            throw Exception('Invalid signature');
          }
        } else {
          // Schnorr
          if (addressType == AddressType.p2trKeyPathSpending) {
            if (!Ecc.verifySchnorr(
                Codec.decodeHex(sigHash), publicKey, signature)) {
              throw Exception('Invalid signature');
            }
          } else if (addressType == AddressType.p2trMuSig2) {
            if (!Ecc.verifySchnorr(
                Codec.decodeHex(psbtInput.muSig2AggregatedPublicKey!),
                Codec.decodeHex(sigHash),
                signature)) {
              throw Exception('Invalid signature');
            }
          } else {
            throw Exception("Unsupported address type");
          }
        }
      }

      // 4. Attach signature to PSBT
      for (String pub in signatureMap.keys) {
        if (!addressType.isTaproot) {
          // ECDSA
          psbtObject.addPartialSig(inputIndex, signatureMap[pub]!, pub);
        } else {
          // Taproot
          if (addressType.applyTweak) {
            // Key path
            psbtObject.addTapKeySig(inputIndex, signatureMap[pub]!);
          } else {
            // Script path
            psbtObject.addTapScriptSig(inputIndex, signatureMap[pub]!, pub);
          }
        }
      }
    }
    return psbtObject.serialize();
  }

  String getMuSig2SecretNonce(String sigHash, String aggregatedPublicKey,
      int accountIndex, bool isChange,
      {Uint8List? extraInput}) {
    Uint8List secretKey =
        Codec.decodeHex(getPrivateKey(accountIndex, isChange: isChange));
    Uint8List publicKey =
        Codec.decodeHex(getPublicKey(accountIndex, isChange: isChange));
    Uint8List aggPubkey = Codec.decodeHex(aggregatedPublicKey);
    Uint8List message = Codec.decodeHex(sigHash);
    Uint8List rand = Hash.sha160fromByte(
        Uint8List.fromList([...secretKey, ...aggPubkey, ...message]));
    return Codec.encodeHex(calculateSecretNonce(
        rand, secretKey, publicKey, aggPubkey, message, extraInput));
  }

  static Uint8List calculateSecretNonce(
      Uint8List rand,
      Uint8List secretKey,
      Uint8List publicKey,
      Uint8List aggPubkey,
      Uint8List message,
      Uint8List? extraInput,
      {bool isDeterministic = true}) {
    if (!isDeterministic) {
      final auxHash = Codec.decodeHex(Hash.taggedHash("MuSig/aux", rand));
      final result = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        result[i] = secretKey[i] ^ auxHash[i];
      }
      rand = result;
    }
    Uint8List mPrefixed;
    final len = message.length;
    final lenBytes = Uint8List(8)..buffer.asByteData().setUint64(0, len);
    mPrefixed = Uint8List.fromList([0x01, ...lenBytes, ...message]);
    extraInput ??= Uint8List(0);
    final extraLenBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, extraInput.length);

    // Step 4: compute k1, k2
    Uint8List? k1, k2;
    List<Uint8List> scalars = [];
    for (int i = 1; i <= 2; i++) {
      final prefix = Uint8List.fromList([i - 1]);
      final input = Uint8List.fromList([
        ...rand,
        // 1,
        publicKey.length,
        ...publicKey,
        // 1,
        aggPubkey.length,
        ...aggPubkey,
        ...mPrefixed,
        ...extraLenBytes,
        ...extraInput,
        ...prefix
      ]);
      final hash = Codec.decodeHex(Hash.taggedHash("MuSig/nonce", input));
      scalars.add(hash);
    }
    k1 = scalars[0];
    k2 = scalars[1];
    return Uint8List.fromList([...k1, ...k2, ...publicKey]);
  }

  String getMuSig2PublicNonce(String sigHash, String aggregatedPublicKey,
      int accountIndex, bool isChange,
      {Uint8List? extraInput}) {
    Uint8List secretNonce = Codec.decodeHex(getMuSig2SecretNonce(
        sigHash, aggregatedPublicKey, accountIndex, isChange,
        extraInput: extraInput));
    return Codec.encodeHex(calculatePublicNonce(secretNonce));
  }

  static Uint8List calculatePublicNonce(Uint8List secretNonce) {
    final k1 = secretNonce.sublist(0, 32);
    final k2 = secretNonce.sublist(32, 64);
    final r1 = Ecc.pointFromScalar(k1, true);
    final r2 = Ecc.pointFromScalar(k2, true);
    return Uint8List.fromList([...r1!, ...r2!]);
  }

  ///@nodoc
  String toJson() {
    return jsonEncode({
      'fingerprint': _masterFingerprint,
      'hdWallet': _hdWallet.toJson(),
      'extendedPublicKey': _extendedPublicKey.serialize(),
      if (_seed != null) 'seed': _seed!.toJson()
    });
  }

  ///@nodoc
  factory KeyStore.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    String fingerprint = map['fingerprint'];
    HDWallet hdWallet = HDWallet.fromJson(map['hdWallet']);
    ExtendedPublicKey extendedPublicKey =
        ExtendedPublicKey.parse(map['extendedPublicKey']);
    Seed? seed = map['seed'] != null ? Seed.fromJson(map['seed']) : null;
    return KeyStore(fingerprint, hdWallet, extendedPublicKey, seed);
  }

  ///@nodoc
  @override
  String toString() {
    return 'KeyStore{fingerprint: $_masterFingerprint, extendedPublicKey: $_extendedPublicKey}';
  }

  ///@nodoc
  @override
  bool operator ==(Object other) {
    if (other is KeyStore) {
      return _masterFingerprint == other._masterFingerprint &&
          _extendedPublicKey == other._extendedPublicKey &&
          _seed == other._seed;
    }
    return false;
  }

  ///@nodoc
  @override
  int get hashCode =>
      _masterFingerprint.hashCode ^
      _extendedPublicKey.hashCode ^
      _seed.hashCode;
}
