part of '../../coconut_lib.dart';

/// Represents a multisignature vault.
class MultisignatureVault extends MultisignatureWalletBase {
  MultisignatureVault(super.requiredSignature, super.addressType,
      int accountIndex, super.derivationPath, super.keyStores);

  /// Create a multisignature vault from a list of keyStores.
  factory MultisignatureVault.fromKeyStoreList(
      List<KeyStore> keyStoreList, int requiredSignature,
      {AddressType? addressType, int accountIndex = 0}) {
    addressType ??= AddressType.p2wsh;
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);

    return MultisignatureVault(requiredSignature, addressType, accountIndex,
        derivationPath, keyStoreList);
  }

  /// Create a multisignature vault from a list of seeds.
  factory MultisignatureVault.fromSeedList(
      List<Seed> seedList, int requiredSignature,
      {AddressType? addressType, int accountIndex = 0}) {
    addressType ??= AddressType.p2wsh;

    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    List<KeyStore> keyStores = [];
    for (var seed in seedList) {
      keyStores.add(
          KeyStore.fromSeed(seed, addressType, accountIndex: accountIndex));
    }
    return MultisignatureVault(requiredSignature, addressType, accountIndex,
        derivationPath, keyStores);
  }

  factory MultisignatureVault.fromCoordinatorBsms(String coordinator,
      {AddressType? addressType}) {
    addressType ??= AddressType.p2wsh;
    Bsms bsms = Bsms.parseCoordinator(coordinator);
    List<KeyStore> keyStores = [];
    Descriptor descriptor = bsms.coordinator!.descriptor;
    for (int i = 0; i < descriptor.totalSigner; i++) {
      ExtendedPublicKey extendedPublicKey =
          ExtendedPublicKey.parse(descriptor.getPublicKey(i));
      HDWallet hdWallet = HDWallet.fromPublicKey(
          extendedPublicKey.publicKey, extendedPublicKey.chainCode);
      KeyStore keyStore =
          KeyStore(descriptor.getFingerprint(i), hdWallet, extendedPublicKey);
      keyStores.add(keyStore);
    }

    return MultisignatureVault.fromKeyStoreList(
        keyStores, descriptor._requiredSignatures,
        addressType: descriptor._addressType);
  }

  void bindSeedToKeyStore(Seed seed, {int accountIndex = 0}) {
    KeyStore keyStoreFromSeed =
        KeyStore.fromSeed(seed, addressType, accountIndex: accountIndex);

    for (KeyStore keyStore in keyStoreList) {
      if (keyStore.masterFingerprint == keyStoreFromSeed.masterFingerprint) {
        keyStoreList[keyStoreList.indexOf(keyStore)] = keyStoreFromSeed;
        return;
      }
    }
  }

  String addPublicNonce(String psbt) {
    if (!hasPublicKeyInPsbt(psbt)) {
      throw Exception('No keyStore can sign to the PSBT.');
    }
    Psbt psbtObject = Psbt.parse(psbt);
    if (psbtObject.addressType != AddressType.p2tr) {
      throw Exception('Only p2tr needs public nonce.');
    }
    if (psbtObject.inputs.length !=
        psbtObject.unsignedTransaction!.inputs.length) {
      throw Exception('Not enought psbt inputs or transaction inputs');
    }

    List<TransactionOutput> utxoList = [];
    for (int j = 0; j < psbtObject.unsignedTransaction!.inputs.length; j++) {
      utxoList.add(psbtObject.inputs[j].witnessUtxo!);
    }

    for (int inputIndex = 0;
        inputIndex < psbtObject.inputs.length;
        inputIndex++) {
      String sigHash = psbtObject.unsignedTransaction!
          .getTaprootSigHash(inputIndex, utxoList);
      PsbtInput psbtInput = psbtObject.inputs[inputIndex];
      for (DerivationPath derivationPath in psbtInput.tapBip32Derivation!) {
        for (KeyStore keyStore in keyStoreList) {
          if (keyStore.hasSeed &&
              derivationPath.masterFingerprint == keyStore.masterFingerprint) {
            keyStore.hasPublicKeyInPsbt(psbt);
            keyStore.addPublicNonceToPsbtInput(
                psbtInput, derivationPath.path, sigHash);
          }
        }
      }
    }
    return psbtObject.serialize();
  }

  /// Get Json string of the multisignature vault.
  String toJson() {
    return jsonEncode({
      "keyStores": keyStoreList.map((e) => e.toJson()).toList(),
      "requiredSignature": requiredSignature,
      "addressTypeName": addressType.name,
      "derivationPath": derivationPath
    });
  }

  /// Create a multisignature vault from a json string.
  factory MultisignatureVault.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    List<KeyStore> keyStores = [];
    for (var keyStoreJson in json['keyStores']) {
      keyStores.add(KeyStore.fromJson(keyStoreJson));
    }
    return MultisignatureVault.fromKeyStoreList(
        keyStores, json['requiredSignature'],
        addressType:
            AddressType.getAddressTypeFromName(json['addressTypeName']),
        accountIndex: 0);
  }
}
