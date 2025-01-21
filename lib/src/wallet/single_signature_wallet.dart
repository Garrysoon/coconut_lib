part of '../../coconut_lib.dart';

/// Represents a single signature wallet.
class SingleSignatureWallet extends SingleSignatureWalletBase
    implements WalletFeature {
  /// Creates a new single signature wallet.
  SingleSignatureWallet(
      String fingerprint,
      HDWallet wallet,
      AddressType addressType,
      String derivationPath,
      ExtendedPublicKey extendedPublicKey)
      : super(KeyStore(addressType, fingerprint, wallet, extendedPublicKey),
            addressType, derivationPath, false);

  /// Create a single signature wallet from descriptor.
  factory SingleSignatureWallet.fromDescriptor(String descriptor) {
    Descriptor descriptorObject = Descriptor.parse(descriptor);
    AddressType addressType;
    if (descriptorObject.scriptType == "sh-wpkh") {
      addressType = AddressType.p2wpkhInP2sh;
    } else {
      addressType = AddressType.getAddressTypeFromScriptType(
          'P2${descriptorObject.scriptType}');
    }

    if (addressType.isMultisig) {
      throw Exception(
          '${addressType.getAddress} is multisig script. Use MultsignatureVault Class.');
    }

    ExtendedPublicKey extendedPublicKey =
        ExtendedPublicKey.parse(descriptorObject.getPublicKey(0));
    HDWallet wallet = HDWallet.fromPublicKey(
        extendedPublicKey.publicKey, extendedPublicKey.chainCode);
    return SingleSignatureWallet(descriptorObject.getFingerprint(0), wallet,
        addressType, descriptorObject.getDerivationPath(0), extendedPublicKey);
  }

  /// Get Json string of the single signature wallet.
  String toJson() {
    return jsonEncode({'descriptor': descriptor});
  }

  /// Parse the single signature wallet from json string.
  factory SingleSignatureWallet.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    return SingleSignatureWallet.fromDescriptor(json['descriptor']);
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
    return psbt.estimateFee(feeRate, addressType);
  }

  @override
  Future<int> estimateFeeWithMaximum(
      List<UTXO> utxoList, String receiverAddress, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forSweep(utxoList, receiverAddress, feeRate, this),
        utxoList,
        this));
    return psbt.estimateFee(feeRate, addressType);
  }
}
