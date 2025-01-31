part of '../../coconut_lib.dart';

/// Represents a PSBT(BIP-0174).
class PSBT {
  /// @nodoc
  Map<String, dynamic> psbtMap;

  /// Get transaction not signed yet.
  Transaction? unsignedTransaction;

  /// @nodoc
  List<PsbtInput> inputs = [];

  /// @nodoc
  List<PsbtOutput> outputs = [];

  /// @nodoc
  List<DerivationPath> derivationPathList = [];

  /// Get the fee of the transaction.
  int get fee => () {
        int totalInput = 0;
        int totalOutput = 0;
        for (int i = 0; i < inputs.length; i++) {
          totalInput += inputs[i].witnessUtxo!.amount;
        }
        for (int i = 0; i < unsignedTransaction!.outputs.length; i++) {
          totalOutput += unsignedTransaction!.outputs[i].amount;
        }
        return totalInput - totalOutput;
      }();

  /// Get the sending amount of the transaction.
  int get sendingAmount => () {
        int sendingAmount = 0;
        for (PsbtOutput output in outputs) {
          if (output.derivationPath != null && output.isChange) continue;
          sendingAmount += output.amount!;
        }

        return sendingAmount;
      }();

  /// @nodoc
  PSBT(this.psbtMap) {
    unsignedTransaction =
        Transaction.parseUnsignedTransaction(psbtMap["global"]["00"]);

    psbtMap["global"].keys.forEach((key) {
      if (key.startsWith('01')) {
        String publicKey = key.substring(2);
        String masterFingerprint = psbtMap["global"][key].substring(0, 8);
        String derivationPath = _parseDerivationPath(
            Converter.hexToBytes(psbtMap["global"][key].substring(8)));
        derivationPathList
            .add(DerivationPath(publicKey, masterFingerprint, derivationPath));
      }
    });

    for (int i = 0; i < psbtMap["inputs"].length; i++) {
      Transaction? prevTx;
      if (psbtMap["inputs"][i].containsKey("00")) {
        prevTx = Transaction.parse(psbtMap["inputs"][i]["00"]);
      }
      TransactionOutput? witnessUtxo;
      if (psbtMap["inputs"][i].containsKey("01")) {
        witnessUtxo = TransactionOutput.parse(psbtMap["inputs"][i]["01"]);
      }

      List<DerivationPath> inputDerivationPathList = [];
      List<Signature> partialSigList = [];
      MultisignatureScript? witnessScript;

      psbtMap["inputs"][i].keys.forEach((key) {
        // 06 : BIP32_DERIVATION
        if (key.startsWith('06')) {
          String publicKey = key.substring(2);
          String masterFingerprint = psbtMap["inputs"][i][key].substring(0, 8);
          String derivationPath = _parseDerivationPath(
              Converter.hexToBytes(psbtMap["inputs"][i][key].substring(8)));
          inputDerivationPathList.add(
              DerivationPath(publicKey, masterFingerprint, derivationPath));
        }
        // 02 : PARTIAL_SIG
        if (key.startsWith('02')) {
          String publicKey = key.substring(2);
          String signature = psbtMap["inputs"][i][key];
          partialSigList.add(Signature(signature, publicKey));
        }
        // 05 : WITNESS_SCRIPT
        if (key.startsWith('05')) {
          String script = psbtMap["inputs"][i][key];
          String size = Converter.bytesToHex(
              Encoder.encodeVariableInteger(script.length ~/ 2));
          witnessScript = MultisignatureScript.parse(size + script);
        }
      });
      inputs.add(PsbtInput(
          prevTx, witnessUtxo, inputDerivationPathList, partialSigList,
          witnessScript: witnessScript));
    }

    for (int i = 0; i < psbtMap["outputs"].length; i++) {
      int? amount;
      String? script;
      if (psbtMap["outputs"][i].containsKey("03")) {
        amount = Converter.littleEndianToInt(
            Converter.hexToBytes(psbtMap["outputs"][i]["03"]));
      }

      if (psbtMap["outputs"][i].containsKey("04")) {
        script = psbtMap["outputs"][i]["04"];
      }

      DerivationPath? outputDerivationPath;
      psbtMap["outputs"][i].keys.forEach((key) {
        if (key.startsWith('02')) {
          String publicKey = key.substring(2);
          String masterFingerprint = psbtMap["outputs"][i][key].substring(0, 8);
          String derivationPath = _parseDerivationPath(
              Converter.hexToBytes(psbtMap["outputs"][i][key].substring(8)));
          outputDerivationPath =
              DerivationPath(publicKey, masterFingerprint, derivationPath);
        }
      });
      outputs.add(PsbtOutput(outputDerivationPath, amount, script));
    }
  }

  /// Generate the PSBT to base64 string.
  String serialize() {
    List<int> psbtBytes = [0x70, 0x73, 0x62, 0x74, 0xff];
    //Global
    psbtBytes.addAll(_serializeKeyMap(psbtMap["global"]));
    psbtBytes.add(0x00);
    List<dynamic> inputList = psbtMap["inputs"];
    for (int i = 0; i < inputList.length; i++) {
      psbtBytes.addAll(_serializeKeyMap(inputList[i]));
      psbtBytes.add(0x00);
    }
    List<dynamic> outputList = psbtMap["outputs"];
    for (int i = 0; i < outputList.length; i++) {
      psbtBytes.addAll(_serializeKeyMap(outputList[i]));
      psbtBytes.add(0x00);
    }

    psbtBytes.add(0x00);
    return base64Encode(psbtBytes);
  }

  List<int> _serializeKeyMap(Map<String, dynamic> map) {
    List<int> globalBytes = [];
    map.forEach((key, value) {
      List<int> keyBytes = Converter.hexToBytes(key);
      globalBytes += Encoder.encodeVariableInteger(keyBytes.length);
      globalBytes += keyBytes;
      List<int> valueBytes = Converter.hexToBytes(value);
      globalBytes += Encoder.encodeVariableInteger(valueBytes.length);
      globalBytes += valueBytes;
    });
    return globalBytes;
  }

  /// Create a PSBT from a Transaction object.
  factory PSBT.fromTransaction(Transaction tx, WalletBase wallet) {
    if (!wallet.addressType.isSegwit) {
      throw Exception('Only Segwit address type is supported');
    }

    if (tx.utxoList.isEmpty) {
      throw Exception('No UTXOs in transaction');
    }
    for (int i = 0; i < tx.inputs.length; i++) {
      if (tx.inputs[i].transactionHash != tx.utxoList[i].transactionHash) {
        throw Exception('Transaction input and UTXO list mismatch');
      }
    }

    late SingleSignatureWalletBase singleSignatureWallet;
    if (wallet is SingleSignatureWalletBase) {
      singleSignatureWallet = wallet;
    }

    late MultisignatureWalletBase multisignatureWallet;
    if (wallet is MultisignatureWalletBase) {
      multisignatureWallet = wallet;
    }

    Map<String, dynamic> psbtData = {"global": {}, "inputs": [], "outputs": []};

    //--- Global
    Map<String, dynamic> globalData = {};
    String txKey = getKeyType(globalKeyType, 'UNSIGNED_TX');
    globalData[txKey] = tx._serializeLegacy(); //old serialze format BIP0174
    psbtData["global"] = globalData;

    //input
    for (int i = 0; i < tx.inputs.length; i++) {
      Map<String, dynamic> inputData = {};

      String receivedAddress =
          wallet.getAddressWithDerivationPath(tx.utxoList[i].derivationPath);
      TransactionOutput output =
          TransactionOutput.forPayment(tx.utxoList[i].amount, receivedAddress);
      String witnessUtxoKey = getKeyType(inputKeyType, 'WITNESS_UTXO');
      inputData[witnessUtxoKey] = output.serialize();

      //derivation path
      String bip32DerivationKeyType =
          getKeyType(inputKeyType, 'BIP32_DERIVATION');
      if (wallet is SingleSignatureWalletBase) {
        String publicKey = singleSignatureWallet.keyStore
            .getPublicKeyWithDerivationPath(tx.utxoList[i].derivationPath);
        String fingerPrint = singleSignatureWallet.keyStore.masterFingerprint;

        inputData[bip32DerivationKeyType + publicKey] = fingerPrint +
            Converter.bytesToHex(
                _serializeDerivationPath(tx.utxoList[i].derivationPath));
      } else if (wallet is MultisignatureWalletBase) {
        for (KeyStore keyStore in multisignatureWallet.keyStoreList) {
          String publicKey = keyStore
              .getPublicKeyWithDerivationPath(tx.utxoList[i].derivationPath);
          String fingerPrint = keyStore.masterFingerprint;
          inputData[bip32DerivationKeyType + publicKey] = fingerPrint +
              Converter.bytesToHex(
                  _serializeDerivationPath(tx.utxoList[i].derivationPath));
        }
      }
      if (tx.inputs[i].witnessList.isNotEmpty) {
        String partialSigKeyType = getKeyType(inputKeyType, 'PARTIAL_SIG');
        String publicKey = tx.inputs[i].witnessList[0];
        String signature = tx.inputs[i].witnessList[1];
        inputData[partialSigKeyType + publicKey] = signature;
      }

      if (wallet.addressType == AddressType.p2wsh) {
        String witnessScriptKey = getKeyType(inputKeyType, 'WITNESS_SCRIPT');
        String witnessScript = multisignatureWallet
            .getWitnessScript(tx.utxoList[i].derivationPath);
        inputData[witnessScriptKey] = witnessScript;
      }
      psbtData["inputs"].add(inputData);
    }

    //output
    for (int i = 0; i < tx.outputs.length; i++) {
      Map<String, dynamic> outputData = {};
      String amountKey = getKeyType(outputKeyType, 'AMOUNT');
      outputData[amountKey] = Converter.bytesToHex(
          Converter.intToLittleEndianBytes(tx.outputs[i].amount, 4));
      String scriptKey = getKeyType(outputKeyType, 'SCRIPT');
      outputData[scriptKey] = tx.outputs[i].scriptPubKey.serialize();
      psbtData["outputs"].add(outputData);
    }

    PSBT psbt = PSBT(psbtData);

    //check input amount is enough
    int totalInputAmount = 0;
    for (PsbtInput input in psbt.inputs) {
      totalInputAmount += input.witnessUtxo!.amount;
    }
    int totalOutputAmount = 0;
    for (PsbtOutput output in psbt.outputs) {
      totalOutputAmount += output.amount!;
    }
    if (totalOutputAmount > totalInputAmount) {
      throw Exception('Not enough input amount');
    }

    return psbt;
  }

  /// Parse a PSBT from a base64 string.
  factory PSBT.parse(String psbtBase64) {
    int offset = 0;

    Uint8List psbtBytes = base64Decode(psbtBase64);
    final version = psbtBytes.sublist(0, 5);
    if (version[0] != 0x70 ||
        version[1] != 0x73 ||
        version[2] != 0x62 ||
        version[3] != 0x74 ||
        version[4] != 0xff) {
      throw Exception('Invalid PSBT');
    }
    offset += 5;

    Map<String, dynamic> psbtData = {"global": {}, "inputs": [], "outputs": []};

    // Global
    Map<String, String> globalMap = {};
    // print(' ---> GLOBAL ---');
    while (true) {
      int keyLen = Encoder.decodeVariableInteger(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      if (keyLen == 0) {
        break;
      }
      Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
      offset += keyLen;
      int valueLen = Encoder.decodeVariableInteger(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
      offset += valueLen;
      globalMap[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
    }
    psbtData["global"] = globalMap;

    // Inputs
    if (psbtData["global"]["00"] == null) {
      throw Exception('Invalid PSBT');
    }
    Transaction globalTx =
        Transaction.parseUnsignedTransaction(psbtData["global"]["00"]);

    for (int i = 0; i < globalTx.inputs.length; i++) {
      Map<String, String> inputData = {};
      while (true) {
        int keyLen = Encoder.decodeVariableInteger(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Encoder.decodeVariableInteger(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        inputData[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
      }
      psbtData["inputs"].add(inputData);
    }

    // Outputs
    for (int i = 0; i < globalTx.outputs.length; i++) {
      Map<String, String> outputData = {};
      while (true) {
        int keyLen = Encoder.decodeVariableInteger(psbtBytes, offset);
        // print(' -key len ${keyLen.toString()}-');
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Encoder.decodeVariableInteger(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        outputData[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
      }
      psbtData["outputs"].add(outputData);
    }

    return PSBT(psbtData);
  }

  /// Add a signature to the PSBT.
  void addSignature(int inputIndex, String signature, String publicKey) {
    inputs[inputIndex].addSignature(signature, publicKey);
    psbtMap["inputs"][inputIndex]["02$publicKey"] = signature;
  }

  bool isSigned(KeyStore keyStore) {
    bool isSigned = false;
    for (PsbtInput input in inputs) {
      for (DerivationPath path in input._derivationPathList) {
        if (keyStore.masterFingerprint == path.masterFingerprint) {
          isSigned = true;
          String publicKey = keyStore.getPublicKeyWithDerivationPath(path.path);
          if (!input.partialSigList
              .any((element) => element.publicKey == publicKey)) {
            return false;
          }
        }
      }
    }

    return isSigned;
  }

  static int _getOffset(int prefix) {
    if (prefix == 0xfd) {
      return 3;
    } else if (prefix == 0xfe) {
      return 5;
    } else if (prefix == 0xff) {
      return 9;
    }
    return 1;
  }

  /// @nodoc
  static Map<int, String> globalKeyType = {
    0: 'UNSIGNED_TX',
    1: 'XPUB',
    2: 'TX_VERSION',
    3: 'LOCKTIME',
    4: 'TX_IN_COUNT',
    5: 'TX_OUT_COUNT',
    6: 'TX_MODIFIABLE',
    251: 'VERSION',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static Map<int, String> inputKeyType = {
    0: 'NON_WITNESS_UTXO',
    1: 'WITNESS_UTXO',
    2: 'PARTIAL_SIG',
    3: 'SIGHASH_TYPE',
    4: 'REDEEM_SCRIPT',
    5: 'WITNESS_SCRIPT',
    6: 'BIP32_DERIVATION',
    7: 'FINAL_SCRIPTSIG',
    8: 'FINAL_SCRIPTWITNESS',
    9: 'POR_COMMITMENT',
    10: 'RIPEMD160',
    11: 'SHA256',
    12: 'HASH160',
    13: 'HASH256',
    14: 'PREVIOUS_TXID',
    15: 'OUTPUT_INDEX',
    16: 'SEQUENCE',
    17: 'REQUIRED_TIME_LOCKTIME',
    18: 'REQUIRED_HEIGHT_LOCKTIME',
    19: 'TAP_KEY_SIG',
    20: 'TAP_SCRIPT_SIG',
    21: 'TAP_LEAF_SCRIPT',
    22: 'TAP_BIP32_DERIVATION',
    23: 'TAP_INTERNAL_KEY',
    24: 'TAP_MERKLE_ROOT',
    25: 'REQUIRED_HEIGHT_LOCKTIME',
    26: 'REQUIRED_HEIGHT_LOCKTIME',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static Map<int, String> outputKeyType = {
    0: 'REDEEM_SCRIPT',
    1: 'WITNESS_SCRIPT',
    2: 'BIP32_DERIVATION',
    3: 'AMOUNT',
    4: 'SCRIPT',
    5: 'TAP_INTERNAL_KEY',
    6: 'TAP_TREE',
    7: 'TAP_BIP32_DERIVATION',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static String getKeyType(Map<int, String> keyTypeMap, String typeName) {
    return Converter.decToHexWithPadding(
        globalKeyType.keys
            .firstWhere((element) => keyTypeMap[element] == typeName),
        2);
  }

  /// @nodoc
  static Uint8List _serializeDerivationPath(String derivationPath) {
    final path = derivationPath.split('/').sublist(1).map((e) {
      if (e.contains('\'')) {
        return int.parse(e.replaceAll('\'', '')) + 0x80000000;
      } else {
        return int.parse(e);
      }
    }).toList();

    List<int> serializedPath = [];

    for (var index in path) {
      serializedPath.addAll(Converter.intToLittleEndianBytes(index, 4));
    }
    return Uint8List.fromList(serializedPath);
  }

  /// @nodoc
  static String _parseDerivationPath(Uint8List serializedPath) {
    if (serializedPath.length % 4 != 0) {
      throw ArgumentError('Serialized path length must be a multiple of 4');
    }

    List<String> pathSegments = ['m'];

    for (int i = 0; i < serializedPath.length; i += 4) {
      Uint8List valueBytes = serializedPath.sublist(i, i + 4);
      int value = Converter.littleEndianToInt(valueBytes);

      if (value & 0x80000000 != 0) {
        value &= ~0x80000000;
        pathSegments.add('$value\'');
      } else {
        pathSegments.add('$value');
      }
    }

    return pathSegments.join('/');
  }

  /// Get the transaction if all inputs are signed.
  Transaction getSignedTransaction(AddressType addressType) {
    Transaction signedTransaction =
        Transaction.parseUnsignedTransaction(unsignedTransaction!.serialize());
    signedTransaction._isSegwit = addressType.isSegwit;
    if (addressType == AddressType.p2wsh) {
      for (int i = 0; i < inputs.length; i++) {
        if (inputs[i].partialSigList.length < inputs[i].requiredSignature) {
          throw Exception('Not enough signatures');
        }
        signedTransaction.inputs[i].setSignature(
            addressType, inputs[i].partialSigList,
            witnessScript: inputs[i].witnessScript);

        if (signedTransaction.validateSignature(
            i, inputs[i].witnessUtxo!.serialize(), addressType,
            witnessScript: inputs[i].witnessScript!.rawSerialize())) {
          continue;
        } else {
          throw Exception('Invalid Signatures');
        }
      }
    } else if (addressType == AddressType.p2wpkh) {
      //every input should have 2 partial sigs
      for (int i = 0; i < inputs.length; i++) {
        if (inputs[i].partialSigList.length != 1) {
          throw Exception('Not enough signatures');
        }
        signedTransaction.inputs[i]
            .setSignature(addressType, inputs[i].partialSigList);
        if (signedTransaction.validateSignature(
            i, inputs[i].witnessUtxo!.serialize(), addressType)) {
          continue;
        } else {
          throw Exception('Invalid Signatures');
        }
      }
    } else {
      throw Exception('Unsupported Address Type');
    }
    return signedTransaction;
  }

  /// Get estimated fee for the transaction.
  int estimateFee(int feeRate, AddressType addressType,
      {int? requiredSignature, int? totalSigner}) {
    Transaction tx =
        Transaction.parseUnsignedTransaction(unsignedTransaction!.serialize());
    tx._isSegwit = addressType.isSegwit;
    double vByte = 0.0;
    if (addressType == AddressType.p2wpkh) {
      vByte = tx.estimateVirtualByte(addressType);
    } else if (addressType == AddressType.p2wsh) {
      if (requiredSignature == null || totalSigner == null) {
        throw Exception("No requiredSignature, totalSiger data");
      }
      vByte = tx.estimateVirtualByte(addressType,
          requiredSignature: requiredSignature, totalSigner: totalSigner);
    } else {
      throw Exception("Not supported address type.");
    }

    return (vByte * feeRate).ceil();
  }
}

/// @nodoc
class PsbtInput {
  final Transaction? _previousTransaction;
  final TransactionOutput? _witnessUtxo;
  final List<DerivationPath> _derivationPathList;
  final List<Signature> _partialSigList;
  final MultisignatureScript? witnessScript;

  Transaction? get previousTransaction => _previousTransaction;
  TransactionOutput? get witnessUtxo => _witnessUtxo;
  List<DerivationPath> get derivationPathList => _derivationPathList;
  List<Signature> get partialSigList => _partialSigList;
  int get requiredSignature {
    if (witnessScript == null) {
      return 1;
    } else {
      return witnessScript!.getRequiredSignature();
    }
  }

  int get totalSinger {
    return derivationPathList.length;
  }

  PsbtInput(this._previousTransaction, this._witnessUtxo,
      this._derivationPathList, this._partialSigList,
      {this.witnessScript});

  addSignature(String signature, String publicKey) {
    _partialSigList.add(Signature(signature, publicKey));
  }
}

/// @nodoc
class PsbtOutput {
  final DerivationPath? _derivationPath;
  final int? _amount;
  final String? _script;

  DerivationPath? get derivationPath => _derivationPath;
  int? get amount => _amount;

  String getAddress() {
    ScriptPublicKey script = ScriptPublicKey.parse(_script!);
    return script.getAddress();
  }

  /// @nodoc
  bool get isChange {
    if (derivationPath == null) {
      return false;
    } else if (derivationPath!.path.split('/')[1].startsWith('48') &&
        derivationPath!.path.split('/')[5] == '1') {
      return true;
    } else if (derivationPath!.path.split('/')[4] == '1') {
      return true;
    } else {
      return false;
    }
  }

  PsbtOutput(this._derivationPath, this._amount, this._script);
}

/// @nodoc
class DerivationPath {
  final String _publicKey;
  final String _masterFingerprint;
  final String _path;

  DerivationPath(this._publicKey, this._masterFingerprint, this._path);

  String get publicKey => _publicKey;
  String get masterFingerprint => _masterFingerprint.toUpperCase();
  String get path => _path;
}
