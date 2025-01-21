part of '../../coconut_lib.dart';

/// Key Store is consist of fingerprint, exPub and seed.
class KeyStore {
  String _masterFingerprint;
  HDWallet _hdWallet;
  HDWallet _hdWalletReceive;
  HDWallet _hdWalletChange;
  ExtendedPublicKey _extendedPublicKey;
  Seed? _seed;
  AddressType _addressType;

  AddressType get addressType => _addressType;

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
  KeyStore(this._addressType, this._masterFingerprint, this._hdWallet,
      this._extendedPublicKey,
      [this._seed])
      : _hdWalletReceive = _hdWallet.derive(0),
        _hdWalletChange = _hdWallet.derive(1);

  /// Create a key store from a seed.
  factory KeyStore.fromSeed(Seed seed, AddressType addressType,
      {int accountIndex = 0}) {
    bool isTestnet = NetworkType.currentNetwork.isTestnet;
    HDWallet rootWallet = HDWallet.fromRootSeed(seed.rootSeed);
    String fingerprint =
        Converter.bytesToHex(rootWallet.fingerprint).toUpperCase();

    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    HDWallet wallet = rootWallet.derivePath(derivationPath);
    int version = isTestnet
        ? addressType.versionForTestnet
        : addressType.versionForMainnet;
    ExtendedPublicKey extendedPublicKey = ExtendedPublicKey.fromHdWallet(
        wallet, version, wallet.parentFingerprint);
    return KeyStore(addressType, fingerprint, wallet, extendedPublicKey, seed);
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

  factory KeyStore.fromSignerBsms(String signer, {AddressType? addressType}) {
    addressType ??= AddressType.p2wsh;
    BSMS bsms = BSMS.parseSigner(signer);
    // KeyStore(fingerprint, wallet, extendedPublicKey)
    HDWallet wallet = HDWallet.fromPublicKey(
        bsms.signer!.extendedPublicKey.publicKey,
        bsms.signer!.extendedPublicKey.chainCode);
    return KeyStore(addressType, bsms.signer!.masterFingerPrint, wallet,
        bsms.signer!.extendedPublicKey);
  }

  /// Get the private key of the key store using index.
  String getPrivateKey(int index, {bool isChange = false}) {
    if (!hasSeed) throw Exception('No private key in this key store');
    HDWallet child = getChildHdWallet(isChange).derive(index);
    //print("priv : " + Converter.bytesToHex(child.privateKey!.toList()));
    return child.getMasterPrivateKey();
  }

//sign.
  String sign(String message, int addressIndex,
      {bool isChange = false, bool isDer = true}) {
    if (!hasSeed) throw Exception('No private key in this key store');
    HDWallet child = getChildHdWallet(isChange).derive(addressIndex);
    Uint8List signature = child.sign(Uint8List.fromList(HEX.decode(message)));
    String sig;
    if (isDer) {
      String r = Converter.bytesToHex(signature.sublist(0, 32));
      if (signature[0] & 0x80 != 0) {
        r = '00$r';
      }
      String rLength = Converter.decToHex(r.length ~/ 2);
      String s = Converter.bytesToHex(signature.sublist(32, 64));
      String sLength = Converter.decToHex(s.length ~/ 2);
      String rs = '02$rLength${r}02$sLength$s';
      sig = '30${Converter.decToHex(rs.length ~/ 2)}${rs}01';
    } else {
      sig = Converter.bytesToHex(signature);
    }

    return sig;
  }

//sign with derivation path.
  String signWithDerivationPath(String message, String derivationPath,
      {bool isDer = true}) {
    List<String> pathList = derivationPath.split('/');
    int index = int.parse(pathList.last);
    int changeIndex = int.parse(pathList[pathList.length - 2]);
    return sign(message, index, isChange: changeIndex == 1, isDer: isDer);
  }

  ///Check if the PSBT can be signed from this vault.
  bool canSignToPsbt(String psbt) {
    PSBT psbtObj = PSBT.parse(psbt);
    for (int i = 0; i < psbtObj.unsignedTransaction!.inputs.length; i++) {
      PsbtInput thisInput = psbtObj.inputs[i];
      // PsbtInput thisInput = psbtObj
      //     .getPsbtInput(psbtObj.unsignedTransaction!.inputs[i].transactionHash)
      // if (thisInput.derivationPath!.parentFingerprint == fingerprint &&
      //     thisInput.derivationPath!.publicKey ==
      //         getPublicKeyWithDerivationPath(thisInput.derivationPath!.path)) {
      //   return true;
      // }

      for (int j = 0; j < thisInput.derivationPathList.length; j++) {
        if (thisInput.derivationPathList[j].masterFingerprint ==
                masterFingerprint &&
            thisInput.derivationPathList[j].publicKey ==
                getPublicKeyWithDerivationPath(
                    thisInput.derivationPathList[j].path)) {
          return true;
        }
      }
    }
    return false;
  }

  ///add signature to PSBT if it's possible.
  String addSignatureToPsbt(String psbt) {
    if (!hasSeed) {
      throw Exception('This vault does not have seed');
    }
    PSBT psbtObject = PSBT.parse(psbt);
    if (canSignToPsbt(psbtObject.serialize()) == false) {
      throw Exception('Vault : This vault can not sign this PSBT');
    }
    for (int i = 0; i < psbtObject.unsignedTransaction!.inputs.length; i++) {
      PsbtInput thisInput = psbtObject.inputs[i];
      // PsbtInput thisInput = psbtObject.getPsbtInput(
      //     psbtObject.unsignedTransaction!.inputs[i].transactionHash);

      //sign
      String utxo = '';
      if (thisInput.witnessUtxo == null) {
        utxo = thisInput.previousTransaction!
            .outputs[psbtObject.unsignedTransaction!.inputs[i].index]
            .serialize();
      } else {
        utxo = thisInput.witnessUtxo!.serialize();
      }
      String sigHash;
      if (addressType == AddressType.p2wsh) {
        String? witnessScript = thisInput.witnessScript!.rawSerialize();
        sigHash = psbtObject.unsignedTransaction!
            .getSigHash(i, utxo, addressType, witnessScript: witnessScript);
      } else {
        sigHash =
            psbtObject.unsignedTransaction!.getSigHash(i, utxo, addressType);
      }

      for (int j = 0; j < thisInput.derivationPathList.length; j++) {
        if (thisInput.derivationPathList[j].masterFingerprint !=
            masterFingerprint) {
          continue;
        }
        String publicKey = getPublicKeyWithDerivationPath(
            thisInput.derivationPathList[j].path);
        String signature = signWithDerivationPath(
            sigHash, thisInput.derivationPathList[j].path);
        if (validateSignatureWithDerivationPath(
            signature, sigHash, thisInput.derivationPathList[j].path)) {}
        psbtObject.addSignature(i, signature, publicKey);
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

  /// Get the public key of the key store using index.
  String getPublicKey(int addressIndex, {bool isChange = false}) {
    HDWallet child = getChildHdWallet(isChange).derive(addressIndex).neutered();
    return HEX.encode((child.publicKey).toList());
  }

  /// Get the public key of the key store using derivation path.
  String getPublicKeyWithDerivationPath(String path) {
    List<String> pathList = path.split('/');
    int index = int.parse(pathList.last);
    int changeIndex = int.parse(pathList[pathList.length - 2]);
    HDWallet child =
        getChildHdWallet(changeIndex == 1).derive(index).neutered();
    return HEX.encode((child.publicKey).toList());
  }

  /// Validate the signatured from this key store.
  bool validateSignature(String signature, String message, int addressIndex,
      {bool isChange = false, bool isDer = true}) {
    Uint8List sig = Converter.hexToBytes(signature);
    Uint8List msg = Converter.hexToBytes(message);

    HDWallet child = getChildHdWallet(isChange).derive(addressIndex);

    if (isDer) {
      //DER decoding
      int rLen = sig[3];
      Uint8List r = sig.sublist(4, 4 + rLen);
      if (r[0] == 0) r = r.sublist(1);
      int sLen = sig[4 + rLen + 1];
      Uint8List s = sig.sublist(4 + rLen + 2, 4 + rLen + 2 + sLen);
      Uint8List rs = Uint8List.fromList([...r, ...s]);

      return child.verify(msg, rs);
    } else {
      return child.verify(msg, sig);
    }
  }

  /// Validate the signatured from this key store with derivation path.
  bool validateSignatureWithDerivationPath(
      String signature, String message, String derivationPath,
      {bool isDer = true}) {
    List<String> pathList = derivationPath.split('/');
    int index = int.parse(pathList.last);
    int changeIndex = int.parse(pathList[pathList.length - 2]);
    return validateSignature(signature, message, index,
        isChange: changeIndex == 1, isDer: isDer);
  }

  ///@nodoc
  String toJson() {
    return jsonEncode({
      'addressType': _addressType.scriptType,
      'fingerprint': _masterFingerprint,
      'hdWallet': _hdWallet.toJson(),
      'extendedPublicKey': _extendedPublicKey.serialize(),
      if (_seed != null) 'seed': _seed!.toJson()
    });
  }

  ///@nodoc
  factory KeyStore.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    AddressType addressType =
        AddressType.getAddressTypeFromScriptType(map['addressType']);
    String fingerprint = map['fingerprint'];
    HDWallet hdWallet = HDWallet.fromJson(map['hdWallet']);
    ExtendedPublicKey extendedPublicKey =
        ExtendedPublicKey.parse(map['extendedPublicKey']);
    Seed? seed = map['seed'] != null ? Seed.fromJson(map['seed']) : null;
    return KeyStore(
        addressType, fingerprint, hdWallet, extendedPublicKey, seed);
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
          _extendedPublicKey == other._extendedPublicKey;
    }
    return false;
  }

  ///@nodoc
  @override
  int get hashCode => toString().hashCode;
}
