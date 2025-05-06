part of '../../coconut_lib.dart';

/// Represents a PSBT(BIP-0174).
class Psbt {
  /// @nodoc
  Map<String, dynamic> psbtMap;

  /// Get transaction not signed yet.
  Transaction? unsignedTransaction;

  /// @nodoc
  List<PsbtInput> inputs = [];

  /// @nodoc
  List<PsbtOutput> outputs = [];

  /// @nodoc
  List<DerivationPath> extendedPublicKeyList = [];

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
          if (output.bip32Derivation != null && output.isChange) continue;
          sendingAmount += output.outAmount!;
        }

        return sendingAmount;
      }();

  AddressType? get addressType => () {
        if (inputs[0].bip32Derivation != null) {
          if (inputs[0].witnessScript == null) {
            return AddressType.p2wpkh;
          } else {
            return AddressType.p2wsh;
          }
        } else if (inputs[0].tapBip32Derivation != null) {
          if (inputs[0].muSig2AggregatedPublicKey != null) {
            return AddressType.p2trMuSig2;
          } else if (inputs[0].tapLeafScript != null) {
            return AddressType.p2trScriptPathSpending;
          } else {
            return AddressType.p2trKeyPathSpending;
          }
        } else {
          return null;
        }
      }();

  /// @nodoc
  Psbt(this.psbtMap) {
    unsignedTransaction =
        Transaction.parseUnsignedTransaction(psbtMap["global"]["00"]);

    // instantiate global
    psbtMap["global"].keys.forEach((key) {
      if (key.startsWith('01')) {
        String publicKey = key.substring(2);
        String masterFingerprint = psbtMap["global"][key].substring(0, 8);
        String derivationPath = _parseDerivationPath(
            Codec.decodeHex(psbtMap["global"][key].substring(8)));
        extendedPublicKeyList
            .add(DerivationPath(publicKey, masterFingerprint, derivationPath));
      }
    });

    // instantiate each input
    for (int i = 0; i < psbtMap["inputs"].length; i++) {
      TransactionOutput? witnessUtxo;
      if (psbtMap["inputs"][i].containsKey("01")) {
        witnessUtxo = TransactionOutput.parse(psbtMap["inputs"][i]["01"]);
      }

      List<DerivationPath> inputDerivationPathList = [];
      List<Signature> partialSigList = [];
      MultisignatureScript? witnessScript;

      // for every taproot
      List<DerivationPath> tapBip32Derivation = [];

      // for key path spending
      String? taprootKeyPathSpendingSignature;

      // field for musig2
      String? muSig2AggregatedPublicKey;
      List<String>? muSig2participantPubKeyList;
      Map<String, String>? muSig2PubNonces;
      List<Signature>? muSig2PartialSigs;

      psbtMap["inputs"][i].keys.forEach((key) {
        // 06 : BIP32_DERIVATION
        if (key.startsWith('06')) {
          String publicKey = key.substring(2);
          String masterFingerprint = psbtMap["inputs"][i][key].substring(0, 8);
          String derivationPath = _parseDerivationPath(
              Codec.decodeHex(psbtMap["inputs"][i][key].substring(8)));
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
          String size =
              Codec.encodeHex(Codec.encodeVariableInteger(script.length ~/ 2));
          witnessScript = MultisignatureScript.parse(size + script);
        }
        // 19 : TAP_KEY_SIG
        if (key.startsWith('13')) {
          taprootKeyPathSpendingSignature = psbtMap["inputs"][i][key];
        }

        // 22 : TAP_BIP32_DERIVATION
        if (key.startsWith('16')) {
          String publicKey = key.substring(2);
          Uint8List valueBytes = Codec.decodeHex(psbtMap["inputs"][i][key]);
          int offset = 0;

          String masterFingerprint =
              Codec.encodeHex(valueBytes.sublist(offset, offset + 4));
          offset += 4;

          String derivationPath = _parseDerivationPath(
              valueBytes.sublist(offset, valueBytes.length));
          tapBip32Derivation.add(
              DerivationPath(publicKey, masterFingerprint, derivationPath));
        }

        // 26: 'MUSIG2_PARTICIPANT_PUBKEY',
        if (key.startsWith('1a')) {
          muSig2AggregatedPublicKey = key.substring(2);
          String concatenatedPubKeys = psbtMap["inputs"][i][key];
          muSig2participantPubKeyList ??= [];
          if (concatenatedPubKeys.length % 64 != 0) {
            throw Exception(
                "Invalid participant public key list: length is not multiple of 66 (got ${concatenatedPubKeys.length})");
          }
          int numberOfKeys = concatenatedPubKeys.length ~/ 64;
          for (int i = 0; i < numberOfKeys; i++) {
            final hexPart = concatenatedPubKeys.substring(i * 64, (i + 1) * 64);
            muSig2participantPubKeyList!.add(hexPart);
          }
          muSig2participantPubKeyList!.sort();
        }

        // 27: 'MUSIG2_PUB_NONCE'
        if (key.startsWith('1b')) {
          muSig2PubNonces ??= {};
          String publicKey = key.substring(2);
          muSig2PubNonces![publicKey] = psbtMap["inputs"][i][key];
        }

        // 28: 'MUSIG2_PARTIAL_SIG',
        if (key.startsWith('1c')) {
          muSig2PartialSigs ??= [];
          String publicKey = key.substring(2);
          String signature = psbtMap["inputs"][i][key];
          muSig2PartialSigs!.add(Signature(signature, publicKey));
        }
      });

      // Set psbt input
      if (inputDerivationPathList.isNotEmpty) {
        inputs.add(PsbtInput.forSegwit(
            witnessUtxo, inputDerivationPathList, partialSigList,
            witnessScript: witnessScript));
      } else if (tapBip32Derivation.isNotEmpty &&
          muSig2AggregatedPublicKey == null) {
        inputs.add(PsbtInput.forKeyPathSpending(
            witnessUtxo, tapBip32Derivation, taprootKeyPathSpendingSignature));
      } else if (tapBip32Derivation.isNotEmpty &&
          muSig2AggregatedPublicKey != null) {
        inputs.add(PsbtInput.forMuSig2(
            witnessUtxo,
            tapBip32Derivation,
            muSig2AggregatedPublicKey,
            muSig2participantPubKeyList,
            muSig2PubNonces,
            muSig2PartialSigs));
      } else {
        inputs.add(PsbtInput.forSignatureOnly(partialSigList,
            witnessScript: witnessScript));
      }
    }

    for (int i = 0; i < psbtMap["outputs"].length; i++) {
      int? amount;
      ScriptPublicKey? script;
      // if (psbtMap["outputs"][i].containsKey("03")) {
      //   amount = Converter.littleEndianToInt(
      //       Codec.decodeHex(psbtMap["outputs"][i]["03"]));
      // }

      // if (psbtMap["outputs"][i].containsKey("04")) {
      //   script = ScriptPublicKey.parse(psbtMap["outputs"][i]["04"]);
      // }
      amount = unsignedTransaction!.outputs[i].amount;
      script = unsignedTransaction!.outputs[i].scriptPubKey;

      DerivationPath? outputDerivationPath;
      psbtMap["outputs"][i].keys.forEach((key) {
        if (key.startsWith('02')) {
          String publicKey = key.substring(2);
          String masterFingerprint = psbtMap["outputs"][i][key].substring(0, 8);
          String derivationPath = _parseDerivationPath(
              Codec.decodeHex(psbtMap["outputs"][i][key].substring(8)));
          outputDerivationPath =
              DerivationPath(publicKey, masterFingerprint, derivationPath);
        }
      });
      outputs.add(PsbtOutput(outputDerivationPath, amount, script));
    }
  }

  /// Generate the PSBT to base64 string.
  String serialize() {
    _updatePsbtMap();
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

    // psbtBytes.add(0x00);
    return base64Encode(psbtBytes);
  }

  void _updatePsbtMap() {
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i].partialSig != null) {
        for (Signature signature in inputs[i].partialSig!) {
          if (!psbtMap["inputs"][i].keys.contains("02${signature.publicKey}")) {
            psbtMap["inputs"][i]["02${signature.publicKey}"] =
                signature.signature;
          }
        }
      }
      if (inputs[i].tapKeySig != null) {
        if (!psbtMap["inputs"][i].keys.contains("13")) {
          psbtMap["inputs"][i]["13"] = inputs[i].tapKeySig!;
        }
      }
      if (inputs[i].muSig2PartialSigs != null) {
        for (Signature signature in inputs[i].muSig2PartialSigs!) {
          if (!psbtMap["inputs"][i].keys.contains("1c${signature.publicKey}")) {
            psbtMap["inputs"][i]["1c${signature.publicKey}"] =
                signature.signature;
          }
        }
      }
      if (inputs[i].tapScriptSig != null) {
        if (!psbtMap["inputs"][i].keys.contains("14")) {
          psbtMap["inputs"][i]["14"] = inputs[i].tapScriptSig!;
        }
      }
      if (inputs[i].muSig2PubNonces != null) {
        for (String publicKey in inputs[i].muSig2PubNonces!.keys) {
          if (!psbtMap["inputs"][i].keys.contains("1b$publicKey")) {
            psbtMap["inputs"][i]["1b$publicKey"] =
                inputs[i].muSig2PubNonces![publicKey]!;
          }
        }
      }
    }
  }

  Map<String, dynamic> toKeyMap() {
    return psbtMap;
  }

  List<int> _serializeKeyMap(Map<String, dynamic> map) {
    List<int> globalBytes = [];
    map.forEach((key, value) {
      List<int> keyBytes = Codec.decodeHex(key);
      globalBytes += Codec.encodeVariableInteger(keyBytes.length);
      globalBytes += keyBytes;
      List<int> valueBytes = Codec.decodeHex(value);
      globalBytes += Codec.encodeVariableInteger(valueBytes.length);
      globalBytes += valueBytes;
    });
    return globalBytes;
  }

  /// Create a PSBT from a Transaction object.
  factory Psbt.fromTransaction(Transaction tx, WalletBase wallet) {
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

    //Global
    Map<String, dynamic> globalData = {};
    String txKey = getKeyType(globalKeyType, 'UNSIGNED_TX');
    globalData[txKey] = tx._serializeLegacy(); //old serialze format BIP0174

    if (wallet.addressType.isSingleSignature) {
      KeyStore keyStore = singleSignatureWallet.keyStore;
      String key =
          "${getKeyType(globalKeyType, 'XPUB')}${keyStore.extendedPublicKey.serializeForPsbt(toXpub: true)}";
      String value =
          "${keyStore.masterFingerprint}${Codec.encodeHex(_serializeDerivationPath(wallet.derivationPath))}";
      globalData[key] = value;
    }

    if (wallet.addressType.isMultisignature) {
      for (KeyStore keyStore in multisignatureWallet.keyStoreList) {
        String key =
            "${getKeyType(globalKeyType, 'XPUB')}${keyStore.extendedPublicKey.serializeForPsbt(toXpub: true)}";
        String value =
            "${keyStore.masterFingerprint}${Codec.encodeHex(_serializeDerivationPath(wallet.derivationPath))}";
        globalData[key] = value;
      }
    }

    psbtData["global"] = globalData;
    //Input
    List<TransactionOutput> witnessUtxoList = [];
    for (int i = 0; i < tx.inputs.length; i++) {
      String receivedAddress =
          wallet.getAddressWithDerivationPath(tx.utxoList[i].derivationPath);
      TransactionOutput output = TransactionOutput.forPayment(
          tx.utxoList[i].amount, receivedAddress,
          isChangeOutput: false);
      witnessUtxoList.add(output);
    }
    for (int i = 0; i < tx.inputs.length; i++) {
      Map<String, dynamic> inputData = {};
      String witnessUtxoKey = getKeyType(inputKeyType, 'WITNESS_UTXO');
      inputData[witnessUtxoKey] = witnessUtxoList[i].serialize();

      String sigHashTypeKey = getKeyType(inputKeyType, 'SIGHASH_TYPE');
      inputData[sigHashTypeKey] =
          Codec.encodeHex(Converter.intToLittleEndianBytes(1, 4));

      // Each address type
      if (wallet.addressType == AddressType.p2wpkh) {
        String bip32DerivationKeyType =
            getKeyType(inputKeyType, 'BIP32_DERIVATION');
        String publicKey = singleSignatureWallet.keyStore.getPublicKey(
            tx.utxoList[i].accountIndex,
            isChange: tx.utxoList[i].isChange);
        String fingerPrint = singleSignatureWallet.keyStore.masterFingerprint;

        inputData[bip32DerivationKeyType + publicKey] = fingerPrint +
            Codec.encodeHex(
                _serializeDerivationPath(tx.utxoList[i].derivationPath));

        if (tx.inputs[i].witnessList.isNotEmpty) {
          String partialSigKeyType = getKeyType(inputKeyType, 'PARTIAL_SIG');
          String publicKey = tx.inputs[i].witnessList[0];
          String signature = tx.inputs[i].witnessList[1];
          inputData[partialSigKeyType + publicKey] = signature;
        }
      } else if (wallet.addressType == AddressType.p2wsh) {
        String bip32DerivationKeyType =
            getKeyType(inputKeyType, 'BIP32_DERIVATION');
        for (KeyStore keyStore in multisignatureWallet.keyStoreList) {
          String publicKey = keyStore.getPublicKey(tx.utxoList[i].accountIndex,
              isChange: tx.utxoList[i].isChange);

          String fingerPrint = keyStore.masterFingerprint;
          inputData[bip32DerivationKeyType + publicKey] = fingerPrint +
              Codec.encodeHex(
                  _serializeDerivationPath(tx.utxoList[i].derivationPath));
        }
        String witnessScriptKey = getKeyType(inputKeyType, 'WITNESS_SCRIPT');
        String witnessScript = multisignatureWallet
            .getWitnessScript(tx.utxoList[i].derivationPath);
        inputData[witnessScriptKey] = witnessScript;

        if (tx.inputs[i].witnessList.isNotEmpty) {
          String partialSigKeyType = getKeyType(inputKeyType, 'PARTIAL_SIG');
          String publicKey = tx.inputs[i].witnessList[0];
          String signature = tx.inputs[i].witnessList[1];
          inputData[partialSigKeyType + publicKey] = signature;
        }
      } else if (wallet.addressType == AddressType.p2trKeyPathSpending) {
        String tapBip32DerivationKeyType =
            getKeyType(inputKeyType, 'TAP_BIP32_DERIVATION');
        String publicKey = singleSignatureWallet.keyStore
            .getPublicKey(tx.utxoList[i].accountIndex,
                isChange: tx.utxoList[i].isChange, applyTweak: false)
            .substring(2);
        String fingerPrint = singleSignatureWallet.keyStore.masterFingerprint;
        inputData[tapBip32DerivationKeyType + publicKey] = fingerPrint +
            Codec.encodeHex(
                _serializeDerivationPath(tx.utxoList[i].derivationPath));
        if (tx.inputs[i].witnessList.isNotEmpty) {
          String taprootKeySpendSignature =
              getKeyType(inputKeyType, 'TAP_KEY_SIG');
          inputData[taprootKeySpendSignature] = tx.inputs[i].witnessList[0];
        }
        if (tx.inputs[i].witnessList.length == 1) {
          String taprootKeySpendSignature =
              getKeyType(inputKeyType, 'PSBT_IN_TAP_KEY_SIG');
          inputData[taprootKeySpendSignature] = tx.inputs[i].witnessList[0];
        }
      } else if (wallet.addressType == AddressType.p2trMuSig2) {
        List<String> publicKeys = [];

        for (KeyStore keyStore in multisignatureWallet.keyStoreList) {
          // TAP_BIP32_DERIVATION
          String tapBip32DerivationKeyType =
              getKeyType(inputKeyType, 'TAP_BIP32_DERIVATION');
          String publicKey = keyStore.getPublicKey(tx.utxoList[i].accountIndex,
              isChange: tx.utxoList[i].isChange, isXOnly: true);
          publicKeys.add(publicKey);

          String fingerPrint = keyStore.masterFingerprint;
          inputData[tapBip32DerivationKeyType + publicKey] = fingerPrint +
              Codec.encodeHex(
                  _serializeDerivationPath(tx.utxoList[i].derivationPath));
        }
        // MUSIG2_PARTICIPANT_PUBKEY
        String musig2ParticipantPubKeyType =
            getKeyType(inputKeyType, 'MUSIG2_PARTICIPANT_PUBKEY');
        String aggregatePubKey = multisignatureWallet.getAddregatedPublilcKey(
            tx.utxoList[i].accountIndex, tx.utxoList[i].isChange);
        inputData[musig2ParticipantPubKeyType + aggregatePubKey] =
            publicKeys.join();

        // String musig2PubNonceType =
        //     getKeyType(inputKeyType, 'MUSIG2_PUB_NONCE');
        for (int keyStoreIndex = 0;
            keyStoreIndex < multisignatureWallet.keyStoreList.length;
            keyStoreIndex++) {
          // MUSIG2_PUB_NONCE
          // if (multisignatureWallet.keyStoreList[keyStoreIndex].hasSeed) {
          //   inputData[musig2PubNonceType + publicKeys[keyStoreIndex]] =
          //       multisignatureWallet.keyStoreList[keyStoreIndex]
          //           .getMuSig2PublicNonce(
          //               tx.getTaprootSigHash(i, witnessUtxoList),
          //               aggregatePubKey,
          //               tx.utxoList[i].accountIndex,
          //               tx.utxoList[i].isChange);
          // }
        }
      }
      psbtData["inputs"].add(inputData);
    }

    //output
    for (int i = 0; i < tx.outputs.length; i++) {
      Map<String, dynamic> outputData = {};
      // String amountKey = getKeyType(outputKeyType, 'AMOUNT');
      // outputData[amountKey] = Codec.encodeHex(
      //     Converter.intToLittleEndianBytes(tx.outputs[i].amount, 4));

      // String scriptKey = getKeyType(outputKeyType, 'SCRIPT');
      // outputData[scriptKey] = tx.outputs[i].scriptPubKey.serialize();

      if (tx.outputs[i].isChangeOutput != null &&
          tx.outputs[i].isChangeOutput!) {
        String bip32DerivationKeyType =
            getKeyType(outputKeyType, 'BIP32_DERIVATION');

        if (wallet is SingleSignatureWalletBase) {
          String publicKey = singleSignatureWallet.keyStore.getPublicKey(
              WalletUtility.getAccountIndexFromDerivationPath(
                  tx.changeAddressDerivationPath!),
              isChange: WalletUtility.isChangeFromDerivationPath(
                  tx.changeAddressDerivationPath!));
          String fingerPrint = singleSignatureWallet.keyStore.masterFingerprint;

          outputData[bip32DerivationKeyType + publicKey] = fingerPrint +
              Codec.encodeHex(
                  _serializeDerivationPath(tx.changeAddressDerivationPath!));
        } else if (wallet is MultisignatureWalletBase) {
          for (KeyStore keyStore in multisignatureWallet.keyStoreList) {
            String publicKey = keyStore.getPublicKey(
                WalletUtility.getAccountIndexFromDerivationPath(
                    tx.changeAddressDerivationPath!),
                isChange: WalletUtility.isChangeFromDerivationPath(
                    tx.changeAddressDerivationPath!));

            String fingerPrint = keyStore.masterFingerprint;
            outputData[bip32DerivationKeyType + publicKey] = fingerPrint +
                Codec.encodeHex(
                    _serializeDerivationPath(tx.changeAddressDerivationPath!));
          }
        }
      }

      psbtData["outputs"].add(outputData);
    }

    Psbt psbt = Psbt(psbtData);

    //check input amount is enough
    // int totalInputAmount = 0;
    // for (PsbtInput input in psbt.inputs) {
    //   totalInputAmount += input.witnessUtxo!.amount;
    // }
    // int totalOutputAmount = 0;
    // for (PsbtOutput output in psbt.outputs) {
    //   totalOutputAmount += output.outAmount!;
    // }
    // if (totalOutputAmount > totalInputAmount) {
    //   throw Exception('Not enough input amount');
    // }

    return psbt;
  }

  factory Psbt.fromMap(Map<String, dynamic> keyMap) {
    return Psbt(keyMap);
  }

  /// Parse a PSBT from a base64 string.
  factory Psbt.parse(String psbtBase64) {
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
      int keyLen = Codec.decodeVariableInteger(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      if (keyLen == 0) {
        break;
      }
      Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
      offset += keyLen;
      int valueLen = Codec.decodeVariableInteger(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
      offset += valueLen;
      globalMap[Codec.encodeHex(key)] = Codec.encodeHex(value);
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
        int keyLen = Codec.decodeVariableInteger(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Codec.decodeVariableInteger(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        inputData[Codec.encodeHex(key)] = Codec.encodeHex(value);
      }
      psbtData["inputs"].add(inputData);
    }

    // Outputs
    for (int i = 0; i < globalTx.outputs.length; i++) {
      Map<String, String> outputData = {};
      while (true) {
        int keyLen = Codec.decodeVariableInteger(psbtBytes, offset);
        // print(' -key len ${keyLen.toString()}-');
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Codec.decodeVariableInteger(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        outputData[Codec.encodeHex(key)] = Codec.encodeHex(value);
      }
      psbtData["outputs"].add(outputData);
    }

    return Psbt(psbtData);
  }

  /// Add a signature to the PSBT.
  // void addPartialSig(int inputIndex, String signature, String publicKey) {
  //   inputs[inputIndex].addPartialSig(signature, publicKey);
  //   psbtMap["inputs"][inputIndex]["02$publicKey"] = signature;
  // }

  // void addTapKeySig(int inputIndex, String signature) {
  //   inputs[inputIndex].addTapKeySig(signature);
  //   psbtMap["inputs"][inputIndex]["13"] = signature;
  // }

  // void addTapScriptSig(int inputIndex, String signature, String publicKey) {
  //   inputs[inputIndex].addTapScriptSig(signature, publicKey);
  //   psbtMap["inputs"][inputIndex]["14$publicKey"] = signature;
  // }

  // void addMuSig2PubNonce(int inputIndex, String publicKey, String nonce) {
  //   inputs[inputIndex].addMuSig2PubNonce(publicKey, nonce);
  //   psbtMap["inputs"][inputIndex]["1b$publicKey"] = nonce;
  // }

  // void addMuSig2PartialSig(int inputIndex, String signature, String publicKey) {
  //   inputs[inputIndex].addMuSig2PartialSig(signature, publicKey);
  //   psbtMap["inputs"][inputIndex]["1c$publicKey"] = signature;
  // }

  String getAggregatedPublicNonce(int inputIndex) {
    return inputs[inputIndex].getAggregatedPublicNonce();
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
    26: 'MUSIG2_PARTICIPANT_PUBKEY',
    27: 'MUSIG2_PUB_NONCE',
    28: 'MUSIG2_PARTIAL_SIG',
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
    8: 'MUSIG2_PARTICIPANT_PUBKEYS',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static String getKeyType(Map<int, String> keyTypeMap, String typeName) {
    for (int key in keyTypeMap.keys) {
      if (keyTypeMap[key] == typeName) {
        return Converter.decToHexWithPadding(key, 2);
      }
    }
    throw Exception('Invalid Key Type');
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
        if (inputs[i].totalSinger < inputs[i].requiredSignature) {
          throw Exception('Not enough signatures');
        }
        signedTransaction.inputs[i].setSignature(
            addressType, inputs[i].partialSig!,
            witnessScript: inputs[i].witnessScript);

        if (inputs[i].witnessUtxo == null) {
          continue;
        }

        if (signedTransaction.validateEcdsa(i, inputs[i].witnessUtxo!,
            witnessScript: inputs[i].witnessScript!.rawSerialize())) {
          continue;
        } else {
          throw Exception('Invalid Signatures');
        }
      }
    } else if (addressType == AddressType.p2wpkh) {
      for (int i = 0; i < inputs.length; i++) {
        if (inputs[i].partialSig == null) {
          throw Exception('Not enough signatures');
        }
        signedTransaction.inputs[i]
            .setSignature(addressType, inputs[i].partialSig!);

        if (inputs[i].witnessUtxo == null) {
          continue;
        }

        if (signedTransaction.validateEcdsa(i, inputs[i].witnessUtxo!)) {
          continue;
        } else {
          throw Exception('Invalid Signatures');
        }
      }
    } else if (addressType == AddressType.p2trKeyPathSpending) {
      List<TransactionOutput> utxoList = [];
      for (int i = 0; i < inputs.length; i++) {
        utxoList.add(inputs[i].witnessUtxo!);
      }

      for (int i = 0; i < inputs.length; i++) {
        if (inputs[i].tapKeySig != null) {
          signedTransaction.inputs[i]
              .setTaprootKeyPathSpendingSignature(inputs[i].tapKeySig!);

          if (utxoList.isEmpty) {
            continue;
          }

          if (signedTransaction.validateSchnorr(i, utxoList)) {
            continue;
          } else {
            throw Exception('Invalid Signatures');
          }
        }
      }
    } else if (addressType == AddressType.p2trMuSig2) {
      List<TransactionOutput> utxoList = [];
      for (int i = 0; i < inputs.length; i++) {
        utxoList.add(inputs[i].witnessUtxo!);
      }
      for (int i = 0; i < inputs.length; i++) {
        if (inputs[i].totalSinger < inputs[i].requiredSignature) {
          throw Exception('Not enough signatures');
        }

        Uint8List aggregatedPubKey =
            Codec.decodeHex(inputs[i].muSig2AggregatedPublicKey!);
        Uint8List aggregatedPubNonce =
            Codec.decodeHex(inputs[i].getAggregatedPublicNonce());
        Uint8List message =
            Codec.decodeHex(signedTransaction.getTaprootSigHash(i, utxoList));
        List<Uint8List> signatureList = [];
        for (Signature sig in inputs[i].muSig2PartialSigs!) {
          signatureList.add(Codec.decodeHex(sig.signature));
        }

        MuSig2SessionContext sessionContext = MuSig2SessionContext(
          aggregatedPubNonce,
          inputs[i]
              .muSig2ParticipantPubkeys!
              .map((e) => Codec.decodeHex('02$e'))
              .toList(),
          message,
        );

        Uint8List aggregatedSignature =
            Ecc.getAggregatedSignatureForMuSig2(sessionContext, signatureList);

        if (Ecc.verifySchnorr(message, aggregatedPubKey, aggregatedSignature)) {
          signedTransaction.inputs[i].setTaprootKeyPathSpendingSignature(
              Codec.encodeHex(aggregatedSignature));
        } else {
          throw Exception('Invalid Signatures');
        }
      }
    } else {
      throw Exception('Unsupported Address Type');
    }
    return signedTransaction;
  }

  bool isSigned(KeyStore keyStore, {isKeyPathSpending = false}) {
    bool isSigned = false;
    for (PsbtInput input in inputs) {
      for (DerivationPath path in input.derivationPathList) {
        if (keyStore.masterFingerprint == path.masterFingerprint) {
          isSigned = true;
          if (isKeyPathSpending) {
            return (input.tapKeySig != null);
          } else {
            String publicKey = keyStore.getPublicKey(
                WalletUtility.getAccountIndexFromDerivationPath(path.path),
                isChange: WalletUtility.isChangeFromDerivationPath(path.path));
            // getPublicKeyWithDerivationPath(path.path);
            if (!input.signatureList
                .any((element) => element.publicKey == publicKey)) {
              return false;
            }
          }
        }
      }
    }

    return isSigned;
  }
}

/// @nodoc
class PsbtInput {
  //Field for Segwit v0
  TransactionOutput? witnessUtxo; //0x01
  List<Signature>? partialSig; //0x02
  List<DerivationPath>? bip32Derivation; //0x03
  MultisignatureScript? witnessScript; //0x05

  PsbtInput.forSegwit(this.witnessUtxo, this.bip32Derivation, this.partialSig,
      {this.witnessScript, this.tapKeySig});

  PsbtInput.forSignatureOnly(this.partialSig, {this.witnessScript});

  //Field for taproot
  String? tapKeySig; //0x13(19)
  List<Signature>? tapScriptSig; //0x14(20)
  MultisignatureScript? tapLeafScript; //0x15
  String? controlBlock; //0x15
  List<DerivationPath>? tapBip32Derivation; //16

  PsbtInput.forKeyPathSpending(
      this.witnessUtxo, this.tapBip32Derivation, this.tapKeySig);

  String? muSig2AggregatedPublicKey; // 0x1a
  List<String>? muSig2ParticipantPubkeys; // 0x1a
  Map<String, String>? muSig2PubNonces; // 0x1b
  List<Signature>? muSig2PartialSigs; // 0x1c

  PsbtInput.forMuSig2(
      this.witnessUtxo,
      this.tapBip32Derivation,
      this.muSig2AggregatedPublicKey,
      this.muSig2ParticipantPubkeys,
      this.muSig2PubNonces,
      this.muSig2PartialSigs);

  List<DerivationPath> get derivationPathList =>
      bip32Derivation == null ? tapBip32Derivation! : bip32Derivation!;
  List<Signature> get signatureList => {
        if (partialSig != null) ...partialSig!,
        if (tapScriptSig != null) ...tapScriptSig!,
        if (tapKeySig != null) ...[Signature(tapKeySig!, '')]
      }.toList();

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

  int get signedCount {
    if (tapScriptSig != null) {
      return tapScriptSig!.length;
    } else if (partialSig != null) {
      return partialSig!.length;
    }
    return 0;
  }

  addPartialSig(String signature, String publicKey) {
    partialSig!.add(Signature(signature, publicKey));
  }

  addTapKeySig(String signature) {
    tapKeySig = signature;
  }

  addTapScriptSig(String signature, String publicKey) {
    tapScriptSig!.add(Signature(signature, publicKey));
  }

  addMuSig2PubNonce(String publicKey, String publicNonce) {
    muSig2PubNonces ??= {};
    muSig2PubNonces![publicKey] = publicNonce;
  }

  addMuSig2PartialSig(String signature, String publicKey) {
    muSig2PartialSigs ??= [];
    muSig2PartialSigs!.add(Signature(signature, publicKey));
  }

  String getAggregatedPublicNonce() {
    // Check if we have any public nonces
    if (muSig2PubNonces == null || muSig2PubNonces!.isEmpty) {
      throw Exception('No MuSig2 public nonces found');
    }

    // Get all public nonces
    List<Uint8List> publicNonces =
        muSig2PubNonces!.values.map((hex) => Codec.decodeHex(hex)).toList();
    // print('publicNonces: ${publicNonces.map((e) => Codec.encodeHex(e))}');

    if (publicNonces.isEmpty) {
      throw Exception('No public nonces found');
    }
    // print(
    //     'aggregatePublicNonce: ${Codec.encodeHex(aggregatePublicNonce(publicNonces))}');
    return Codec.encodeHex(aggregatePublicNonce(publicNonces));
  }

  static Uint8List aggregatePublicNonce(List<Uint8List> publicNonces) {
    if (publicNonces.isEmpty) {
      throw ArgumentError('At least one public nonce required');
    }
    if (publicNonces[0].length != 66) {
      throw ArgumentError('Public nonce #0 must be 66 bytes');
    }

    Uint8List r1 = publicNonces[0].sublist(0, 33);
    Uint8List r2 = publicNonces[0].sublist(33, 66);

    for (int i = 1; i < publicNonces.length; i++) {
      final nonce = publicNonces[i];
      if (nonce.length != 66) {
        throw ArgumentError('Public nonce #$i must be 66 bytes');
      }

      final r1i = nonce.sublist(0, 33);
      final r2i = nonce.sublist(33, 66);

      r1 = Ecc.pointCombine(r1, r1i, true) ?? Uint8List(33);
      r2 = Ecc.pointCombine(r2, r2i, true) ?? Uint8List(33);
    }

    return Uint8List.fromList([...r1, ...r2]);
  }
}

/// @nodoc
class PsbtOutput {
  final DerivationPath? bip32Derivation; //0x02
  final int? outAmount; //0x03
  final ScriptPublicKey? outScript; //0x04

  String get outAddress => outScript!.getAddress();

  /// @nodoc
  bool get isChange {
    if (bip32Derivation == null) {
      return false;
    } else if (bip32Derivation!.path.split('/')[1].startsWith('48') &&
        bip32Derivation!.path.split('/')[5] == '1') {
      return true;
    } else if (bip32Derivation!.path.split('/')[4] == '1') {
      return true;
    } else {
      return false;
    }
  }

  PsbtOutput(this.bip32Derivation, this.outAmount, this.outScript);
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
  int get accountIndex {
    return WalletUtility.getAccountIndexFromDerivationPath(_path);
  }

  bool get isChange {
    return WalletUtility.isChangeFromDerivationPath(_path);
  }
}
