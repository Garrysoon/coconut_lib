part of '../../coconut_lib.dart';

/// Represents a multisignature vault.
class MultisignatureVault extends MultisignatureWalletBase
    implements VaultFeature {
  MultisignatureVault(int requiredSignature, AddressType addressType,
      int accountIndex, String derivationPath, List<KeyStore> keyStores)
      : super(requiredSignature, addressType, derivationPath, keyStores) {
    if (keyStores.length < requiredSignature) {
      throw Exception(
          'Required signature is greater than the number of keyStores.');
    }
  }

  /// Create a multisignature vault from a list of keyStores.
  factory MultisignatureVault.fromKeyStoreList(List<KeyStore> keyStoreList,
      int requiredSignature, AddressType addressType,
      {int accountIndex = 0}) {
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    return MultisignatureVault(requiredSignature, addressType, accountIndex,
        derivationPath, keyStoreList);
  }

  /// Create a multisignature vault from a list of seeds.
  factory MultisignatureVault.fromSeedList(
      List<Seed> seedList, int requiredSignature, AddressType addressType,
      {int accountIndex = 0}) {
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
    BSMS bsms = BSMS.parseCoordinator(coordinator);
    List<KeyStore> keyStores = [];
    Descriptor descriptor = bsms.coordinator!.descriptor;
    for (int i = 0; i < descriptor.totalSignature; i++) {
      ExtendedPublicKey extendedPublicKey =
          ExtendedPublicKey.parse(descriptor.getPublicKey(i));
      HDWallet hdWallet = HDWallet.fromPublicKey(
          extendedPublicKey.publicKey, extendedPublicKey.chainCode);
      KeyStore keyStore = KeyStore(addressType, descriptor.getFingerprint(i),
          hdWallet, extendedPublicKey);
      keyStores.add(keyStore);
    }

    return MultisignatureVault.fromKeyStoreList(
        keyStores,
        descriptor.requiredSignatures,
        AddressType.getAddressTypeFromScriptType("p2${descriptor.scriptType}"));
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
      if (keyStore.canSignToPsbt(signedPsbt)) {
        signedPsbt = keyStore.addSignatureToPsbt(signedPsbt);
      }
    }
    return signedPsbt;
  }

  /// Get Json string of the multisignature vault.
  String toJson() {
    return jsonEncode({
      "keyStores": keyStoreList.map((e) => e.toJson()).toList(),
      "requiredSignature": requiredSignature,
      "addressType": addressType.scriptType,
      "derivationPath": derivationPath
    });
  }

  void bindSeedToKeyStore(Seed seed, int index) {
    KeyStore keyStoreFromSeed =
        KeyStore.fromSeed(seed, addressType, accountIndex: index);

    for (KeyStore keyStore in keyStoreList) {
      if (keyStore.masterFingerprint == keyStoreFromSeed.masterFingerprint) {
        keyStoreList[keyStoreList.indexOf(keyStore)] = keyStoreFromSeed;
        return;
      }
    }
  }

  /// Create a multisignature vault from a json string.
  factory MultisignatureVault.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    List<KeyStore> keyStores = [];
    for (var keyStoreJson in json['keyStores']) {
      keyStores.add(KeyStore.fromJson(keyStoreJson));
    }
    return MultisignatureVault.fromKeyStoreList(
        keyStores,
        json['requiredSignature'],
        AddressType.getAddressTypeFromScriptType(json['addressType']),
        accountIndex: 0);
  }
}
