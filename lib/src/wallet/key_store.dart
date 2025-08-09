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

  factory KeyStore.fromExtendedPublicKey(String extendedPublicKey, String masterFingerprint) {
    ExtendedPublicKey exPub = ExtendedPublicKey.parse(extendedPublicKey);
    HDWallet wallet = HDWallet.fromPublicKey(exPub.publicKey, exPub.chainCode);
    return KeyStore(masterFingerprint, wallet, exPub);
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
  bool hasPublicKeyInPsbt(String psbt) {
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
              masterFingerprint) {
            if (publicKeyInPsbt == publicKey) {
              return true;
            }
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
              isChange: thisInput.tapBip32Derivation![j].isChange,
              isXOnly: true);

          //getPublicKey(tx.utxoList[i].accountIndex,
          //isChange: tx.utxoList[i].isChange, isXOnly: true)
          if (publicKeyInPsbt.length != publicKey.length) {
            publicKey = publicKey.substring(2);
          }

          // print(
          //     'thisInput.tapBip32Derivation![j].masterFingerprint: ${thisInput.tapBip32Derivation![j].masterFingerprint}');
          // print('masterFingerprint: $masterFingerprint');

          // print('publicKeyInPsbt: $publicKeyInPsbt');
          // print('publicKey: $publicKey');

          if (thisInput.derivationPathList[j].masterFingerprint ==
              masterFingerprint) {
            if (publicKeyInPsbt == publicKey) {
              return true;
            } else if (publicKeyInPsbt == publicKey.substring(2)) {
              return true;
            }
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
      throw Exception('This key store does not have seed');
    }
    Psbt psbtObject = Psbt.parse(psbt);
    if (psbtObject.addressType != AddressType.p2trMuSig2) {
      throw Exception('Only musig2 needs public nonce.');
    }
    if (psbtObject.inputs.length !=
        psbtObject.unsignedTransaction!.inputs.length) {
      throw Exception('Not enought psbt inputs or transaction inputs');
    }
    List<TransactionOutput> utxoList = [];
    if (hasPublicKeyInPsbt(psbtObject.serialize()) == false) {
      throw Exception('This vault can not sign this PSBT');
    }
    for (int j = 0; j < psbtObject.unsignedTransaction!.inputs.length; j++) {
      utxoList.add(psbtObject.inputs[j].witnessUtxo!);
    }
    for (int inputIndex = 0;
        inputIndex < psbtObject.unsignedTransaction!.inputs.length;
        inputIndex++) {
      PsbtInput psbtInput = psbtObject.inputs[inputIndex];
      String sigHash = psbtObject.unsignedTransaction!
          .getTaprootSigHash(inputIndex, utxoList);
      for (DerivationPath derivationPath in psbtInput.tapBip32Derivation!) {
        if (masterFingerprint == derivationPath.masterFingerprint) {
          addMuSig2PublicNonceToPsbtInput(
              psbtInput, derivationPath.path, sigHash);
        }
      }
    }
    return psbtObject.serialize();
  }

  void addMuSig2PublicNonceToPsbtInput(
      PsbtInput psbtInput, String derivationPath, String sigHash) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed');
    }

    int accountIndex =
        WalletUtility.getAccountIndexFromDerivationPath(derivationPath);
    bool isChange = WalletUtility.isChangeFromDerivationPath(derivationPath);
    String publicKey =
        getPublicKey(accountIndex, isChange: isChange, isXOnly: true);
    String publicNonce = getMuSig2PublicNonce(
        sigHash, psbtInput.muSig2AggregatedPublicKey!, accountIndex, isChange);
    psbtInput.addMuSig2PubNonce(publicKey, publicNonce);
  }

  String addSignatureToPsbt(String psbt, AddressType addressType) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed');
    }
    Psbt psbtObject = Psbt.parse(psbt);
    if (hasPublicKeyInPsbt(psbtObject.serialize()) == false) {
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

      // Generate sig hash
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
      String derivationPath = psbtInput.derivationPathList[inputIndex].path;
      MuSig2SessionContext? sessionContext;
      if (addressType == AddressType.p2trMuSig2) {
        sessionContext = MuSig2SessionContext(
            Codec.decodeHex(psbtInput.getAggregatedPublicNonce()),
            psbtInput.muSig2ParticipantPubkeys!
                .map((e) => Codec.decodeHex('02$e'))
                .toList(),
            Codec.decodeHex(sigHash));
      }

      addSignatureToPsbtInput(psbtInput, addressType, derivationPath, sigHash,
          sessionContext: sessionContext);

      // 2. Calculate signatures and get public keys
      // List<String> signatureList = [];
      // List<String> publicKeyList = [];
      // for (int pathIndex = 0;
      //     pathIndex < psbtInput.derivationPathList.length;
      //     pathIndex++) {
      //   if (psbtInput.derivationPathList[pathIndex].masterFingerprint !=
      //       masterFingerprint) {
      //     continue;
      //   }
      //   String derivationPath = psbtInput.derivationPathList[pathIndex].path;
      //   HDWallet hdWallet = getChildHdWallet(
      //           WalletUtility.isChangeFromDerivationPath(derivationPath))
      //       .derive(WalletUtility.getAccountIndexFromDerivationPath(
      //           derivationPath));
      //   publicKeyList.add(getPublicKey(
      //       psbtInput.derivationPathList[pathIndex].accountIndex,
      //       isChange: psbtInput.derivationPathList[pathIndex].isChange,
      //       applyTweak: addressType.applyTweak));

      //   if (!addressType.isTaproot) {
      //     // ECDSA
      //     signatureList.add(
      //         Codec.encodeHex(hdWallet.signEcdsa(Codec.decodeHex(sigHash))));
      //   } else {
      //     //Schnorr
      //     signatureList.add(Codec.encodeHex(hdWallet.signSchnorr(
      //         Codec.decodeHex(sigHash), addressType.applyTweak)));
      //   }
      // }

      // // 3. Validate signature
      // for (int j = 0; j < signatureList.length; j++) {
      //   Uint8List signature = Codec.decodeHex(signatureList[j]);
      //   Uint8List publicKey = Codec.decodeHex(publicKeyList[j]);
      //   if (!addressType.isTaproot) {
      //     // ECDSA
      //     if (!Ecc.verifyEcdsa(Codec.decodeHex(sigHash), publicKey,
      //         Converter.derToRawSignature(signature))) {
      //       throw Exception('Invalid signature');
      //     }
      //   } else {
      //     // Schnorr
      //     if (!Ecc.verifySchnorr(
      //         Codec.decodeHex(sigHash), publicKey, signature)) {
      //       throw Exception('Invalid signature');
      //     }
      //   }
      // }

      // // 4. Attach signature to PSBT
      // for (int j = 0; j < signatureList.length; j++) {
      //   if (!addressType.isTaproot) {
      //     // ECDSA
      //     psbtObject.addPartialSig(
      //         inputIndex, signatureList[j], publicKeyList[j]);
      //   } else {
      //     // Taproot
      //     if (addressType.applyTweak) {
      //       // Key path
      //       psbtObject.addTapKeySig(j, signatureList[j]);
      //     } else {
      //       // Script path
      //       psbtObject.addTapScriptSig(j, signatureList[j], publicKeyList[j]);
      //     }
      //   }
      // }
    }
    return psbtObject.serialize();
  }

  ///add signature to PSBT if it's possible.
  void addSignatureToPsbtInput(PsbtInput psbtInput, AddressType addressType,
      String derivationPath, String sigHash,
      {MuSig2SessionContext? sessionContext}) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed.');
    }
    int accountIndex =
        WalletUtility.getAccountIndexFromDerivationPath(derivationPath);
    bool isChange = WalletUtility.isChangeFromDerivationPath(derivationPath);
    HDWallet hdWallet = getChildHdWallet(isChange).derive(accountIndex);

    String publicKey = getPublicKey(accountIndex,
        isChange: isChange,
        applyTweak: addressType.applyTweak,
        isXOnly: addressType.isTaproot);
    late String signature;

    if (!addressType.isTaproot) {
      // ECDSA
      signature = Codec.encodeHex(hdWallet.signEcdsa(Codec.decodeHex(sigHash)));
    } else {
      //Schnorr
      if (addressType == AddressType.p2trKeyPathSpending) {
        signature = Codec.encodeHex(hdWallet.signSchnorr(
            Codec.decodeHex(sigHash), addressType.applyTweak));
      } else if (addressType == AddressType.p2trMuSig2) {
        //MuSig2
        if (psbtInput.tapBip32Derivation!.length !=
            psbtInput.muSig2PubNonces!.length) {
          throw Exception("Not enough public nonce.");
        }
        Uint8List secretNonce = Codec.decodeHex(getMuSig2SecretNonce(sigHash,
            psbtInput.muSig2AggregatedPublicKey!, accountIndex, isChange));

        signature = Codec.encodeHex(
            hdWallet.signSchnorrForMuSig2(secretNonce, sessionContext!));
      }
    }

    // 3. Validate signature

    Uint8List signatureByte = Codec.decodeHex(signature);
    Uint8List publicKeyByte = Codec.decodeHex(publicKey);
    if (!addressType.isTaproot) {
      // ECDSA
      if (!Ecc.verifyEcdsa(Codec.decodeHex(sigHash), publicKeyByte,
          Converter.derToRawSignature(signatureByte))) {
        throw Exception('Invalid signature');
      }
    } else {
      // Schnorr
      if (addressType == AddressType.p2trKeyPathSpending) {
        if (!Ecc.verifySchnorr(
            Codec.decodeHex(sigHash), publicKeyByte, signatureByte)) {
          throw Exception('Invalid signature');
        }
      } else if (addressType == AddressType.p2trMuSig2) {
        Uint8List publicNonce = Codec.decodeHex(
            psbtInput.muSig2PubNonces![Codec.encodeHex(publicKeyByte)]!);
        if (!Ecc.verifyMuSig2PartialSignature(
            signatureByte, publicNonce, publicKeyByte, sessionContext!)) {
          throw Exception('Invalid signature');
        }
      } else {
        throw Exception("Unsupported address type");
      }
    }

    // 4. Attach signature to PSBT
    if (!addressType.isTaproot) {
      // ECDSA
      // psbtObject.addPartialSig(inputIndex, signatureMap[pub]!, pub);
      psbtInput.addPartialSig(signature, publicKey);
    } else {
      // Taproot
      if (addressType == AddressType.p2trKeyPathSpending) {
        // Key path
        // psbtObject.addTapKeySig(inputIndex, signatureMap[pub]!);
        psbtInput.addTapKeySig(signature);
      } else if (addressType == AddressType.p2trMuSig2) {
        // psbtObject.addMuSig2PartialSig(inputIndex, signatureMap[pub]!, pub);
        psbtInput.addMuSig2PartialSig(signature, publicKey);
      } else if (addressType == AddressType.p2trScriptPathSpending) {
        // Script path
        // psbtObject.addTapScriptSig(inputIndex, signatureMap[pub]!, pub);
        psbtInput.addTapScriptSig(signature, publicKey);
      } else {
        throw Exception("Unsupported address type");
      }
    }
  }

  String getMuSig2SecretNonce(String sigHash, String aggregatedPublicKey,
      int accountIndex, bool isChange,
      {Uint8List? extraInput}) {
    Uint8List secretKey = Codec.decodeHex(
        getPrivateKey(accountIndex, isChange: isChange, isXOnly: true));
    Uint8List publicKey = Codec.decodeHex(
        "02${getPublicKey(accountIndex, isChange: isChange, isXOnly: true)}");
    Uint8List aggPubkey = Codec.decodeHex(aggregatedPublicKey);
    Uint8List message = Codec.decodeHex(sigHash);
    Uint8List rand = Hash.sha160fromByte(
        Uint8List.fromList([...secretKey, ...aggPubkey, ...message]));
    // print("==> Get Secret Nonce");
    // print('rand: ${Codec.encodeHex(rand)}');
    // print('secretKey: ${Codec.encodeHex(secretKey)}');
    // print('publicKey: ${Codec.encodeHex(publicKey)}');
    // print('aggPubkey: ${Codec.encodeHex(aggPubkey)}');
    // print('message: ${Codec.encodeHex(message)}');
    // print('extraInput: ${Codec.encodeHex(extraInput ?? Uint8List(0))}');
    Uint8List secretNonce = calculateSecretNonce(
        rand, secretKey, publicKey, aggPubkey, message, extraInput,
        isDeterministic: false);
    // print('secretNonce: ${Codec.encodeHex(secretNonce)}');
    // print("==> Finished Get Secret Nonce");
    return Codec.encodeHex(secretNonce);
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
    Uint8List publicNonce = calculatePublicNonce(secretNonce);
    return Codec.encodeHex(publicNonce);
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

class MuSig2SessionContext {
  final Uint8List aggregatedPubNonce;
  final List<Uint8List> participantPublicKeys;
  final Uint8List message;

  late ECPoint Q;
  late BigInt b;
  late ECPoint R;
  late BigInt e;

  MuSig2SessionContext(
      this.aggregatedPubNonce, this.participantPublicKeys, this.message) {
    // print('aggregatedPubNonce: ${Codec.encodeHex(aggregatedPubNonce)}');
    // print(
    //     'participantPublicKeys: ${Codec.encodeHex(participantPublicKeys[0])}');
    // print(
    //     'participantPublicKeys: ${Codec.encodeHex(participantPublicKeys[1])}');
    // print('message: ${Codec.encodeHex(message)}');
    if (message.length != 32) {
      throw ArgumentError("sighash must be 32 bytes (got ${message.length})");
    }
    if (aggregatedPubNonce.length != 66) {
      throw ArgumentError(
          "aggregatedPubNonce must be 66 bytes (got ${aggregatedPubNonce.length})");
    }

    for (var key in participantPublicKeys) {
      if (key.length != 33) {
        throw Exception(
            "participantPublicKeys must be 33 bytes (got ${key.length})");
      }
    }

    Q = Ecc.decodeFrom(WalletUtility.aggregatePublicKey(
        participantPublicKeys.map((e) => Codec.encodeHex(e)).toList(),
        isXOnly: false))!;

    b = Ecc.fromBuffer(Codec.decodeHex(Hash.taggedHash(
        "MuSig/noncecoef",
        Uint8List.fromList([
          ...aggregatedPubNonce,
          ...Ecc.getEncoded(Q, true).sublist(1),
          ...message
        ]))));

    final r1 = Ecc.decodeFrom(aggregatedPubNonce.sublist(0, 33))!;
    final r2 = Ecc.decodeFrom(aggregatedPubNonce.sublist(33, 66))!;

    R = (r1 + r2 * b)!;

    Uint8List rX = Ecc.getEncoded(R, false).sublist(1, 33);

    e = Ecc.fromBuffer(Codec.decodeHex(Hash.taggedHash(
        "BIP0340/challenge",
        Uint8List.fromList(
            [...rX, ...Ecc.getEncoded(Q, true).sublist(1), ...message]))));
  }
}
