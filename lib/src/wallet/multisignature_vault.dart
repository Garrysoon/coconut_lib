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
        keyStores, descriptor.requiredSignatures,
        addressType: descriptor.addressType);
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

  String addMuSig2PublicNonce(String psbt) {
    if (addressType != AddressType.p2trMuSig2) {
      throw Exception("Only MuSig2 needs public nonce.");
    }
    if (!canSignToPsbt(psbt)) {
      throw Exception('No keyStore can sign to the PSBT.');
    }

    String nonceAddedPsbt = psbt;

    for (KeyStore keyStore in keyStoreList) {
      if (!keyStore.hasSeed) continue;
      if (keyStore.canSignToPsbt(psbt)) {
        nonceAddedPsbt = keyStore.addMuSig2PublicNonceToPsbt(nonceAddedPsbt);
      }
    }

    return nonceAddedPsbt;
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
