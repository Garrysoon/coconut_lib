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

    if (_addressType == AddressType.p2trMusig2) {
      throw Exception('MuSig2 is not supported yet.');
    }

    if (_keyStoreList.length < requiredSignature) {
      throw Exception(
          'Required signature is greater than the number of keyStores.');
    }

    if (_addressType == AddressType.p2trMusig2 &&
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
        _addressType,
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
}
