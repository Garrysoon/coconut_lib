part of '../../coconut_lib.dart';

/// Represents a common member of multisignature wallet and vault.
abstract class MultisignatureWalletBase extends WalletBase {
  final int _requiredSignature;
  final List<KeyStore> _keyStoreList;

  /// Get the total number of public key.
  int get totalSigner => _keyStoreList.length;

  /// Get the required number of signature.
  int get requiredSignature => _requiredSignature;

  /// Get the list of keyStores.
  List<KeyStore> get keyStoreList => _keyStoreList;

  /// @nodoc
  MultisignatureWalletBase(this._requiredSignature, AddressType _addressType,
      String derivationPath, this._keyStoreList)
      : super(_addressType, derivationPath) {
    if (!_addressType.isMultisignature) {
      throw Exception('Use Vault or Wallet class for multisignature.');
    }

    if (_keyStoreList.length < requiredSignature) {
      throw Exception(
          'Required signature is greater than the number of keyStores.');
    }

    if (_addressType == AddressType.p2trMuSig2 &&
        _keyStoreList.length != _requiredSignature) {
      throw Exception(
          'The number of keyStores must be equal to the required signature in MuSig2.');
    }

    for (KeyStore keyStore in _keyStoreList) {
      if (NetworkType.currentNetworkType.isTestnet !=
          AddressType.isTestnetVersion(keyStore.extendedPublicKey.version)) {
        throw Exception('Network type mismatch.');
      }
    }

    _descriptor = Descriptor.forMultisignature(
        _addressType.scriptType.replaceAll("P2", "").toLowerCase(),
        _keyStoreList.map((e) => e.extendedPublicKey.serialize()).toList(),
        _derivationPath.replaceAll("m/", ""),
        _keyStoreList.map((e) => e.masterFingerprint).toList(),
        _requiredSignature);
  }

  @override
  String getAddress(int addressIndex, {bool isChange = false}) {
    List<String> pubkeys = _keyStoreList
        .map((e) => e.getPublicKey(addressIndex, isChange: isChange))
        .toList();
    return _addressType.getMultisignatureAddress(pubkeys, _requiredSignature);
  }

  @override
  String getAddressWithDerivationPath(String derivationPath) {
    if (!WalletUtility.validateDerivationPath(_derivationPath)) {
      throw Exception("Invalid derivation path (e.g., m/44'/0'/0'/0/0)");
    }

    if (!derivationPath.startsWith(derivationPath)) {
      throw Exception("Derivation path does not match");
    }

    List<String> pubkeys = _keyStoreList
        .map((e) => e.getPublicKey(
            WalletUtility.getAccountIndexFromDerivationPath(derivationPath),
            isChange: WalletUtility.isChangeFromDerivationPath(derivationPath)))
        .toList();
    return _addressType.getMultisignatureAddress(pubkeys, _requiredSignature);
  }

  String getCoordinatorBsms() {
    Bsms bsms = Bsms(
        coordinator: Coordinator(getAddress(0), Descriptor.parse(descriptor)));
    return bsms.serializeCoordinator();
  }

  String getWitnessScript(String derivationPath) {
    if (addressType == AddressType.p2wsh) {
      List<Uint8List> publicKeys = [];
      for (KeyStore keyStore in keyStoreList) {
        String pub = keyStore.getPublicKey(
            WalletUtility.getAccountIndexFromDerivationPath(derivationPath),
            isChange: WalletUtility.isChangeFromDerivationPath(derivationPath));
        publicKeys.add(Codec.decodeHex(pub));
      }

      MultisignatureScript script = MultisignatureScript.forP2wsh(
          requiredSignature, totalSigner, publicKeys);

      return script.rawSerialize();
    } else {
      throw Exception('Not support witness script for this address type.');
    }
  }

  @override
  bool canSignToPsbt(String psbt) {
    for (KeyStore keyStore in keyStoreList) {
      if (keyStore.canSignToPsbt(psbt)) {
        return true;
      }
    }
    return false;
  }

  @override
  String addSignatureToPsbt(String psbt) {
    if (!canSignToPsbt(psbt)) {
      throw Exception('No keyStore can sign to the PSBT.');
    }

    String signedPsbt = psbt;

    for (KeyStore keyStore in keyStoreList) {
      if (!keyStore.hasSeed) continue;
      if (keyStore.canSignToPsbt(signedPsbt)) {
        signedPsbt = keyStore.addSignatureToPsbt(signedPsbt, addressType);
      }
    }
    return signedPsbt;
  }

  String getAddregatedPublilcKey(int addressIndex, bool isChange) {
    List<String> publicKeysHex = keyStoreList
        .map((keyStore) =>
            keyStore.getPublicKey(addressIndex, isChange: isChange))
        .toList();

    // List<String> publicKeysHex = [
    //   '02F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9',
    //   '03DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659',
    //   '023590A94E768F8E1815C2F24B4D80A8E3149316C3518CE7B7AD338368D038CA66'
    // ];

    List<Uint8List> publicKeysBytes =
        publicKeysHex.map((e) => Codec.decodeHex(e)).toList();

    Uint8List secondKey = Uint8List(0);
    for (String key in publicKeysHex) {
      if (publicKeysHex[0] != key) {
        secondKey = Codec.decodeHex(key);
        break;
      }
    }
    String concatenatedPublicKey = publicKeysHex.map((e) => e).join();

    Uint8List Q = publicKeysBytes[0];
    for (int i = 0; i < publicKeysBytes.length; i++) {
      Uint8List coefficient = Uint8List(0);
      if (Codec.encodeHex(publicKeysBytes[i]) == Codec.encodeHex(secondKey)) {
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
    return Codec.encodeHex(Q).substring(2);
  }
}
