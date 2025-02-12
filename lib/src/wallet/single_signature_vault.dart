part of '../../coconut_lib.dart';

/// Represents a single signature vault.
class SingleSignatureVault extends SingleSignatureWalletBase {
  SingleSignatureVault._(
      KeyStore keyStore, AddressType addressType, String derivationPath)
      : super(keyStore, addressType, derivationPath, true) {
    if (addressType.isMultisig) {
      throw Exception("Address type is not for single signature vault");
    }
  }

  /// Create a single signature vault from keystore.
  factory SingleSignatureVault.fromKeyStore(KeyStore keyStore,
      {AddressType? addressType, int accountIndex = 0}) {
    addressType ??= AddressType.p2wpkh;
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    return SingleSignatureVault._(keyStore, addressType, derivationPath);
  }

  /// Create a single signature vault from random entropy.
  factory SingleSignatureVault.random({
    AddressType? addressType,
    int mnemonicLength = 24,
    String passphrase = '',
    int accountIndex = 0,
  }) {
    addressType ??= AddressType.p2wpkh;
    KeyStore keyStore = KeyStore.random(addressType,
        mnemonicLength: mnemonicLength,
        passphrase: passphrase,
        accountIndex: accountIndex);
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    return SingleSignatureVault._(keyStore, addressType, derivationPath);
  }

  /// Create a single signature vault from mnemonic words.
  factory SingleSignatureVault.fromMnemonic(String mnemonicWords,
      {AddressType? addressType,
      String passphrase = '',
      int accountIndex = 0}) {
    addressType ??= AddressType.p2wpkh;
    KeyStore keyStore = KeyStore.fromMnemonic(mnemonicWords, addressType,
        passphrase: passphrase, accountIndex: accountIndex);
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    return SingleSignatureVault._(keyStore, addressType, derivationPath);
  }

  /// Create a single signature vault from seed.
  factory SingleSignatureVault.fromSeed(Seed seed,
      {AddressType? addressType, int accountIndex = 0}) {
    addressType ??= AddressType.p2wpkh;
    KeyStore keyStore =
        KeyStore.fromSeed(seed, addressType, accountIndex: accountIndex);
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    return SingleSignatureVault._(keyStore, addressType, derivationPath);
  }

  /// Create a single signature vault from hex entropy.
  factory SingleSignatureVault.fromEntropy(String entropy,
      {AddressType? addressType,
      String passphrase = '',
      int accountIndex = 0}) {
    addressType ??= AddressType.p2wpkh;
    KeyStore keyStore = KeyStore.fromEntropy(entropy, addressType,
        passphrase: passphrase, accountIndex: accountIndex);
    String derivationPath =
        WalletUtility.getDerivationPath(addressType, accountIndex);
    return SingleSignatureVault._(keyStore, addressType, derivationPath);
  }

  /// Display BSMS for multisig setup.
  String getSignerBsms(AddressType targetAddressType, String description) {
    if (keyStore.hasSeed == false) {
      throw Exception('Use seed to create signer.');
    }
    if (!targetAddressType.isMultisig) {
      throw Exception('Use Multisig address type.');
    }

    KeyStore multisigKeyStore =
        // ignore: unnecessary_non_null_assertion
        KeyStore.fromSeed(keyStore.seed!, targetAddressType);

    Bsms bsms = Bsms.fromSigner(
        multisigKeyStore.masterFingerprint,
        (WalletUtility.getDerivationPath(targetAddressType, 0))
            .replaceAll("m/", ""),
        multisigKeyStore.extendedPublicKey.serialize(),
        description);
    return bsms.serializeSigner();
  }

  /// Get Json string of the single signature vault.
  String toJson() {
    return jsonEncode({
      "keyStore": keyStore.toJson(),
      "addressType": addressType.scriptType,
      "derivationPath": derivationPath
    });
  }

  /// Create a single signature vault from a json string.
  factory SingleSignatureVault.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return SingleSignatureVault._(
        KeyStore.fromJson(map['keyStore']),
        AddressType.getAddressTypeFromScriptType(map['addressType']),
        map['derivationPath']);
  }
}
