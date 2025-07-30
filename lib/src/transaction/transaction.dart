part of '../../coconut_lib.dart';

/// Represents a transaction.
class Transaction {
  Uint8List _version;
  List<TransactionInput> _inputs;
  List<TransactionOutput> _outputs;
  Uint8List _lockTime;
  bool _isSegwit;
  late final Map<String, int> _paymentMap;
  late String? changeAddressDerivationPath;

  late List<Utxo> _utxoList = [];

  /// Get the version of the transaction.
  String get version => Codec.encodeHex(_version);

  /// Get the inputs of the transaction.
  List<TransactionInput> get inputs => _inputs;

  /// Get the outputs of the transaction.
  List<TransactionOutput> get outputs => _outputs;

  /// Get the lock time of the transaction.
  String get lockTime => Codec.encodeHex(_lockTime);

  /// Get the transaction hash.
  String get transactionHash {
    // String hash = Hash.sha256fromHex(Hash.sha256fromHex(_serializeLegacy()));
    String hash = Hash.sha256fromHex(Hash.sha256fromHex(_serializeLegacy()));
    String littleEndian = Converter.toLittleEndian(hash);
    return littleEndian;
  }

  /// Get the length of the transaction.
  int get length => () {
        int total = 0;
        total += _version.length;
        if (_isSegwit) {
          total += 2;
        }
        total += Codec.encodeVariableInteger(_inputs.length).length;
        for (TransactionInput input in _inputs) {
          total += input.length;
        }
        total += Codec.encodeVariableInteger(_outputs.length).length;
        for (TransactionOutput output in _outputs) {
          total += output.length;
        }
        total += _lockTime.length;
        return total;
      }();

  List<Utxo> get utxoList => _utxoList;
  int get totalInputAmount {
    int total = 0;
    for (Utxo utxo in _utxoList) {
      total += utxo.amount;
    }
    return total;
  }

  int _getTotalSendingAmount() {
    int total = 0;
    for (var entry in _paymentMap.entries) {
      total += entry.value;
    }
    return total;
  }

  /// @nodoc
  Transaction(this._version, this._inputs, this._outputs, this._lockTime,
      this._isSegwit);

  factory Transaction.withInputsAndOutputs(List<TransactionInput> inputs,
      List<TransactionOutput> outputs, AddressType addressType,
      {int version = 2, int lockTime = 0}) {
    return Transaction(
        Converter.intToLittleEndianBytes(version, 4),
        inputs,
        outputs,
        Converter.intToLittleEndianBytes(lockTime, 4),
        addressType.isSegwit);
  }

  /// Create a transaction with UTXO List.
  factory Transaction.forBatchPayment(
      List<Utxo> utxoList,
      Map<String, int> paymentMap,
      String changeAddressDerivationPath,
      double feeRate,
      WalletBase wallet,
      {int version = 2,
      int lockTime = 0}) {
    int totalInputAmount = 0;
    List<TransactionInput> inputs = [];
    List<TransactionOutput> outputs = [];
    for (Utxo utxo in utxoList) {
      totalInputAmount += utxo.amount;
      inputs.add(TransactionInput.forPayment(utxo.transactionHash, utxo.index));
    }

    String changeAddress =
        wallet.getAddressWithDerivationPath(changeAddressDerivationPath);

    int totalOutputAmount =
        paymentMap.values.fold(0, (sum, value) => sum + value);

    for (var entry in paymentMap.entries) {
      String recipientAddress = entry.key;
      int amount = entry.value;

      outputs.add(TransactionOutput.forPayment(amount, recipientAddress,
          isChangeOutput: false));
    }
    TransactionOutput changeOutput =
        TransactionOutput.forPayment(0, changeAddress, isChangeOutput: true);
    outputs.add(changeOutput);

    Transaction tx = Transaction.withInputsAndOutputs(
        inputs, outputs, wallet.addressType,
        version: version, lockTime: lockTime);

    // print("Input : ${tx.inputs.length}, Output : ${tx.outputs.length}");

    double vByte = 0.0;
    if (!wallet.addressType.isMultisignature) {
      vByte = tx.estimateVirtualByte(wallet.addressType);
    } else {
      MultisignatureWalletBase multisignatureWallet =
          wallet as MultisignatureWalletBase;
      vByte = tx.estimateVirtualByte(wallet.addressType,
          requiredSignature: multisignatureWallet.requiredSignature,
          totalSigner: multisignatureWallet.totalSigner);
    }

    int fee = (vByte * feeRate).ceil();

    // print("Fee : $fee");
    int changeAmount = totalInputAmount - totalOutputAmount - fee;
    if (changeAmount < 0) {
      // tx.outputs.remove(changeOutput);
      throw Exception('Not enough amount for sending. (Fee : $fee)');
    } else {
      changeOutput.setAmount(changeAmount);
      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        tx.outputs.remove(changeOutput);
      }
    }

    tx._paymentMap = paymentMap;
    tx.changeAddressDerivationPath = changeAddressDerivationPath;
    tx._utxoList = utxoList;
    return tx;
  }

  /// Create a transaction for simple payment.
  factory Transaction.forSinglePayment(
      List<Utxo> utxoList,
      String receiveAddress,
      String changeAddressDerivationPath,
      int amount,
      double feeRate,
      WalletBase wallet,
      {int version = 2,
      int lockTime = 0}) {
    Transaction transaction = Transaction.forBatchPayment(utxoList,
        {receiveAddress: amount}, changeAddressDerivationPath, feeRate, wallet,
        version: version, lockTime: lockTime);
    return transaction;
  }

  /// Create a transaction for sending all Bitcoin in the wallet.
  factory Transaction.forSweep(
      List<Utxo> utxoList, String address, double feeRate, WalletBase wallet,
      {int version = 2, int lockTime = 0}) {
    List<TransactionInput> inputs = [];
    List<TransactionOutput> outputs = [];
    int inputAmount = 0;
    for (Utxo utxo in utxoList) {
      // if (utxo.blockHeight == 0) {
      //   continue;
      // }
      inputs.add(TransactionInput.forPayment(utxo.transactionHash, utxo.index));
      inputAmount += utxo.amount;
    }

    if (inputAmount == 0) {
      throw Exception('No balance to send');
    }

    if (inputAmount < _getDustThreshold(wallet.addressType)) {
      throw Exception('Sending amount is under dust threshold.');
    }

    TransactionOutput sendingOutput =
        TransactionOutput.forPayment(0, address, isChangeOutput: false);
    outputs.add(sendingOutput);

    Transaction transaction = Transaction.withInputsAndOutputs(
        inputs, outputs, wallet.addressType,
        version: version, lockTime: lockTime);

    transaction._paymentMap = {
      sendingOutput.getAddress(): sendingOutput.amount
    };

    double vByte = 0.0;
    if (!wallet.addressType.isMultisignature) {
      vByte = transaction.estimateVirtualByte(wallet.addressType);
    } else {
      MultisignatureWalletBase multisignatureWallet =
          wallet as MultisignatureWalletBase;
      vByte = transaction.estimateVirtualByte(wallet.addressType,
          requiredSignature: multisignatureWallet.requiredSignature,
          totalSigner: multisignatureWallet.totalSigner);
    }

    int fee = (vByte * feeRate).ceil();

    if (inputAmount < fee) {
      throw Exception('Not enough amount for sending. (Fee : $fee)');
    }

    sendingOutput.setAmount(inputAmount - fee);

    // Transaction tx = Transaction.forMaximumSending(
    //     inputs, address, inputAmount, wallet.addressType, feeRate);
    // print(tx.serialize());
    transaction._utxoList = utxoList;
    return transaction;
  }

  /// Create a batch transaction for sending all Bitcoin in the wallet.
  factory Transaction.forBatchSweep(
      List<Utxo> utxoList,
      Map<String, int> paymentMap,
      String remainderAddress,
      double feeRate,
      WalletBase wallet,
      {int version = 2,
      int lockTime = 0}) {
    int totalInputAmount = 0;
    List<TransactionInput> inputs = [];
    List<TransactionOutput> outputs = [];
    for (Utxo utxo in utxoList) {
      totalInputAmount += utxo.amount;
      inputs.add(TransactionInput.forPayment(utxo.transactionHash, utxo.index));
    }

    int totalOutputAmount =
        paymentMap.values.fold(0, (sum, value) => sum + value);

    for (var entry in paymentMap.entries) {
      String recipientAddress = entry.key;
      int amount = entry.value;

      outputs.add(TransactionOutput.forPayment(amount, recipientAddress,
          isChangeOutput: false));
    }
    TransactionOutput changeOutput = TransactionOutput.forPayment(
        0, remainderAddress,
        isChangeOutput: false);
    outputs.add(changeOutput);

    Transaction tx = Transaction.withInputsAndOutputs(
        inputs, outputs, wallet.addressType,
        version: version, lockTime: lockTime);

    // print("Input : ${tx.inputs.length}, Output : ${tx.outputs.length}");

    double vByte = 0.0;
    if (!wallet.addressType.isMultisignature) {
      vByte = tx.estimateVirtualByte(wallet.addressType);
    } else {
      MultisignatureWalletBase multisignatureWallet =
          wallet as MultisignatureWalletBase;
      vByte = tx.estimateVirtualByte(wallet.addressType,
          requiredSignature: multisignatureWallet.requiredSignature,
          totalSigner: multisignatureWallet.totalSigner);
    }

    int fee = (vByte * feeRate).ceil();

    // print("Fee : $fee");
    int changeAmount = totalInputAmount - totalOutputAmount - fee;
    if (changeAmount < 0) {
      // tx.outputs.remove(changeOutput);
      throw Exception('Not enough amount for sending. (Fee : $fee)');
    } else {
      changeOutput.setAmount(changeAmount);
      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        tx.outputs.remove(changeOutput);
      }
    }

    tx._paymentMap = paymentMap;
    tx._utxoList = utxoList;
    return tx;
  }

  /// Parse the transaction.
  factory Transaction.parse(String transaction,
      {bool isEmptySignature = false}) {
    Uint8List txBytes = Codec.decodeHex(transaction);

    Uint8List sublist = txBytes.sublist(4);
    bool isSegwit = sublist[0] == 0x00;

    // Move the pointer back by 5 bytes
    //sublist = txBytes.sublist(0, txBytes.length - 5);
    if (isSegwit) {
      return Transaction._parseSegwit(txBytes);
    } else {
      return Transaction._parseLegacy(txBytes, isEmptySignature);
    }
  }

  /// Get the length of a variable integer based on its first byte
  static int _getVariableIntegerLength(Uint8List bytes, int offset) {
    int firstByte = bytes[offset];
    if (firstByte < 0xfd) {
      return 1;
    } else if (firstByte == 0xfd) {
      return 3;
    } else if (firstByte == 0xfe) {
      return 5;
    } else {
      return 9;
    }
  }

  factory Transaction._parseSegwit(Uint8List txBytes) {
    int offset = 0;
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;
    Uint8List marker = txBytes.sublist(offset, offset + 2);
    offset += 2;
    if (!(marker[0] == 0x00 && marker[1] == 0x01)) {
      throw Exception('Transaction : Not a segwit transaction maker');
    }
    int numInputs = Codec.decodeVariableInteger(txBytes, offset);
    //print(numInputs);
    offset += _getVariableIntegerLength(txBytes, offset);
    List<TransactionInput> inputs = [];
    //print(Converter.bytesToHex(txBytes.sublist(offset)));
    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Codec.encodeHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      //print("size:" + size.toString());
      offset += size;
    }
    int numOutputs = Codec.decodeVariableInteger(txBytes, offset);
    offset += _getVariableIntegerLength(txBytes, offset);
    //print(numOutputs);
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output =
          TransactionOutput.parse(Codec.encodeHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    //witness
    for (TransactionInput txIn in inputs) {
      int numItems = Codec.decodeVariableInteger(txBytes, offset);
      offset += _getVariableIntegerLength(txBytes, offset);
      List items = [];
      for (int i = 0; i < numItems; i++) {
        int itemLen = Codec.decodeVariableInteger(txBytes, offset);
        offset += _getVariableIntegerLength(txBytes, offset);
        if (itemLen == 0) {
          items.add(0);
        } else {
          items.add(txBytes.sublist(offset, offset + itemLen));
          offset += itemLen;
        }
      }
      txIn.witnessList = [];
      // txIn.witnessList = items.map((e) => Converter.bytesToHex(e)).toList();
      for (dynamic item in items) {
        if (item == 0) {
          txIn.witnessList.add('00');
        } else {
          txIn.witnessList.add(Codec.encodeHex(item));
        }
      }
    }
    Uint8List locktime = txBytes.sublist(offset);
    offset += 4;
    // return Transaction(version, inputs, outputs, locktime,
    //     testnet: testnet, segwit: true);
    // print('witness : ' + inputs[0].witness.toString());
    return Transaction(version, inputs, outputs, locktime, true);
  }

  factory Transaction._parseLegacy(Uint8List txBytes, bool isEmptySignature) {
    int offset = 0;
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;
    int numInputs = Codec.decodeVariableInteger(txBytes, offset);
    //print("numInputs : $numInputs");
    offset += _getVariableIntegerLength(txBytes, offset);
    List<TransactionInput> inputs = [];
    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Codec.encodeHex(txBytes.sublist(offset)));
      // print("input : ${input.serialize()}");
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      //print("size:" + size.toString());
      offset += size;
      // print("script : ${input.scriptSig.serialize()}");
      // print("input : ${input.serialize()}");
    }

    int numOutputs = Codec.decodeVariableInteger(txBytes, offset);
    offset += _getVariableIntegerLength(txBytes, offset);
    // print("numOutputs : $numOutputs");
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output =
          TransactionOutput.parse(Codec.encodeHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    Uint8List locktime = txBytes.sublist(offset);
    return Transaction(version, inputs, outputs, locktime, false);
  }

  /// Parse the unsigned transaction. (for PSBT)
  factory Transaction.parseUnsignedTransaction(String transaction) {
    int offset = 0;
    Uint8List txBytes = Codec.decodeHex(transaction);
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;

    int numInputs = Codec.decodeVariableInteger(txBytes, offset);
    offset += _getVariableIntegerLength(txBytes, offset);
    List<TransactionInput> inputs = [];

    for (int i = 0; i < numInputs; i++) {
      TransactionInput input = TransactionInput.parseForPsbt(
          Codec.encodeHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      //print("size:" + size.toString());
      offset += size;
      // print("input : " + input.transactionHash);
      // print("input index : " + input.index.toString());
      // print("input script : " + input.scriptSig.serialize());
      // print("input sequence : " + input.sequence.toString());
    }

    int numOutputs = Codec.decodeVariableInteger(txBytes, offset);
    offset += _getVariableIntegerLength(txBytes, offset);
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output =
          TransactionOutput.parse(Codec.encodeHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
      // print("numOutputs:" + numOutputs.toString());
      // print("output script : " + output.scriptPubKey.serialize());
    }
    bool isSegwit = false;

    Uint8List locktime = txBytes.sublist(offset);
    offset += 4;

    return Transaction(version, inputs, outputs, locktime, isSegwit);
  }

  /// Serialize the transaction.
  String serialize() {
    if (_isSegwit) {
      return _serializeSegwit();
    } else {
      return _serializeLegacy();
    }
  }

  /// Serialize to segwit transaction.
  String _serializeSegwit() {
    String serialized = '';
    serialized += version;
    serialized += '0001';
    serialized += Codec.encodeHex(Codec.encodeVariableInteger(inputs.length));
    for (int i = 0; i < inputs.length; i++) {
      serialized += inputs[i].serialize();
    }
    serialized += Codec.encodeHex(Codec.encodeVariableInteger(outputs.length));
    for (int i = 0; i < outputs.length; i++) {
      serialized += outputs[i].serialize();
    }

    //serialize witness
    for (int i = 0; i < inputs.length; i++) {
      serialized += Codec.encodeHex(
          Codec.encodeVariableInteger(inputs[i].witnessList.length));

      //if the script is p2wpkh or else
      for (int j = 0; j < inputs[i].witnessList.length; j++) {
        if (inputs[i].witnessList[j].isEmpty ||
            inputs[i].witnessList[j] == '00') {
          serialized += '00';
        } else {
          int size = inputs[i].witnessList[j].length ~/ 2;
          serialized += Codec.encodeHex(Codec.encodeVariableInteger(size));
          serialized += inputs[i].witnessList[j];
        }
      }
    }

    serialized += lockTime;
    return serialized;
  }

  /// Serialize to legacy transaction.
  String _serializeLegacy() {
    String serialized = '';
    serialized += version;
    serialized += Codec.encodeHex(Codec.encodeVariableInteger(inputs.length));
    for (int i = 0; i < inputs.length; i++) {
      serialized += inputs[i].serialize();
    }
    serialized += Codec.encodeHex(Codec.encodeVariableInteger(outputs.length));
    //print(Converter.bytesToHex(Varints.encode(outputs.length)));
    for (int i = 0; i < outputs.length; i++) {
      serialized += outputs[i].serialize();
      //print('script output : ' + outputs[i].scriptPubKey.serialize());
    }
    //print('locktime : ' + Converter.bytesToHex(lockTime));
    serialized += lockTime;
    return serialized;
  }

  /// Get the signature hash of the transaction.
  String getSigHash(int index, TransactionOutput utxo, AddressType addressType,
      {int hashType = 1, String? witnessScript}) {
    if (hashType != 1) {
      throw Exception("Only SIGHASH_ALL supported.");
    }

    if (addressType.isSegwit) {
      if (addressType == AddressType.p2wsh) {
        if (witnessScript == null) {
          throw ArgumentError('witnessScript is required for p2wsh');
        }
        return _getSegwitSigHash(index, utxo, hashType, addressType,
            witnessScript: witnessScript);
      }
      return _getSegwitSigHash(index, utxo, hashType, addressType);
    } else {
      return _getLegacySigHash(index, utxo, hashType);
    }
  }

  String _getLegacySigHash(int index, TransactionOutput utxo, int hashType) {
    String thisTx = serialize();
    Transaction forSig = Transaction.parse(thisTx);
    for (int i = 0; i < forSig.inputs.length; i++) {
      if (i == index) {
        String pubkey = utxo.scriptPubKey.serialize();
        forSig.inputs[i].scriptSig = ScriptSignature.parse(pubkey);
      } else {
        forSig.inputs[i].scriptSig = ScriptSignature.parse('00');
      }
    }
    String type =
        Codec.encodeHex(Converter.intToLittleEndianBytes(hashType, 4));
    String sigHash = forSig.serialize() + type;
    return Hash.sha256(sigHash);
  }

  //BIP143
  String _getSegwitSigHash(
      int index, TransactionOutput utxo, int hashType, AddressType addressType,
      {String? witnessScript}) {
    String sigHash = '';
    sigHash += version;
    sigHash += _getHashPrevOuts(false);
    //print("prevouts : " + _getHashPrevOuts());
    sigHash += _getHashSequence(false);
    sigHash += _getOutPoint(index);
    if (addressType == AddressType.p2wpkh) {
      sigHash +=
          "1976a914${Codec.encodeHex(utxo.scriptPubKey.commands[1])}88ac";
    } else if (addressType == AddressType.p2wsh) {
      if (witnessScript == null) {
        throw ArgumentError('witnessScript is required for p2wsh');
      }
      int length = witnessScript.length ~/ 2;
      sigHash += Codec.encodeHex(Codec.encodeVariableInteger(length));
      sigHash += witnessScript;
    } else {
      sigHash += utxo.scriptPubKey.serialize();
    }

    sigHash +=
        Codec.encodeHex(Converter.intToLittleEndianBytes(utxo.amount, 8));
    sigHash += Codec.encodeHex(
        Converter.intToLittleEndianBytes(inputs[index].sequence, 4));
    sigHash += _getHashOutputs(false);
    sigHash += lockTime;
    sigHash += Codec.encodeHex(Converter.intToLittleEndianBytes(hashType, 4));

    return Hash.sha256fromHex(Hash.sha256fromHex(sigHash));
  }

  //BIP341
  String getTaprootSigHash(int index, List<TransactionOutput> utxoList,
      {int hashType = 0,
      bool isTapscript = false,
      Uint8List? annexHash,
      Uint8List? spentOutput,
      Uint8List? prevout}) {
    int outputType =
        (hashType == 0) ? 1 : (hashType & 3); // Default is SIGHASH_ALL
    if (outputType == 3) {
      throw ArgumentError("Invalid hash type");
    }
    int inputType = hashType & 0x80;
    if (!(hashType <= 0x03 || (hashType >= 0x81 && hashType <= 0x83))) {
      throw ArgumentError("Invalid hash type");
    }

    final List<int> buffer = [];
    buffer.add(0);
    buffer.add(hashType);

    buffer.addAll(_version);
    buffer.addAll(_lockTime);
    if (inputType != 0x80) {
      //if not SIGHASH_ANYONECANPAY
      buffer.addAll(Codec.decodeHex(_getHashPrevOuts(true)));
      // print("prevouts : " + _getHashPrevOuts(true));
      buffer.addAll(Codec.decodeHex(
          getHashAmounts(utxoList.map((e) => e.amount).toList())));
      // print("amounts : " +
      //     getHashAmounts(utxoList.map((e) => e.amount).toList()));
      buffer.addAll(Codec.decodeHex(_getHashScriptPublicKey(utxoList
          .map((e) => e.scriptPubKey.serialize())
          .toList()))); //scriptPubkeys
      buffer.addAll(Codec.decodeHex(_getHashSequence(true)));
    }
    if (outputType == 1) {
      //if SIGHASH_ALL
      String outputsText = '';
      outputs.map((e) => e.serialize()).forEach((element) {
        outputsText += element;
      });
      buffer.addAll(Codec.decodeHex(Hash.sha256fromHex(outputsText)));
      // print("outputs : " + Hash.sha256fromHex(outputsText));
    }

    int extFlag = isTapscript ? 1 : 0;
    int haveAnnex = annexHash != null ? 1 : 0;
    int spendType = (extFlag << 1) + haveAnnex;
    buffer.add(spendType);

    if (inputType == 0x80) {
      //if SIGHASH_ANYONECANPAY
      buffer.addAll(prevout!);
      buffer.addAll(spentOutput!);
    } else {
      buffer.addAll(
          Uint8List(4)..buffer.asByteData().setInt32(0, index, Endian.little));
    }
    if (haveAnnex == 1) {
      buffer.addAll(annexHash!);
    }
    return Hash.taggedHash("TapSighash", buffer);
  }

  String _getHashPrevOuts(bool isTaproot) {
    String prevouts = '';
    for (TransactionInput input in inputs) {
      prevouts += Codec.encodeHex(input._transactionHash) +
          Codec.encodeHex(input._index);
    }
    //print("prevouts : " + prevouts);
    if (isTaproot) {
      return Hash.sha256fromHex(prevouts);
    } else {
      return Hash.sha256fromHex(Hash.sha256fromHex(prevouts));
    }
  }

  String getHashAmounts(List<int> amountList) {
    List<int> buffer = [];
    for (int amount in amountList) {
      buffer.addAll(Converter.intToLittleEndianBytes(amount, 8));
    }
    return Hash.sha256fromHex(Codec.encodeHex(buffer));
  }

  String _getHashScriptPublicKey(List<String> scriptList) {
    String buffer = '';
    for (String script in scriptList) {
      buffer += script;
    }
    return Hash.sha256fromHex(buffer);
  }

  String _getHashSequence(bool isTaproot) {
    String sequences = '';
    for (TransactionInput input in inputs) {
      sequences += Codec.encodeHex(input._sequence);
    }
    if (isTaproot) {
      return Hash.sha256fromHex(sequences);
    } else {
      return Hash.sha256fromHex(Hash.sha256fromHex(sequences));
    }
  }

  String _getHashOutputs(bool isTaproot) {
    String outputs = '';
    for (TransactionOutput output in this.outputs) {
      outputs += output.serialize();
    }
    if (isTaproot) {
      return Hash.sha256fromHex(outputs);
    } else {
      return Hash.sha256fromHex(Hash.sha256fromHex(outputs));
    }
  }

  String _getOutPoint(int index) {
    String outpoint = '';
    outpoint += Codec.encodeHex(inputs[index]._transactionHash) +
        Codec.encodeHex(inputs[index]._index);
    //print(outpoint);
    return outpoint;
  }

  /// check if the signature is valid in the transaction.
  bool validateEcdsa(int inputIndex, TransactionOutput utxo,
      {String? witnessScript}) {
    // get address type from utxo
    late AddressType utxoAddressType;
    if (utxo.scriptPubKey.isP2wpkh()) {
      utxoAddressType = AddressType.p2wpkh;
    } else if (utxo.scriptPubKey.isP2wsh()) {
      utxoAddressType = AddressType.p2wsh;
    } else {
      throw Exception('Unsupported Address Type');
    }

    // 1. Generate sigHash
    String sigHash;
    if (utxoAddressType == AddressType.p2wpkh) {
      sigHash = getSigHash(inputIndex, utxo, utxoAddressType);
    } else if (utxoAddressType == AddressType.p2wsh) {
      sigHash = getSigHash(inputIndex, utxo, utxoAddressType,
          witnessScript: witnessScript);
    } else {
      throw Exception('Unsupported Address Type');
    }
    Uint8List msg = Codec.decodeHex(sigHash);

    // 2.Validate signature
    if (utxoAddressType == AddressType.p2wsh) {
      String script = inputs[inputIndex].witnessList.last;
      String size =
          Codec.encodeHex(Codec.encodeVariableInteger(script.length ~/ 2));
      MultisignatureScript witnessScript =
          MultisignatureScript.parse(size + script);

      List<Uint8List> signatures = [];

      for (int i = 1; i < inputs[inputIndex].witnessList.length - 1; i++) {
        signatures.add(Codec.decodeHex(inputs[inputIndex].witnessList[i]));
      }

      List<Uint8List> pubKeys = witnessScript.getPublicKeys();

      int requiredSigs = witnessScript.getRequiredSignature();

      if (signatures.length < requiredSigs) {
        return false;
      }

      int validSigs = 0;

      for (Uint8List sig in signatures) {
        for (Uint8List pub in pubKeys) {
          int rLen = sig[3];
          Uint8List r = sig.sublist(4, 4 + rLen);
          if (r[0] == 0) r = r.sublist(1);
          int sLen = sig[4 + rLen + 1];
          Uint8List s = sig.sublist(4 + rLen + 2, 4 + rLen + 2 + sLen);
          Uint8List rs = Uint8List.fromList([...r, ...s]);

          if (Ecc.verifyEcdsa(msg, pub, rs)) {
            validSigs += 1;
            continue;
          }
        }
      }
      return validSigs >= requiredSigs;
    } else if (utxoAddressType == AddressType.p2wpkh) {
      //validate single signature
      String signature;
      String publicKey;

      signature = inputs[inputIndex].witnessList[0];
      publicKey = inputs[inputIndex].witnessList[1];

      Uint8List sig = Codec.decodeHex(signature);
      Uint8List pub = Codec.decodeHex(publicKey);

      Uint8List rawSignature = Converter.derToRawSignature(sig);

      // int rLen = sig[3];
      // Uint8List r = sig.sublist(4, 4 + rLen);
      // if (r[0] == 0) r = r.sublist(1);
      // int sLen = sig[4 + rLen + 1];
      // Uint8List s = sig.sublist(4 + rLen + 2, 4 + rLen + 2 + sLen);
      // Uint8List rs = Uint8List.fromList([...r, ...s]);

      return Ecc.verifyEcdsa(msg, pub, rawSignature);
    } else {
      throw Exception('Unsupported Address Type');
    }
  }

  /// Validate taproot signature
  bool validateSchnorr(int inputIndex, List<TransactionOutput> utxoList) {
    Uint8List sigHash =
        Codec.decodeHex(getTaprootSigHash(inputIndex, utxoList));
    // Uint8List publicKey = Encoder.decodeHex(
    //     "02${TransactionOutput.parse(utxoList[inputIndex]).scriptPubKey.commands[1]}");
    Uint8List publicKey = utxoList[inputIndex].scriptPubKey.commands[1];
    Uint8List signature = Codec.decodeHex(inputs[inputIndex].witnessList[0]);
    bool isValid = Ecc.verifySchnorr(sigHash, publicKey, signature) ||
        Ecc.verifySchnorr(sigHash, publicKey, signature);
    return isValid;
  }

  /// Get the virtual byte size of the transaction.
  double getVirtualByte() {
    double totalByte = (Codec.decodeHex(serialize()).length) * 1.0;
    double witnessByte = 0;
    for (TransactionInput input in inputs) {
      for (int i = 0; i < input.witnessList.length; i++) {
        if (input.witnessList[i] != "00") {
          witnessByte += (input.witnessList[i].length / 2).floor();
          witnessByte += 1;
        } else {
          witnessByte += 1;
        }
      }
      witnessByte += 1;
    }

    double vByte;
    if (_isSegwit) {
      double nonWitnessByte = totalByte - witnessByte - 2.0;
      witnessByte = witnessByte + 2;
      vByte = (nonWitnessByte * 4 + witnessByte) / 4;
    } else {
      vByte = totalByte;
    }
    // print("vByte : $vByte");

    return vByte;
  }

  double estimateVirtualByte(AddressType addressType,
      {int? requiredSignature, int? totalSigner}) {
    if (!addressType.isSegwit) {
      return getVirtualByte();
    }

    double vByte = getVirtualByte();

    int sigSize = 73; // 72 + 1(length)
    int pubKeySize = 34; // 33 + 1(length)
    if (addressType.isTaproot) {
      sigSize = 65; // 64 + 1(length)
      pubKeySize = 0; // 32 + 1(length)
    }
    // int baseSize = Converter.hexToBytes(serializeSegwit()).length;
    int additionalWitnessSize = 0;

    // baseSize -= 2; //marker + flag
    // witnessSize += 2; //marker + flag
    // witnessSize += 1; //num of witness

    if (addressType == AddressType.p2wpkh ||
        addressType == AddressType.p2trKeyPathSpending) {
      int emptyWitness = 0;
      for (TransactionInput input in inputs) {
        if (input.witnessList.isEmpty) {
          additionalWitnessSize += (sigSize + pubKeySize);
          emptyWitness += 1;
        }
      }
      if (emptyWitness == inputs.length) {
        additionalWitnessSize += 1; // number of witness
      }
    } else if (addressType == AddressType.p2wsh) {
      if (requiredSignature == null || totalSigner == null) {
        throw ArgumentError(
            'requiredSignature and totalSignature is required for p2wsh');
      }
      int emptyWitness = 0;
      for (TransactionInput input in inputs) {
        if (input.witnessList.isEmpty) {
          emptyWitness += 1;
          additionalWitnessSize += 1; // 00
          additionalWitnessSize += requiredSignature * (sigSize);
          int scriptSize = 0;
          scriptSize += 3; // m,n,OP_CHECKMULTISIG
          scriptSize += totalSigner * (pubKeySize);
          additionalWitnessSize += scriptSize;
        }
      }
      if (emptyWitness == inputs.length) {
        additionalWitnessSize += 1; // number of witness
      }
    }

    vByte = vByte + (additionalWitnessSize / 4);
    return vByte;
  }

  /// Estimate the fee of the transaction.
  int estimateFee(double feeRatePerByte, AddressType addressType,
      {int? requiredSignature, int? totalSigner}) {
    double vByte = estimateVirtualByte(addressType,
        requiredSignature: requiredSignature, totalSigner: totalSigner);
    return (vByte * feeRatePerByte).ceil();
  }

  /// Add utxo to the transaction.
  void addInputWithUtxo(Utxo newUtxo, double feeRate, WalletBase wallet,
      {int? requiredSignature, int? totalSigner}) {
    for (TransactionInput input in inputs) {
      if (input.transactionHash == newUtxo.transactionHash &&
          input.index == newUtxo.index) {
        throw Exception('UTXO already exists in the transaction');
      }
    }

    if (_utxoList.contains(newUtxo)) {
      throw Exception('UTXO already exists in UTXO list');
    }

    TransactionInput input =
        TransactionInput.forPayment(newUtxo.transactionHash, newUtxo.index);
    inputs.add(input);
    _utxoList.add(newUtxo);
    TransactionOutput? changeOutput;
    String changeAddress =
        wallet.getAddressWithDerivationPath(changeAddressDerivationPath!);
    for (TransactionOutput output in outputs) {
      if (output.scriptPubKey.getAddress() == changeAddress) {
        changeOutput = output;
        break;
      }
    }

    if (changeOutput == null) {
      changeOutput =
          TransactionOutput.forPayment(0, changeAddress, isChangeOutput: true);
      outputs.add(changeOutput);
    }

    int fee = estimateFee(feeRate, wallet.addressType,
        requiredSignature: requiredSignature, totalSigner: totalSigner);
    int changeAmount = totalInputAmount - _getTotalSendingAmount() - fee;
    if (changeAmount < 0) {
      outputs.remove(changeOutput);
    } else {
      changeOutput.setAmount(changeAmount);

      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        outputs.remove(changeOutput);
      }
    }
    // if (changeAmount < _getDustThreshold(wallet.addressType)) {
    //   outputs.remove(changeOutput);
    // } else {
    //   changeOutput.setAmount(changeAmount);
    // }
  }

  /// Remove utxo from the transaction.
  void removeInputWithUtxo(Utxo utxoToRemove, double feeRate, WalletBase wallet,
      {int? requiredSignature, int? totalSigner}) {
    if (!_utxoList.contains(utxoToRemove)) {
      throw Exception('UTXO not found in the UTXO list');
    }

    TransactionInput? removeTarget;
    for (TransactionInput input in inputs) {
      if (input.transactionHash == utxoToRemove.transactionHash &&
          input.index == utxoToRemove.index) {
        removeTarget = input;
        break;
      }
    }
    if (removeTarget == null) {
      throw Exception('UTXO not found in the transaction');
    }

    String changeAddress =
        wallet.getAddressWithDerivationPath(changeAddressDerivationPath!);

    TransactionOutput changeOutput =
        TransactionOutput.forPayment(0, changeAddress, isChangeOutput: true);
    for (TransactionOutput output in outputs) {
      if (output.scriptPubKey.getAddress() == changeAddress) {
        changeOutput = output;
        break;
      }
    }

    for (TransactionInput input in inputs) {
      if (input.transactionHash == utxoToRemove.transactionHash &&
          input.index == utxoToRemove.index) {
        inputs.remove(input);
        break;
      }
    }
    _utxoList.remove(utxoToRemove);
    int fee = estimateFee(feeRate, wallet.addressType,
        requiredSignature: requiredSignature, totalSigner: totalSigner);
    int changeAmount = totalInputAmount - _getTotalSendingAmount() - fee;
    if (changeAmount < 0) {
      outputs.remove(changeOutput);
    } else {
      changeOutput.setAmount(changeAmount);

      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        outputs.remove(changeOutput);
      }
    }
  }

  void updateFeeRate(double feeRate, WalletBase wallet,
      {int? requiredSignature, int? totalSigner}) {
    int fee = estimateFee(feeRate, wallet.addressType,
        requiredSignature: requiredSignature, totalSigner: totalSigner);

    if (outputs.length == 1) {
      if (outputs[0].amount <= fee) {
        throw Exception('Not enough amount for sending.');
      }
      outputs[0].setAmount(totalInputAmount - fee);
      if (outputs[0].isDustOutput(wallet.addressType.isSegwit)) {
        throw Exception('Sending amount is under dust threshold.');
      }
    } else {
      String changeAddress =
          wallet.getAddressWithDerivationPath(changeAddressDerivationPath!);
      TransactionOutput changeOutput =
          TransactionOutput.forPayment(0, changeAddress, isChangeOutput: true);

      for (TransactionOutput output in outputs) {
        if (output.scriptPubKey.getAddress() == changeAddress) {
          changeOutput = output;
          break;
        }
      }
      int changeAmount = totalInputAmount - _getTotalSendingAmount() - fee;

      if (changeAmount < 0) {
        outputs.remove(changeOutput);
      } else {
        changeOutput.setAmount(changeAmount);

        if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
          outputs.remove(changeOutput);
        }
      }
    }
  }

  static int _getDustThreshold(AddressType addressType) {
    if (addressType == AddressType.p2wpkh) {
      return 294;
    } else if (addressType == AddressType.p2wsh || addressType.isTaproot) {
      return 330;
    } else if (addressType == AddressType.p2pkh) {
      return 546;
    } else if (addressType == AddressType.p2sh) {
      return 888;
    } else if (addressType == AddressType.p2wpkhInP2sh) {
      return 273;
    } else {
      throw Exception('Unsupported Address Type');
    }
  }
}
