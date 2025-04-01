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
    if (mnemonicLength <= 12 &&
        mnemonicLength >= 24 &&
        mnemonicLength % 3 != 0) {
      throw Exception('MnemonicLength is not valid.');
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
      Uint8List? merkleRoot,
      Uint8List? aggregatedPublicKey}) {
    if (!hasSeed) throw Exception('No private key in this key store');
    HDWallet child = getChildHdWallet(isChange).derive(index);
    if (applyTweak) {
      return Codec.encodeHex(child.getTweakedPrivateKey(
          merkleRoot: merkleRoot, aggregatedPublicKey: aggregatedPublicKey));
    } else {
      //print("priv : " + Converter.bytesToHex(child.privateKey!.toList()));
      return child.getMasterPrivateKey();
    }
  }

//sign.
  String sign(String message, int addressIndex,
      {bool isChange = false, isSchnorr = false}) {
    if (!hasSeed) throw Exception('No private key in this key store');
    HDWallet child = getChildHdWallet(isChange).derive(addressIndex);
    Uint8List signature = child.sign(Uint8List.fromList(HEX.decode(message)),
        isShnorr: isSchnorr);
    String sig;
    if (!isSchnorr) {
      // String r = Codec.encodeHex(signature.sublist(0, 32));
      // if (int.parse(r.substring(0, 2), radix: 16) & 0x80 != 0) {
      //   r = '00$r';
      // }
      // String rLength = Converter.decToHex(r.length ~/ 2);
      // String s = Codec.encodeHex(signature.sublist(32, 64));
      // String sLength = Converter.decToHex(s.length ~/ 2);
      // String rs = '02$rLength${r}02$sLength$s';
      // sig = '30${Converter.decToHex(rs.length ~/ 2)}${rs}01';
      sig = Codec.encodeHex(Converter.rawToDerSignature(signature));
    } else {
      sig = Codec.encodeHex(signature);
    }
    return sig;
  }

//sign with derivation path.
  String signWithDerivationPath(String message, String derivationPath,
      {bool isSchnorr = false}) {
    if (!WalletUtility.validateDerivationPath(derivationPath)) {
      throw Exception('Invalid derivation path');
    }
    List<String> pathList = derivationPath.split('/');
    int index = int.parse(pathList.last);
    int changeIndex = int.parse(pathList[pathList.length - 2]);
    return sign(message, index,
        isChange: changeIndex == 1, isSchnorr: isSchnorr);
  }

  /// Get the public key of the key store using index.
  String getPublicKey(int addressIndex,
      {bool isChange = false,
      isXOnly = false,
      applyTweak = false,
      Uint8List? merkleRoot,
      Uint8List? aggregatedPublicKey}) {
    HDWallet child = getChildHdWallet(isChange).derive(addressIndex).neutered();
    if (applyTweak) {
      return HEX.encode((child.getTweakedPublicKey(
          merkleRoot: merkleRoot, aggregatedPublicKey: aggregatedPublicKey)));
    } else {
      return HEX.encode((child.publicKey).toList());
    }
  }

  /// Validate the signatured from this key store.
  bool validateSignature(String signature, String message, int addressIndex,
      {bool isChange = false, bool isSchnorr = false}) {
    Uint8List sig = Codec.decodeHex(signature);
    Uint8List msg = Codec.decodeHex(message);

    HDWallet child = getChildHdWallet(isChange).derive(addressIndex);

    if (!isSchnorr) {
      //DER decoding
      // int rLen = sig[3];
      // Uint8List r = sig.sublist(4, 4 + rLen);
      // if (rLen == 33 && r[0] == 0x00 && r[1] < 0x80) {
      //   r = r.sublist(1);
      // }
      // int sLen = sig[4 + rLen + 1];
      // Uint8List s = sig.sublist(4 + rLen + 2, 4 + rLen + 2 + sLen);

      // if (sLen == 33 && s[0] == 0x00 && s[1] < 0x80) {
      //   s = s.sublist(1);
      // }
      // Uint8List rs = Uint8List.fromList([...r, ...s]);
      Uint8List rs = Converter.derToRawSignature(sig);

      return child.verify(msg, rs);
    } else {
      return child.verify(msg, sig, isSchnorr: isSchnorr);
    }
  }

  /// Validate the signatured from this key store with derivation path.
  bool validateSignatureWithDerivationPath(
      String signature, String message, String derivationPath,
      {bool isSchnorr = false}) {
    List<String> pathList = derivationPath.split('/');
    int index = int.parse(pathList.last);
    int changeIndex = int.parse(pathList[pathList.length - 2]);
    return validateSignature(signature, message, index,
        isChange: changeIndex == 1, isSchnorr: isSchnorr);
  }

  ///Check if the PSBT can be signed from this vault.
  bool canSignToPsbt(String psbt) {
    Psbt psbtObj = Psbt.parse(psbt);
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
  }

  ///add signature to PSBT if it's possible.
  String addSignatureToPsbt(String psbt, AddressType addressType) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed');
    }
    Psbt psbtObject = Psbt.parse(psbt);
    if (canSignToPsbt(psbtObject.serialize()) == false) {
      throw Exception('Vault : This vault can not sign this PSBT');
    }

    bool isSchnorr = false;
    if (addressType.isTaproot) {
      isSchnorr = true;
    }

    for (int i = 0; i < psbtObject.unsignedTransaction!.inputs.length; i++) {
      PsbtInput thisInput = psbtObject.inputs[i];

      if (thisInput.requiredSignature <= thisInput.signedCount) {
        continue;
      }

      // Generate sig hash
      String sigHash;
      if (isSchnorr) {
        List<TransactionOutput> utxoList = [];
        for (int i = 0;
            i < psbtObject.unsignedTransaction!.inputs.length;
            i++) {
          utxoList.add(psbtObject.inputs[i].witnessUtxo!);
        }
        sigHash =
            psbtObject.unsignedTransaction!.getTaprootSigHash(i, utxoList);
      } else {
        TransactionOutput utxo = thisInput.witnessUtxo!;
        if (addressType == AddressType.p2wsh) {
          String? witnessScript = thisInput.witnessScript!.rawSerialize();
          sigHash = psbtObject.unsignedTransaction!
              .getSigHash(i, utxo, addressType, witnessScript: witnessScript);
        } else {
          sigHash =
              psbtObject.unsignedTransaction!.getSigHash(i, utxo, addressType);
        }
      }

      //Add signature
      for (int j = 0; j < thisInput.derivationPathList.length; j++) {
        if (thisInput.derivationPathList[j].masterFingerprint !=
            masterFingerprint) {
          continue;
        }

        //TODO: implement code for the wallet is musig2 or script path
        String publicKey = getPublicKey(
            thisInput.derivationPathList[j].accountIndex,
            isChange: thisInput.derivationPathList[j].isChange,
            applyTweak: isSchnorr);
        String signature = signWithDerivationPath(
            sigHash, thisInput.derivationPathList[j].path,
            isSchnorr: isSchnorr);

        // Validate signature
        if (!validateSignatureWithDerivationPath(
            signature, sigHash, thisInput.derivationPathList[j].path,
            isSchnorr: isSchnorr)) {
          throw Exception('Invalid signature');
        }
        if (addressType == AddressType.p2trKeyPathSpending ||
            addressType == AddressType.p2trMusig2) {
          psbtObject.addTaprootSignature(i, signature);
        } else {
          psbtObject.addSignature(i, signature, publicKey);
        }
      }
      // String publicKey =
      //     getPublicKeyWithDerivationPath(thisInput.derivationPathList!.path);
      // String signature =
      //     signWithDerivationPath(sigHash, thisInput.derivationPathList!.path);
      // if (validateSignatureWithDerivationPath(
      //     signature, sigHash, thisInput.derivationPathList!.path)) {}
    }
    return psbtObject.serialize();
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
