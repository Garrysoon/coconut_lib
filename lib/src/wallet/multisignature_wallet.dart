part of '../../coconut_lib.dart';

/// Represents a multisignature wallet.
class MultisignatureWallet extends MultisignatureWalletBase
    implements WalletFeature {
  /// @nodoc
  MultisignatureWallet(super.requiredSignature, super.addressType,
      super.derivationPath, super.keyStores);

  /// Create a multisignature wallet from descriptor.
  factory MultisignatureWallet.fromDescriptor(String descriptor) {
    Descriptor descriptorObject = Descriptor.parse(descriptor);
    AddressType addressType;
    if (descriptorObject.scriptType == "sh-wpkh") {
      addressType = AddressType.p2wpkhInP2sh;
    } else {
      addressType = AddressType.getAddressTypeFromScriptType(
          'P2${descriptorObject.scriptType}');
    }

    if (!addressType.isMultisig) {
      throw Exception('Use ${addressType.getAddress} is not multisig script.');
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
        throw Exception('Derivation Path is not same for all public keys');
      }

      KeyStore keyStore =
          KeyStore(addressType, fingerprint, wallet, extendedPublicKey);
      keyStores.add(keyStore);
    }

    return MultisignatureWallet(descriptorObject.requiredSignatures,
        addressType, descriptorObject.getDerivationPath(0), keyStores);
  }

  factory MultisignatureWallet.fromKeyStoreList(
      int requiredSignature,
      AddressType addressType,
      String derivationPath,
      List<KeyStore> keyStoreList) {
    if (!addressType.isMultisig) {
      throw Exception('Use ${addressType.getAddress} is not multisig script.');
    }

    return MultisignatureWallet(
        requiredSignature, addressType, derivationPath, keyStoreList);
  }

  /// Get Json string of the multisignature wallet.
  String toJson() {
    return jsonEncode({'descriptor': descriptor});
  }

  /// Parse the multisignature wallet from json string.
  factory MultisignatureWallet.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    return MultisignatureWallet.fromDescriptor(json['descriptor']);
  }

  @override
  Future<String> generatePsbt(List<UTXO> utxoList, String receiverAddress,
      String changeAddress, int sendingAmount, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forPayment(utxoList, receiverAddress, changeAddress,
            sendingAmount, feeRate, this),
        utxoList,
        this));
    return psbt.serialize();
  }

  @override
  Future<String> generatePsbtWithMaximum(
      List<UTXO> utxoList, String receiverAddress, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forSweep(utxoList, receiverAddress, feeRate, this),
        utxoList,
        this));
    return psbt.serialize();
  }

  @override
  Future<String> generatePsbtWithUtxoList(
      List<UTXO> utxoList,
      String receiverAddress,
      String changeAddress,
      int sendingAmount,
      int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.fromUtxoList(utxoList, receiverAddress, changeAddress,
            sendingAmount, feeRate, this),
        utxoList,
        this));
    return psbt.serialize();
  }

  @override
  Future<int> estimateFee(List<UTXO> utxoList, String receiverAddress,
      String changeAddress, int sendingAmount, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forPayment(utxoList, receiverAddress, changeAddress,
            sendingAmount, feeRate, this),
        utxoList,
        this));
    return psbt.estimateFee(feeRate, addressType,
        requiredSignature: requiredSignature, totalSigner: keyStoreList.length);
  }

  @override
  Future<int> estimateFeeWithMaximum(
      List<UTXO> utxoList, String receiverAddress, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forSweep(utxoList, receiverAddress, feeRate, this),
        utxoList,
        this));
    return psbt.estimateFee(feeRate, addressType,
        requiredSignature: requiredSignature, totalSigner: keyStoreList.length);
  }
}
