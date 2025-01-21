part of '../../coconut_lib.dart';

/// Represents a transaction.
class Transaction {
  Uint8List _version;
  List<TransactionInput> _inputs;
  List<TransactionOutput> _outputs;
  Uint8List _lockTime;
  bool _isSegwit;
  late int? sendingAmount;
  late String? receiveAddress;
  late String? changeAddress;

  // Field for from Blockchain Ledger
  late List<UTXO> _utxoList = [];

  List<UTXO> get utxoList => _utxoList;
  int get totalInputAmount {
    int total = 0;
    for (UTXO utxo in _utxoList) {
      total += utxo.amount;
    }
    return total;
  }

  /// Get the version of the transaction.
  String get version => Converter.bytesToHex(_version);

  /// Get the inputs of the transaction.
  List<TransactionInput> get inputs => _inputs;

  /// Get the outputs of the transaction.
  List<TransactionOutput> get outputs => _outputs;

  /// Get the lock time of the transaction.
  String get lockTime => Converter.bytesToHex(_lockTime);

  /// Get the transaction hash.
  String get transactionHash {
    String hash = Hash.sha256fromHex(Hash.sha256fromHex(serializeLegacy()));
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
        total += Varints.encode(_inputs.length).length;
        for (TransactionInput input in _inputs) {
          total += input.length;
        }
        total += Varints.encode(_outputs.length).length;
        for (TransactionOutput output in _outputs) {
          total += output.length;
        }
        total += _lockTime.length;
        return total;
      }();

  /// @nodoc
  Transaction(this._version, this._inputs, this._outputs, this._lockTime,
      this._isSegwit);

  factory Transaction.withDefault(List<TransactionInput> inputs,
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
  factory Transaction.fromUtxoList(List<UTXO> utxoList, String receiveAddress,
      String changeAddress, int amount, int feeRate, WalletBase wallet,
      {int version = 2, int lockTime = 0}) {
    int totalInputAmount = 0;
    List<TransactionInput> inputs = [];
    List<TransactionOutput> outputs = [];
    for (UTXO utxo in utxoList) {
      totalInputAmount += utxo.amount;
      inputs.add(TransactionInput.forPayment(utxo.transactionHash, utxo.index));
    }

    TransactionOutput sendingOutput =
        TransactionOutput.forPayment(amount, receiveAddress);
    TransactionOutput changeOutput =
        TransactionOutput.forPayment(0, changeAddress);

    outputs.add(sendingOutput);
    outputs.add(changeOutput);

    Transaction tx = Transaction.withDefault(
        inputs, outputs, wallet.addressType,
        version: version, lockTime: lockTime);

    // print("Input : ${tx.inputs.length}, Output : ${tx.outputs.length}");

    double vByte = 0.0;
    if (wallet.addressType == AddressType.p2wpkh) {
      vByte = tx.estimateVirtualByte(wallet.addressType);
    } else if (wallet.addressType == AddressType.p2wsh) {
      MultisignatureWallet multisignatureWallet =
          wallet as MultisignatureWallet;
      vByte = tx.estimateVirtualByte(wallet.addressType,
          requiredSignature: multisignatureWallet.requiredSignature,
          totalSigner: multisignatureWallet.totalSigner);
    } else {
      throw Exception('Unsupported Address Type');
    }

    int fee = (vByte * feeRate).ceil();

    // print("Fee : $fee");
    int changeAmount = totalInputAmount - amount - fee;
    if (changeAmount < 0) {
      tx.outputs.remove(changeOutput);
    } else {
      changeOutput.setAmount(changeAmount);

      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        tx.outputs.remove(changeOutput);
      }
    }
    // int dust = _getDustThreshold(wallet.addressType);

    // if (changeAmount <= dust) {
    //   for (TransactionOutput output in tx.outputs) {
    //     if (output.scriptPubKey.getAddress() == changeAddress) {
    //       tx.outputs.remove(output);
    //       break;
    //     }
    //   }
    // } else {
    //   changeOutput.setAmount(changeAmount);
    // }
    tx.sendingAmount = amount;
    tx.receiveAddress = receiveAddress;
    tx.changeAddress = changeAddress;
    tx._utxoList = utxoList;
    return tx;
  }

  /// Create a transaction for simple payment.
  factory Transaction.forPayment(List<UTXO> utxoList, String receiveAddress,
      String changeAddress, int amount, int feeRate, WalletBase wallet,
      {int version = 2, int lockTime = 0}) {
    List<UTXO> selectedUtxoList =
        _selectOptimalUtxo(utxoList, amount, feeRate, wallet.addressType);

    return Transaction.fromUtxoList(selectedUtxoList, receiveAddress,
        changeAddress, amount, feeRate, wallet,
        version: version, lockTime: lockTime);
  }

  static List<UTXO> _selectOptimalUtxo(
      List<UTXO> utxos, int amount, int feeRate, AddressType addressType) {
    int baseVbyte = 72; //0 input, 2 output
    int vBytePerInput = 0;
    int dust = _getDustThreshold(addressType);
    if (addressType.isSegwit) {
      vBytePerInput = 68; //segwit discount
    } else {
      vBytePerInput = 148;
    }
    List<UTXO> selectedUtxos = [];

    int totalAmount = 0;
    int totalVbyte = baseVbyte;
    int finalFee = 0;
    utxos.sort((a, b) => b.amount.compareTo(a.amount));
    for (UTXO utxo in utxos) {
      // if (utxo.blockHeight == 0) {
      //   continue;
      // }
      selectedUtxos.add(utxo);
      totalAmount += utxo.amount;
      totalVbyte += vBytePerInput;
      int fee = totalVbyte * feeRate;
      if (totalAmount >= amount + fee + dust) {
        return selectedUtxos;
      }
      finalFee = fee;
    }
    throw Exception('Not enough amount for sending. (Fee : $finalFee)');
  }

  /// Create a transaction for sending all Bitcoin in the wallet.
  factory Transaction.forSweep(
      List<UTXO> utxoList, String address, int feeRate, WalletBase wallet,
      {int version = 2, int lockTime = 0}) {
    List<TransactionInput> inputs = [];
    List<TransactionOutput> outputs = [];
    int inputAmount = 0;
    for (UTXO utxo in utxoList) {
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

    TransactionOutput sendingOutput = TransactionOutput.forPayment(0, address);
    outputs.add(sendingOutput);

    Transaction tx = Transaction.withDefault(
        inputs, outputs, wallet.addressType,
        version: version, lockTime: lockTime);

    double vByte = 0.0;
    if (wallet.addressType == AddressType.p2wpkh) {
      vByte = tx.estimateVirtualByte(wallet.addressType);
    } else if (wallet.addressType == AddressType.p2wsh) {
      MultisignatureWallet multisignatureWallet =
          wallet as MultisignatureWallet;
      vByte = tx.estimateVirtualByte(wallet.addressType,
          requiredSignature: multisignatureWallet.requiredSignature,
          totalSigner: multisignatureWallet.totalSigner);
    } else {
      throw Exception('Unsupported Address Type');
    }

    int fee = (vByte * feeRate).ceil();

    if (inputAmount < fee) {
      throw Exception('Not enough amount for sending. (Fee : $fee)');
    }

    sendingOutput.setAmount(inputAmount - fee);

    // Transaction tx = Transaction.forMaximumSending(
    //     inputs, address, inputAmount, wallet.addressType, feeRate);
    // print(tx.serialize());
    tx._utxoList = utxoList;
    return tx;
  }

  /// Parse the transaction.
  factory Transaction.parse(String transaction,
      {bool isEmptySignature = false}) {
    Uint8List txBytes = Converter.hexToBytes(transaction);

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

  factory Transaction._parseSegwit(Uint8List txBytes) {
    int offset = 0;
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;
    Uint8List marker = txBytes.sublist(offset, offset + 2);
    offset += 2;
    if (!(marker[0] == 0x00 && marker[1] == 0x01)) {
      throw Exception('Transaction : Not a segwit transaction maker');
    }
    int numInputs = Varints.read(txBytes, offset);
    //print(numInputs);
    offset += 1;
    List<TransactionInput> inputs = [];
    //print(Converter.bytesToHex(txBytes.sublist(offset)));
    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Converter.bytesToHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      //print("size:" + size.toString());
      offset += size;
    }
    int numOutputs = Varints.read(txBytes, offset);
    offset += 1;
    //print(numOutputs);
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    //witness
    for (TransactionInput txIn in inputs) {
      int numItems = Varints.read(txBytes, offset++);
      List items = [];
      for (int i = 0; i < numItems; i++) {
        int itemLen = Varints.read(txBytes, offset);
        offset++;
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
          txIn.witnessList.add(Converter.bytesToHex(item));
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
    int numInputs = Varints.read(txBytes, offset);
    //print("numInputs : $numInputs");
    offset += 1;
    List<TransactionInput> inputs = [];
    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Converter.bytesToHex(txBytes.sublist(offset)));
      // print("input : ${input.serialize()}");
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      //print("size:" + size.toString());
      offset += size;
      // print("script : ${input.scriptSig.serialize()}");
      // print("input : ${input.serialize()}");
    }

    int numOutputs = Varints.read(txBytes, offset);
    offset++;
    // print("numOutputs : $numOutputs");
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
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
    Uint8List txBytes = Converter.hexToBytes(transaction);
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;

    int numInputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionInput> inputs = [];

    for (int i = 0; i < numInputs; i++) {
      TransactionInput input = TransactionInput.parseForPsbt(
          Converter.bytesToHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      //print("size:" + size.toString());
      offset += size;
      // print("input : " + input.transactionHash);
      // print("input index : " + input.index.toString());
      // print("input script : " + input.scriptSig.serialize());
      // print("input sequence : " + input.sequence.toString());
    }

    int numOutputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
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
      return serializeSegwit();
    } else {
      return serializeLegacy();
    }
  }

  /// Serialize to segwit transaction.
  String serializeSegwit() {
    String serialized = '';
    serialized += version;
    serialized += '0001';
    serialized += Converter.bytesToHex(Varints.encode(inputs.length));
    for (int i = 0; i < inputs.length; i++) {
      serialized += inputs[i].serialize();
    }
    serialized += Converter.bytesToHex(Varints.encode(outputs.length));
    for (int i = 0; i < outputs.length; i++) {
      serialized += outputs[i].serialize();
    }

    //serialize witness
    for (int i = 0; i < inputs.length; i++) {
      serialized +=
          Converter.bytesToHex(Varints.encode(inputs[i].witnessList.length));

      //if the script is p2wpkh or else
      for (int j = 0; j < inputs[i].witnessList.length; j++) {
        if (inputs[i].witnessList[j].isEmpty ||
            inputs[i].witnessList[j] == '00') {
          serialized += '00';
        } else {
          int size = inputs[i].witnessList[j].length ~/ 2;
          serialized += Converter.decToHex(size);
          serialized += inputs[i].witnessList[j];
        }
      }
    }

    serialized += lockTime;
    return serialized;
  }

  /// Serialize to legacy transaction.
  String serializeLegacy() {
    String serialized = '';
    serialized += version;
    serialized += Converter.bytesToHex(Varints.encode(inputs.length));
    for (int i = 0; i < inputs.length; i++) {
      serialized += inputs[i].serialize();
    }
    serialized += Converter.bytesToHex(Varints.encode(outputs.length));
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
  String getSigHash(int index, String utxo, AddressType addressType,
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

  String _getLegacySigHash(int index, String utxo, int hashType) {
    String thisTx = serialize();
    Transaction forSig = Transaction.parse(thisTx);
    for (int i = 0; i < forSig.inputs.length; i++) {
      if (i == index) {
        String pubkey = TransactionOutput.parse(utxo).scriptPubKey.serialize();
        forSig.inputs[i].scriptSig = ScriptSignature.parse(pubkey);
      } else {
        forSig.inputs[i].scriptSig = ScriptSignature.parse('00');
      }
    }
    String type =
        Converter.bytesToHex(Converter.intToLittleEndianBytes(hashType, 4));
    String sigHash = forSig.serialize() + type;
    return Hash.sha256(sigHash);
  }

  //BIP143
  String _getSegwitSigHash(
      int index, String utxo, int hashType, AddressType addressType,
      {String? witnessScript}) {
    String sigHash = '';
    sigHash += version;
    sigHash += _getHashPrevOuts();
    //print("prevouts : " + _getHashPrevOuts());
    sigHash += _getHashSequence();
    sigHash += _getOutPoint(index);
    TransactionOutput prevUtxo = TransactionOutput.parse(utxo);
    if (addressType == AddressType.p2wpkh) {
      sigHash +=
          "1976a914${Converter.bytesToHex(prevUtxo.scriptPubKey.commands[1])}88ac";
    } else if (addressType == AddressType.p2wsh) {
      if (witnessScript == null) {
        throw ArgumentError('witnessScript is required for p2wsh');
      }
      int length = witnessScript.length ~/ 2;
      sigHash += Converter.bytesToHex(Varints.encode(length));
      sigHash += witnessScript;
    } else {
      sigHash += prevUtxo.scriptPubKey.serialize();
    }

    sigHash += Converter.bytesToHex(
        Converter.intToLittleEndianBytes(prevUtxo.amount, 8));
    sigHash += Converter.bytesToHex(
        Converter.intToLittleEndianBytes(inputs[index].sequence, 4));
    sigHash += _getHashOutputs();
    sigHash += lockTime;
    sigHash +=
        Converter.bytesToHex(Converter.intToLittleEndianBytes(hashType, 4));

    return Hash.sha256fromHex(Hash.sha256fromHex(sigHash));
  }

  String _getHashPrevOuts() {
    String prevouts = '';
    for (TransactionInput input in inputs) {
      prevouts += Converter.bytesToHex(input._transactionHash) +
          Converter.bytesToHex(input._index);
    }
    //print("prevouts : " + prevouts);
    return Hash.sha256fromHex(Hash.sha256fromHex(prevouts));
  }

  String _getHashSequence() {
    String sequences = '';
    for (TransactionInput input in inputs) {
      sequences += Converter.bytesToHex(input._sequence);
    }
    String hashSequence = Hash.sha256fromHex(Hash.sha256fromHex(sequences));
    return hashSequence;
  }

  String _getHashOutputs() {
    String outputs = '';
    for (TransactionOutput output in this.outputs) {
      outputs += output.serialize();
    }
    return Hash.sha256fromHex(Hash.sha256fromHex(outputs));
  }

  String _getOutPoint(int index) {
    String outpoint = '';
    outpoint += Converter.bytesToHex(inputs[index]._transactionHash) +
        Converter.bytesToHex(inputs[index]._index);
    //print(outpoint);
    return outpoint;
  }

  /// check if the signature is valid in the transaction.
  bool validateSignature(int inputIndex, String utxo, AddressType addressType,
      {String? witnessScript}) {
    String sigHash;
    if (addressType == AddressType.p2wpkh) {
      sigHash = getSigHash(inputIndex, utxo, addressType);
    } else if (addressType == AddressType.p2wsh) {
      if (witnessScript == null) {
        throw ArgumentError('witnessScript is required for p2wsh');
      }
      sigHash = getSigHash(inputIndex, utxo, addressType,
          witnessScript: witnessScript);
    } else {
      throw Exception('Unsupported Address Type');
    }
    Uint8List msg = Converter.hexToBytes(sigHash);

    if (addressType == AddressType.p2wsh) {
      String script = inputs[inputIndex].witnessList.last;
      String size = Converter.bytesToHex(Varints.encode(script.length ~/ 2));
      WitnessScript witnessScript = WitnessScript.parse(size + script);

      List<Uint8List> signatures = [];

      for (int i = 1; i < inputs[inputIndex].witnessList.length - 1; i++) {
        signatures.add(Converter.hexToBytes(inputs[inputIndex].witnessList[i]));
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

          if (ecc.verify(msg, pub, rs)) {
            validSigs += 1;
            continue;
          }
        }
      }
      return validSigs >= requiredSigs;
    } else if (addressType == AddressType.p2wpkh) {
      //validate single signature
      String signature;
      String publicKey;

      signature = inputs[inputIndex].witnessList[0];
      publicKey = inputs[inputIndex].witnessList[1];

      Uint8List sig = Converter.hexToBytes(signature);
      Uint8List pub = Converter.hexToBytes(publicKey);

      int rLen = sig[3];
      Uint8List r = sig.sublist(4, 4 + rLen);
      if (r[0] == 0) r = r.sublist(1);
      int sLen = sig[4 + rLen + 1];
      Uint8List s = sig.sublist(4 + rLen + 2, 4 + rLen + 2 + sLen);
      Uint8List rs = Uint8List.fromList([...r, ...s]);

      return ecc.verify(msg, pub, rs);
    } else {
      throw Exception('Unsupported Address Type');
    }
  }

  /// Get the virtual byte size of the transaction.
  double getVirtualByte() {
    double totalByte = (Converter.hexToBytes(serialize()).length) * 1.0;
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

    const int sigSize = 73; // 72 + 1(length)
    const int pubKeySize = 34; // 33 + 1(length)

    // int baseSize = Converter.hexToBytes(serializeSegwit()).length;
    int additionalWitnessSize = 0;

    // baseSize -= 2; //marker + flag
    // witnessSize += 2; //marker + flag
    // witnessSize += 1; //num of witness

    if (addressType == AddressType.p2wpkh) {
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

  int calculateFeeWithWitnessSize(int feeRatePerByte, int witnessSize) {
    return ((getVirtualByte() - witnessSize) * feeRatePerByte).ceil();
  }

  /// Estimate the fee of the transaction.
  int estimateFee(int feeRatePerByte, AddressType addressType,
      {int? requiredSignature, int? totalSinger}) {
    // bool hasSignatureLength = !hasNoSignature();
    // int unsignedInput = 0;
    // double vByte = getVirtualByte();
    // int sigByte = 106;
    // for (TransactionInput input in inputs) {
    //   if (!input.hasSignature(_isSegwit)) {
    //     unsignedInput++;
    //   }
    // }
    // if (_isSegwit) {
    //   double additionalByte = 4.0;
    //   additionalByte += unsignedInput * sigByte;
    //   if (!hasSignatureLength) {
    //     additionalByte += 2;
    //   }
    //   vByte += (additionalByte / 4);
    // } else {
    //   vByte += unsignedInput * sigByte;
    // }
    // print("vByte : $vByte");
    double vByte = estimateVirtualByte(addressType,
        requiredSignature: requiredSignature, totalSigner: totalSinger);
    return (vByte * feeRatePerByte).ceil();
  }

  /// Check if the transaction has no signature.
  bool hasNoSignature() {
    for (TransactionInput input in inputs) {
      if (input.hasSignature(_isSegwit)) {
        return false;
      }
    }
    return true;
  }

  /// Check if the all inputs have a signature.
  bool hasAllSignature() {
    for (TransactionInput input in inputs) {
      if (!input.hasSignature(_isSegwit)) {
        return false;
      }
    }
    return true;
  }

  /// Add utxo to the transaction.
  void addInputWithUtxo(UTXO newUtxo, int feeRate, WalletBase wallet,
      {int? requiredSignature, int? totalSinger}) {
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
    for (TransactionOutput output in outputs) {
      if (output.scriptPubKey.getAddress() == changeAddress) {
        changeOutput = output;
        break;
      }
    }

    if (changeOutput == null) {
      changeOutput = TransactionOutput.forPayment(0, changeAddress!);
      outputs.add(changeOutput);
    }

    int fee = estimateFee(feeRate, wallet.addressType,
        requiredSignature: requiredSignature, totalSinger: totalSinger);
    int changeAmount = totalInputAmount - sendingAmount! - fee;

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
  void removeInputWithUtxo(UTXO utxoToRemove, int feeRate, WalletBase wallet,
      {int? requiredSignature, int? totalSinger}) {
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

    TransactionOutput changeOutput =
        TransactionOutput.forPayment(0, changeAddress!);
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
        requiredSignature: requiredSignature, totalSinger: totalSinger);
    int changeAmount = totalInputAmount - sendingAmount! - fee;
    if (changeAmount < 0) {
      outputs.remove(changeOutput);
    } else {
      changeOutput.setAmount(changeAmount);

      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        outputs.remove(changeOutput);
      }
    }
  }

  void updateFeeRate(int feeRate, WalletBase wallet,
      {int? requiredSignature, int? totalSinger}) {
    int fee = estimateFee(feeRate, wallet.addressType,
        requiredSignature: requiredSignature, totalSinger: totalSinger);
    TransactionOutput changeOutput =
        TransactionOutput.forPayment(0, changeAddress!);

    for (TransactionOutput output in outputs) {
      if (output.scriptPubKey.getAddress() == changeAddress) {
        changeOutput = output;
        break;
      }
    }
    int changeAmount = totalInputAmount - sendingAmount! - fee;
    if (changeAmount < 0) {
      outputs.remove(changeOutput);
    } else {
      changeOutput.setAmount(changeAmount);

      if (changeOutput.isDustOutput(wallet.addressType.isSegwit)) {
        outputs.remove(changeOutput);
      }
    }
  }

  static int _getDustThreshold(AddressType addressType) {
    if (addressType == AddressType.p2wpkh) {
      return 294;
    } else if (addressType == AddressType.p2wsh) {
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
