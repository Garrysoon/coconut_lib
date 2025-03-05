part of '../../coconut_lib.dart';

/// Represents the base class of a wallet and vault.
abstract class WalletBase {
  final AddressType _addressType;
  final String _derivationPath;
  final int _accountIndex = 0;
  late final Descriptor _descriptor;

  /// Get the address type of the wallet.
  AddressType get addressType => _addressType;

  /// Get the derivation path of the wallet.
  String get derivationPath => _derivationPath;

  /// Get the account index of the wallet.
  int get accountIndex => _accountIndex;

  /// Get the descriptor of the wallet.
  String get descriptor => _descriptor.serialize();

  /// @nodoc
  WalletBase(this._addressType, this._derivationPath);

  /// Get the address of the given index.
  String getAddress(int addressIndex, {bool isChange = false});

  /// Get the address from derivation path
  String getAddressWithDerivationPath(String derivationPath);

  bool canSignToPsbt(String psbt);

  String addSignatureToPsbt(String psbt);

  Future<String> generatePsbtForPayment(
      List<Utxo> utxoPool,
      String receiverAddress,
      String changeAddress,
      int sendingAmount,
      int feeRate) async {
    Psbt psbt = await Future(() => Psbt.fromTransaction(
        Transaction.forPayment(utxoPool, receiverAddress, changeAddress,
            sendingAmount, feeRate, this),
        this));
    return psbt.serialize();
  }

  Future<String> generatePsbtWithUtxoList(
      List<Utxo> utxoList,
      String receiverAddress,
      String changeAddress,
      int sendingAmount,
      int feeRate) async {
    Psbt psbt = await Future(() => Psbt.fromTransaction(
        Transaction.fromUtxoList(utxoList, {receiverAddress: sendingAmount},
            changeAddress, feeRate, this),
        this));
    return psbt.serialize();
  }

  Future<String> generatePsbtForBatchPayment(List<Utxo> utxoPool,
      Map<String, int> paymentMap, String changeAddress, int feeRate) async {
    Psbt psbt = await Future(() => Psbt.fromTransaction(
        Transaction.forBatchPayment(
            utxoPool, paymentMap, changeAddress, feeRate, this),
        this));
    return psbt.serialize();
  }

  Future<String> generatePsbtForSweep(
      List<Utxo> utxoPool, String receiverAddress, int feeRate) async {
    Psbt psbt = await Future(() => Psbt.fromTransaction(
        Transaction.forSweep(utxoPool, receiverAddress, feeRate, this), this));
    return psbt.serialize();
  }
}
