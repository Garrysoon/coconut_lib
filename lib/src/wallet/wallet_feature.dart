part of '../../coconut_lib.dart';

/// Represents the common feature of a wallet.
abstract class WalletFeature {
  /// Generate PSBT for sending bitcoin.
  Future<String> generatePsbt(List<UTXO> utxoList, String receiverAddress,
      String changeAddress, int sendingAmount, int feeRate);

  /// Generate PSBT for sending all bitcoin in the wallet.
  Future<String> generatePsbtWithMaximum(
      List<UTXO> utxoList, String receiverAddress, int feeRate);

  Future<String> generatePsbtWithUtxoList(
      List<UTXO> utxoList,
      String receiverAddress,
      String changeAddress,
      int sendingAmount,
      int feeRate);

  /// Get a estimate fee for sending bitcoin.
  Future<int> estimateFee(List<UTXO> utxoList, String receiverAddress,
      String changeAddress, int sendingAmount, int feeRate);

  /// Get a estimate fee for sending all bitcoin in the wallet.
  Future<int> estimateFeeWithMaximum(
      List<UTXO> utxoList, String receiverAddress, int feeRate);
}
