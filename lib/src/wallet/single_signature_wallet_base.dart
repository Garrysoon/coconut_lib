part of '../../coconut_lib.dart';

/// Represents a common member of single signature wallet and vault.
abstract class SingleSignatureWalletBase extends WalletBase {
  final KeyStore _keyStore;
  final bool _isVault;
  bool get isVault => _isVault;

  /// Get the keystore.
  KeyStore get keyStore => _keyStore;

  /// @nodoc
  SingleSignatureWalletBase(this._keyStore, AddressType _addressType,
      String _derivationPath, this._isVault)
      : super(_addressType, _derivationPath) {
    // if (_addressType.isMultisig) {
    //   throw Exception('Use MultsignatureVault or MultisignatureWallet.');
    // }
    if (NetworkType.currentNetworkType.isTestnet !=
        AddressType.isTestnetVersion(_keyStore._extendedPublicKey.version)) {
      throw Exception('Network type mismatch.');
    }

    _descriptor = Descriptor.forSingleSignature(
        _addressType.scriptType.replaceAll("P2", "").toLowerCase(),
        _keyStore.extendedPublicKey.serialize(),
        _derivationPath.replaceAll("m/", ""),
        _keyStore.masterFingerprint);
  }

  /// Get the address of the given index.
  @override
  String getAddress(int addressIndex, {bool isChange = false}) {
    String pubkey;
    if (addressType == AddressType.p2trKeyPathSpending) {
      pubkey = _keyStore.getPublicKey(addressIndex,
          isChange: isChange, applyTweak: true, isXOnly: true);
    } else {
      pubkey = _keyStore.getPublicKey(addressIndex, isChange: isChange);
    }
    return _addressType.getAddress(pubkey);
  }

  @override
  String getAddressWithDerivationPath(String derivationPath) {
    if (!WalletUtility.validateDerivationPath(_derivationPath)) {
      throw Exception("Invalid derivation path (e.g., m/44'/0'/0'/0/0)");
    }

    if (!derivationPath.startsWith(derivationPath)) {
      throw Exception("Derivation path does not match");
    }

    bool xOnly = false;
    bool applyTweak = false;
    if (addressType.isTaproot) {
      xOnly = true;
    }
    if (addressType == AddressType.p2trKeyPathSpending) {
      applyTweak = true;
    }

    String pubkey = _keyStore.getPublicKey(
        WalletUtility.getAccountIndexFromDerivationPath(derivationPath),
        isChange: WalletUtility.isChangeFromDerivationPath(derivationPath),
        applyTweak: applyTweak,
        isXOnly: xOnly);
    return _addressType.getAddress(pubkey);
  }

  @override
  bool canSignToPsbt(String psbt) {
    return keyStore.canSignToPsbt(psbt);
  }

  @override
  String addSignatureToPsbt(String psbt) {
    return keyStore.addSignatureToPsbt(psbt, addressType);
  }
}
