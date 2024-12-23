part of '../../coconut_lib.dart';

/// Represents a multisignature wallet.
class MultisignatureWallet extends MultisignatureWalletBase
    implements WalletFeature {
  @override
  late WalletStatus? walletStatus;

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
  int getBalance() {
    return walletStatus!.balance.confirmed;
  }

  @override
  int getUnconfirmedBalance() {
    return walletStatus!.balance.unconfirmed;
  }

  @override
  List<Transfer> getTransferList({int cursor = 0, int count = 5}) {
    List<Transfer> transferList = [];

    for (Transaction entity
        in walletStatus!.getTransactionList(count, cursor)) {
      transferList.add(Transfer.fromTransactions(addressBook, entity));
    }
    transferList.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
    return transferList;
  }

  @override
  List<UTXO> getUtxoList(
      {UtxoOrderEnum order = UtxoOrderEnum.byTimestampDesc,
      int? cursor,
      int? count}) {
    UTXO.sortUTXO(walletStatus!.utxoList, order);

    if (cursor != null && count != null) {
      return walletStatus!.utxoList.skip(cursor).take(count).toList();
    }

    return walletStatus!.utxoList;
  }

  @override
  Future<String> generatePsbt(
      String receiverAddress, int sendingAmount, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forPayment(receiverAddress, sendingAmount, feeRate, this),
        this));
    return psbt.serialize();
  }

  @override
  Future<String> generatePsbtWithMaximum(
      String receiverAddress, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forSweep(receiverAddress, feeRate, this), this));
    return psbt.serialize();
  }

  @override
  Future<int> estimateFee(
      String receiverAddress, int sendingAmount, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forPayment(receiverAddress, sendingAmount, feeRate, this),
        this));
    return psbt.estimateFee(feeRate, addressType,
        requiredSignature: requiredSignature, totalSigner: keyStoreList.length);
  }

  @override
  Future<int> estimateFeeWithMaximum(
      String receiverAddress, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forSweep(receiverAddress, feeRate, this), this));
    return psbt.estimateFee(feeRate, addressType,
        requiredSignature: requiredSignature, totalSigner: keyStoreList.length);
  }

  @override
  Future<void> fetchOnChainData(NodeConnector nodeConnector) async {
    var syncResult = await nodeConnector.fetch(this);
    if (syncResult.isFailure) {
      throw Exception(" - Sync failed : ${syncResult.error}");
    } else {
      walletStatus = syncResult.value;
      addressBook.updateAddressBook();
    }
  }

  @override
  void saveStatus() {
    walletStatus!.persist(identifier);
  }

  @override
  Future<void> loadStatus() async {
    walletStatus = await WalletStatus.load(identifier);
    addressBook.updateAddressBook();
  }
}
