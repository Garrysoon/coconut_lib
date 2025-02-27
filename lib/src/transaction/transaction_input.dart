part of '../../coconut_lib.dart';

/// Represents a transaction input.
class TransactionInput {
  Uint8List _transactionHash;
  Uint8List _index;

  /// Get the script signature of the transaction.
  late ScriptSignature scriptSig;
  late Uint8List _sequence;

  /// @nodoc
  late List<String> witnessList = [];

  /// Get the previous transaction hash.
  String get transactionHash =>
      Encoder.encodeHex(_transactionHash.reversed.toList());

  /// Get the index of previous transaction.
  int get index => Converter.littleEndianToInt(_index);

  /// Get the sequence of the transaction.
  int get sequence => Converter.littleEndianToInt(_sequence);

  /// The length of the transaction input.
  int get length => () {
        int length = 0;
        length += _transactionHash.length;
        length += _index.length;
        length += scriptSig.length;
        length += _sequence.length;
        return length;
      }();

  /// @nodoc
  TransactionInput(
      this._transactionHash, this._index, this.scriptSig, this._sequence,
      {this.witnessList = const []});

  /// Parse the transaction input from the given input string.
  factory TransactionInput.parse(String input) {
    Uint8List bytes = Encoder.decodeHex(input);
    //print("full : " + Converter.bytesToHex(bytes));
    var txHash = bytes.sublist(0, 32);
    //print("txHash : " + Converter.bytesToHex(txHash));
    var index = bytes.sublist(32, 36);
    //print("index : " + Converter.bytesToHex(index));
    var scriptSize = 0;
    ScriptSignature script;
    //if (isSegwit || isUnsignedSignature) {
    if (bytes[36] == 0x00 && bytes[37] != 0x14) {
      script = ScriptSignature.empty();
    } else {
      var scriptSig = bytes.sublist(36);
      script = ScriptSignature.parse(Encoder.encodeHex(scriptSig));
    }
    //print("scriptSig : " + Converter.bytesToHex(scriptSig));
    scriptSize = script.serialize().length ~/ 2;
    var sequence = bytes.sublist(36 + scriptSize, 36 + scriptSize + 4);
    //print(Converter.bytesToHex(sequence));
    return TransactionInput(txHash, index, script, sequence);
  }

  /// Parse the transaction input from the given input string for PSBT.
  factory TransactionInput.parseForPsbt(String input) {
    Uint8List bytes = Encoder.decodeHex(input);
    //print("full : " + Converter.bytesToHex(bytes));
    var txHash = bytes.sublist(0, 32);
    //print("txHash : " + Converter.bytesToHex(txHash));
    var index = bytes.sublist(32, 36);
    //print("index : " + Converter.bytesToHex(index));
    var sequence = bytes.sublist(37, 41);
    return TransactionInput(txHash, index, ScriptSignature.empty(), sequence);
  }

  /// Create a transaction input for sending.
  factory TransactionInput.forPayment(String transactionHash, int index,
      {int sequence = 0xffffffff}) {
    return TransactionInput(
        Uint8List.fromList(
            Encoder.decodeHex(transactionHash).reversed.toList()),
        Converter.intToLittleEndianBytes(index, 4),
        ScriptSignature.empty(),
        Converter.intToLittleEndianBytes(sequence, 4));
  }

  /// Insert signature into the transaction input.
  void setSignature(AddressType addressType, List<Signature> signatureList,
      {MultisignatureScript? witnessScript}) {
    if (signatureList.isEmpty) {
      throw Exception("No signature found.");
    }

    if (!addressType.isMultisignature && signatureList.length > 1) {
      throw Exception(
          "Only one signature is allowed for single signature address.");
    }

    if (addressType == AddressType.p2pkh) {
      scriptSig = ScriptSignature.p2pkh(
          Encoder.decodeHex(signatureList[0].signature),
          Encoder.decodeHex(signatureList[0].publicKey));
    } else if (addressType == AddressType.p2wpkh) {
      scriptSig = ScriptSignature.p2wpkh();
      witnessList = [signatureList[0].signature, signatureList[0].publicKey];
    } else if (addressType == AddressType.p2wsh) {
      if (witnessScript == null) {
        throw ArgumentError('witnessScript is required for p2wsh');
      }
      signatureList.sort((a, b) => a.publicKey.compareTo(b.publicKey));

      scriptSig = ScriptSignature.p2wsh();
      witnessList = ["00"];
      for (int i = 0; i < signatureList.length; i++) {
        // int sigLength = signatureList[i].signature.length ~/ 2;
        // witnessList.add(Converter.decToHex(sigLength));
        witnessList.add(signatureList[i].signature);
      }
      witnessList.add(witnessScript.rawSerialize());
    } else {
      throw ArgumentError('Not supported address type');
    }
  }

  void setTaprootKeyPathSpendingSignature(String signature) {
    witnessList = [signature];
  }

  /// Check if the transaction input has signature.
  bool hasSignature(bool isSewit) {
    if (isSewit) {
      return witnessList.length >= 2;
    } else {
      return !(scriptSig.commands.length == 1 && scriptSig.commands[0] == 0x00);
    }
  }

  /// Serialize the transaction input.
  String serialize() {
    // print("Tx hash : " + Converter.bytesToHex(_transactionHash));
    // print("index : " + Converter.bytesToHex(_index));
    // print("script : " + _scriptSig.serialize());
    // print("seq : " + Converter.bytesToHex(_sequence));
    return Encoder.encodeHex(_transactionHash) +
        Encoder.encodeHex(_index) +
        scriptSig.serialize() +
        Encoder.encodeHex(_sequence);
  }
}
