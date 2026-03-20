part of '../../coconut_lib.dart';

/// Represents a Taproot wallet.
class TaprootWallet extends TaprootWalletBase {
  TaprootWallet._(List<KeyStore> keyStoreList, List<Policy> policyList,
      String derivationPath)
      : super(keyStoreList, policyList, derivationPath, false);

  /// Create a Taproot wallet from a list of keyStores.
  factory TaprootWallet.fromKeyStoreList(
    List<KeyStore> keyStoreList,
    List<Policy> policyList, {
    int accountIndex = 0,
  }) {
    String derivationPath =
        WalletUtility.getDerivationPath(AddressType.p2tr, accountIndex);

    return TaprootWallet._(keyStoreList, policyList, derivationPath);
  }

  /// Create a Taproot wallet from a list of seeds.
  factory TaprootWallet.fromSeedList(
    List<Seed> seedList,
    List<Policy> policyList, {
    int accountIndex = 0,
  }) {
    String derivationPath =
        WalletUtility.getDerivationPath(AddressType.p2tr, accountIndex);
    List<KeyStore> keyStores = [];
    for (var seed in seedList) {
      keyStores.add(KeyStore.fromSeed(seed, AddressType.p2tr,
          accountIndex: accountIndex));
    }
    return TaprootWallet._(keyStores, policyList, derivationPath);
  }

  /// Create a Taproot wallet from descriptor.
  factory TaprootWallet.fromDescriptor(String descriptor,
      {bool ignoreChecksum = false}) {
    Descriptor descriptorObject =
        Descriptor.parse(descriptor, ignoreChecksum: ignoreChecksum);

    if (descriptorObject.scriptType != 'tr') {
      throw Exception('Descriptor is not for Taproot address type.');
    }

    List<KeyStore> keyStores = [];
    String derivationPath = descriptorObject.getDerivationPath(0);

    for (int i = 0; i < descriptorObject.totalSigner; i++) {
      String fingerprint = descriptorObject.getFingerprint(i);
      ExtendedPublicKey extendedPublicKey =
          ExtendedPublicKey.parse(descriptorObject.getPublicKey(i));
      HDWallet wallet = HDWallet.fromPublicKey(
          extendedPublicKey.publicKey, extendedPublicKey.chainCode);
      if (derivationPath != descriptorObject.getDerivationPath(i)) {
        throw Exception('Derivation Path is not same.');
      }

      KeyStore keyStore = KeyStore(fingerprint, wallet, extendedPublicKey);
      keyStores.add(keyStore);
    }

    // Parse policies from miniscript list if available
    List<Policy> policies = [];
    if (descriptorObject.miniscriptList.isNotEmpty &&
        descriptorObject.miniscriptList.length > 0) {
      for (String miniscript in descriptorObject.miniscriptList) {
        policies.add(Policy.fromMiniscript(miniscript));
      }
    }

    return TaprootWallet._(keyStores, policies, derivationPath);
  }

  factory TaprootWallet.fromKeyOriginExpression(String keyOriginExpression) {
    RegExpMatch match =
        RegExp(r'\[(.+)\](.+)').firstMatch(keyOriginExpression)!;
    String derivationPath =
        'm/${match.group(1)!.split('/').sublist(1).join('/')}'
            .replaceAll('h', "'");
    String? fingerprint = match.group(1)!.split('/')[0];
    String? extendedPublicKey = match.group(2)!.split('/')[0];

    ExtendedPublicKey extendedPublicKeyObject =
        ExtendedPublicKey.parse(extendedPublicKey);
    HDWallet wallet = HDWallet.fromPublicKey(
        extendedPublicKeyObject.publicKey, extendedPublicKeyObject.chainCode);
    return TaprootWallet._(
        [KeyStore(fingerprint, wallet, extendedPublicKeyObject)],
        [],
        derivationPath);
  }

  /// Get Json string of the Taproot wallet.
  String toJson() {
    return jsonEncode({
      "keyStores": keyStoreList.map((e) => e.toJson()).toList(),
      // TODO: Policy의 toJson 구현 필요
      // "policies": policyList.map((e) => e.toJson()).toList(),
      "addressTypeName": AddressType.p2tr.name,
      "derivationPath": derivationPath
    });
  }

  /// Create a Taproot wallet from a json string.
  factory TaprootWallet.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    List<KeyStore> keyStores = [];
    for (var keyStoreJson in json['keyStores']) {
      keyStores.add(KeyStore.fromJson(keyStoreJson));
    }

    // TODO: Policy의 fromJson 구현 필요
    List<Policy> policies = [];
    // for (var policyJson in json['policies']) {
    //   policies.add(Policy.fromJson(policyJson));
    // }

    return TaprootWallet.fromKeyStoreList(keyStores, policies, accountIndex: 0);
  }
}
