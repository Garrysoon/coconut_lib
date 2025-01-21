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
    if (!_addressType.isMultisig) {
      throw Exception('Use Vault or Wallet class for single signature.');
    }

    for (KeyStore keyStore in _keyStoreList) {
      if (NetworkType.currentNetwork.isTestnet !=
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
    List<String> pubkeys = _keyStoreList
        .map((e) => e.getPublicKeyWithDerivationPath(derivationPath))
        .toList();
    return _addressType.getMultisignatureAddress(pubkeys, _requiredSignature);
  }

  String getCoordinatorBsms() {
    BSMS bsms = BSMS(
        coordinator: Coordinator(getAddress(0), Descriptor.parse(descriptor)));
    return bsms.serializeCoordinator();
  }

  String getWitnessScript(String derivationPath) {
    if (addressType == AddressType.p2wsh) {
      List<Uint8List> publicKeys = [];
      for (KeyStore keyStore in keyStoreList) {
        String pub = keyStore.getPublicKeyWithDerivationPath(derivationPath);
        publicKeys.add(Converter.hexToBytes(pub));
      }

      WitnessScript script =
          WitnessScript.p2wsh(requiredSignature, totalSigner, publicKeys);

      return script.rawSerialize();
    } else {
      throw Exception('Not support witness script for this address type.');
    }
  }
}
