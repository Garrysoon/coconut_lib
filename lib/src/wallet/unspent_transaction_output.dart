part of '../../coconut_lib.dart';

/// Represents an UTXO.
class UTXO {
  final String _transactionHash;
  int _index;
  int _amount;
  String _derivationPath;
  int _timestamp;
  int _blockHeight;

  /// @nodoc
  UTXO(
    this._transactionHash,
    this._index,
    this._amount,
    this._derivationPath,
    this._timestamp,
    this._blockHeight,
  );

  /// Get the previous transaction hash of this UTXO.
  String get transactionHash => _transactionHash;

  /// Get the index of the previous transaction.
  int get index => _index;

  /// Get the amount of the UTXO.
  int get amount => _amount;

  /// Get the derivation path of the UTXO.
  String get derivationPath => _derivationPath;

  /// Get the timestamp of the UTXO.
  int get timestamp => _timestamp;

  /// Get the block height of the UTXO.
  int get blockHeight => _blockHeight;

  /// @nodoc
  factory UTXO.fromBlockchain(String transactionHash, int index, int amount,
      String derivationPath, int timestamp, int blockHeight) {
    return UTXO(
        transactionHash, index, amount, derivationPath, timestamp, blockHeight);
  }

  static void sortUTXO(List<UTXO> utxos, UtxoOrderEnum order) {
    int getLastIndex(String path) => int.parse(path.split('/').last);

    int compareUTXOs(UTXO a, UTXO b, bool isAscending, bool byAmount) {
      int primaryCompare = byAmount
          ? (isAscending ? a.amount : b.amount)
              .compareTo(isAscending ? b.amount : a.amount)
          : (isAscending ? a.timestamp : b.timestamp)
              .compareTo(isAscending ? b.timestamp : a.timestamp);

      if (primaryCompare != 0) return primaryCompare;

      int secondaryCompare = byAmount
          ? b.timestamp.compareTo(a.timestamp)
          : b.amount.compareTo(a.amount);

      if (secondaryCompare != 0) return secondaryCompare;

      return getLastIndex(a.derivationPath)
          .compareTo(getLastIndex(b.derivationPath));
    }

    utxos.sort((a, b) {
      switch (order) {
        case UtxoOrderEnum.byAmountDesc:
          return compareUTXOs(a, b, false, true);
        case UtxoOrderEnum.byAmountAsc:
          return compareUTXOs(a, b, true, true);
        case UtxoOrderEnum.byTimestampDesc:
          return compareUTXOs(a, b, false, false);
        case UtxoOrderEnum.byTimestampAsc:
          return compareUTXOs(a, b, true, false);
      }
    });
  }

  String toJson() {
    return jsonEncode({
      'transactionHash': _transactionHash,
      'index': _index,
      'amount': _amount,
      'derivationPath': _derivationPath,
      'timestamp': _timestamp,
      'blockHeight': _blockHeight
    });
  }

  factory UTXO.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    return UTXO(json['transactionHash'], json['index'], json['amount'],
        json['derivationPath'], json['timestamp'], json['blockHeight']);
  }
}
