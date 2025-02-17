part of '../../coconut_lib.dart';

/// Represents a transaction output.
class TransactionOutput {
  Uint8List _amount;
  ScriptPublicKey _scriptPubKey;

  /// Get the amount of the output.
  int get amount =>
      Converter.bytesToDec(Uint8List.fromList(_amount.reversed.toList()));

  /// Get the script public key object of the transaction output.
  ScriptPublicKey get scriptPubKey => _scriptPubKey;

  /// The length of the transaction output.
  int get length => _amount.length + _scriptPubKey.length;

  /// @nodoc
  TransactionOutput(this._amount, this._scriptPubKey);

  /// Get the Bitcoin amount of the output.
  void setAmount(int amount) {
    _amount = Converter.intToLittleEndianBytes(amount, 8);
  }

  factory TransactionOutput.forPayment(int amount, String address) {
    Uint8List amountBytes = Converter.intToLittleEndianBytes(amount, 8);
    if (address.startsWith('1') ||
        address.startsWith('m') ||
        address.startsWith('n')) {
      return TransactionOutput(amountBytes, ScriptPublicKey.p2pkh(address));
    } else if (address.startsWith('bc1q') ||
        address.startsWith('tb1q') ||
        address.startsWith('bcrt1q')) {
      return TransactionOutput(amountBytes, ScriptPublicKey.p2wpkh(address));
    } else if (address.startsWith('bc1p') ||
        address.startsWith('tb1p') ||
        address.startsWith('bcrt1p')) {
      return TransactionOutput(amountBytes, ScriptPublicKey.p2tr(address));
    }
    throw Exception('AddressType not supported');
  }

  bool isDustOutput(bool isSegwit, {int dustRelayFee = 3}) {
    int outputScriptSize = Encoder.decodeHex(serialize()).length;
    late int inputSize;
    if (isSegwit) {
      inputSize = (32 + 4 + 1 + (107 / 4).floor() + 4);
    } else {
      inputSize = (32 + 4 + 1 + 107 + 4);
    }
    int dustThreshold = dustRelayFee * (outputScriptSize + inputSize);

    if (dustThreshold >= amount) {
      return true;
    }
    return false;
  }

  /// Parse the transaction output from the given output hex.
  factory TransactionOutput.parse(String output) {
    Uint8List bytes = Encoder.decodeHex(output);

    var amount = bytes.sublist(0, 8);
    var script = bytes.sublist(8, bytes.length);
    ScriptPublicKey scriptPubKey =
        ScriptPublicKey.parse(Encoder.encodeHex(script));

    return TransactionOutput(amount, scriptPubKey);
  }

  /// Serialize the transaction output.
  String serialize() {
    //print("amount : " + Converter.bytesToHex(_amount));
    //print(amount);
    //print("scriptPubKey : " + _scriptPubKey.serialize());
    return Encoder.encodeHex(_amount) + _scriptPubKey.serialize();
  }

  /// Get the address of the transaction output.
  String getAddress() {
    return _scriptPubKey.getAddress();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true; // Check if they are the same instance
    }
    if (other is! TransactionOutput) {
      return false; // Ensure the object is of the same type
    }
    return amount == other.amount &&
        scriptPubKey.serialize() ==
            other.scriptPubKey.serialize(); // Compare properties
  }

  @override
  int get hashCode => amount.hashCode ^ scriptPubKey.hashCode;
}
