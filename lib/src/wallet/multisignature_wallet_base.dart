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

    for (KeyStore keyStore in _keyStoreList) {
      if (NetworkType.currentNetworkType.isTestnet !=
          AddressType.isTestnetVersion(keyStore.extendedPublicKey.version)) {
        throw Exception('Network type mismatch.');
      }
    }

    _descriptor = Descriptor.forMultisignature(_addressType, _keyStoreList,
        _derivationPath.replaceAll("m/", ""), _requiredSignature);
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

  @override
  String getKeyOriginExpression() {
    List<String> keyOriginExpressionList = [];
    for (KeyStore keyStore in keyStoreList) {
      keyOriginExpressionList
          .add(Descriptor.getKeyOriginExpression(keyStore, derivationPath));
    }
    return keyOriginExpressionList.join(',');
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
  bool hasPublicKeyInPsbt(String psbt) {
    for (KeyStore keyStore in keyStoreList) {
      if (keyStore.hasPublicKeyInPsbt(psbt)) {
        return true;
      }
    }
    return false;
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

      if (addressType != AddressType.p2wsh) {
        throw Exception('Not support witness script for this address type.');
      }
      TransactionOutput utxo = psbtInput.witnessUtxo!;
      String? witnessScript = psbtInput.witnessScript!.rawSerialize();
      sigHash = psbtObject.unsignedTransaction!.getSigHash(
          inputIndex, utxo, addressType,
          witnessScript: witnessScript);

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
                psbtInput, addressType, derivationPath.path, sigHash);
            break;
          }
        }
      }
    }
    return psbtObject.serialize();
  }
}
