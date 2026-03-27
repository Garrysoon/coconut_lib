part of '../../coconut_lib.dart';

/// Represents a Taproot vault with script path spending support.
class TaprootVault extends TaprootWalletBase {
  TaprootVault._(List<KeyStore> keyStoreList, List<Policy> policyList,
      String derivationPath)
      : super(keyStoreList, policyList, derivationPath, true);

  /// Create a Taproot vault from a list of keyStores.
  factory TaprootVault.fromKeyStoreList(
    List<KeyStore> keyStoreList,
    List<Policy> policyList, {
    int accountIndex = 0,
  }) {
    String derivationPath =
        WalletUtility.getDerivationPath(AddressType.p2tr, accountIndex);
    return TaprootVault._(keyStoreList, policyList, derivationPath);
  }

  /// Create a Taproot vault from a list of seeds.
  factory TaprootVault.fromSeedList(
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
    return TaprootVault._(keyStores, policyList, derivationPath);
  }

  factory TaprootVault.fromCoordinatorBsms(String coordinator,
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

    return TaprootVault.fromKeyStoreList(keyStores, []);
  }

  /// Add public nonce to the PSBT.
  String addPublicNonce(String psbt) {
    if (addressType != AddressType.p2tr) {
      throw Exception("Only p2tr needs public nonce.");
    }
    if (!hasPublicKeyInPsbt(psbt)) {
      throw Exception('No keyStore can sign to the PSBT.');
    }
    if (keyStoreList.length == 1) {
      return psbt;
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

  /// Get Json string of the Taproot vault.
  String toJson() {
    return jsonEncode({
      "keyStores": keyStoreList.map((e) => e.toJson()).toList(),
      // TODO: Miniscript의 toJson 구현 필요
      // "miniscripts": miniscriptList?.map((e) => e.toJson()).toList() ?? [],
      "addressTypeName": AddressType.p2tr.name,
      "derivationPath": derivationPath
    });
  }

  /// Create a Taproot vault from a json string.
  factory TaprootVault.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    List<KeyStore> keyStores = [];
    for (var keyStoreJson in json['keyStores']) {
      keyStores.add(KeyStore.fromJson(keyStoreJson));
    }

    // TODO: Miniscript의 fromJson 구현 필요
    List<Policy> policies = [];
    // for (var miniscriptJson in json['miniscripts']) {
    //   miniscripts.add(Miniscript.fromJson(miniscriptJson));
    // }

    return TaprootVault.fromKeyStoreList(keyStores, policies, accountIndex: 0);
  }
}
