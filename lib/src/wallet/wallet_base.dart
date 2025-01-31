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

  Future<int> estimateFee(List<UTXO> utxoPool, String receiverAddress,
      String changeAddress, int sendingAmount, int feeRate);

  Future<int> estimateFeeForSweep(
      List<UTXO> utxoPool, String receiverAddress, int feeRate);

  Future<String> generatePsbtForPayment(
      List<UTXO> utxoPool,
      String receiverAddress,
      String changeAddress,
      int sendingAmount,
      int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forPayment(utxoPool, receiverAddress, changeAddress,
            sendingAmount, feeRate, this),
        this));
    return psbt.serialize();
  }

  Future<String> generatePsbtWithUtxoList(
      List<UTXO> utxoList,
      String receiverAddress,
      String changeAddress,
      int sendingAmount,
      int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.fromUtxoList(utxoList, receiverAddress, changeAddress,
            sendingAmount, feeRate, this),
        this));
    return psbt.serialize();
  }

  Future<String> generatePsbtForSweep(
      List<UTXO> utxoPool, String receiverAddress, int feeRate) async {
    PSBT psbt = await Future(() => PSBT.fromTransaction(
        Transaction.forSweep(utxoPool, receiverAddress, feeRate, this), this));
    return psbt.serialize();
  }
}
