part of '../../coconut_lib.dart';

/// Represents an UTXO.
class Utxo {
  final String _transactionHash;
  final int _index;
  final int _amount;
  final String _derivationPath;

  /// @nodoc
  Utxo(
    this._transactionHash,
    this._index,
    this._amount,
    this._derivationPath,
  ) {
    if (!WalletUtility.validateDerivationPath(_derivationPath)) {
      throw Exception("Invalid derivation path (e.g., m/44'/0'/0'/0/0)");
    }
  }

  /// Get the transaction hash of this UTXO.
  String get transactionHash => _transactionHash;

  /// Get the index of the transaction output.
  int get index => _index;

  /// Get the amount of the UTXO.
  int get amount => _amount;

  /// Get the derivation path of the UTXO.
  String get derivationPath => _derivationPath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Utxo &&
        other._transactionHash == _transactionHash &&
        other._index == _index;
  }

  @override
  int get hashCode => _transactionHash.hashCode ^ _index.toString().hashCode;
}
