part of '../../coconut_lib.dart';

/// Represents common utility functions for wallet.
abstract class WalletUtility {
  WalletUtility._();

  /// Get the derivation path for the given address type and account index.
  static String getDerivationPath(AddressType addressType, int accountIndex) {
    bool isTestnet = NetworkType.currentNetworkType.isTestnet;
    String derivationPath;
    if (addressType == AddressType.p2sh) {
      derivationPath = "m/${addressType.purposeIndex}'";
    } else if (addressType == AddressType.p2wsh) {
      derivationPath =
          "m/${addressType.purposeIndex}'/${isTestnet ? 1 : 0}'/$accountIndex'/2'";
    } else {
      derivationPath =
          "m/${addressType.purposeIndex}'/${isTestnet ? 1 : 0}'/$accountIndex'";
    }

    return derivationPath;
  }

  /// Check if the given address is valid.
  static bool validateAddress(String address) {
    if (NetworkType.currentNetworkType.isTestnet) {
      if (address.startsWith('1') ||
          address.startsWith('3') ||
          address.startsWith('bc1')) {
        return false;
      }
    } else {
      if (address.startsWith('m') ||
          address.startsWith('n') ||
          address.startsWith('2') ||
          address.startsWith('tb1') ||
          address.startsWith('bcrt1')) {
        return false;
      }
    }
    if (address.startsWith('1') ||
        address.startsWith('2') ||
        address.startsWith('3') ||
        address.startsWith('m') ||
        address.startsWith('n')) {
      if (address.length < 26 || address.length > 35) return false;
      Uint8List decoded;
      try {
        decoded = Codec.decodeBase58(address);
      } catch (e) {
        return false;
      }

      // Check the version byte
      int versionByte = decoded[0];
      if (address.startsWith('1')) {
        if (versionByte != 0x00) {
          return false;
        }
      } else if (address.startsWith('3')) {
        if (versionByte != 0x05) {
          return false;
        }
      } else if (address.startsWith('m') || address.startsWith('n')) {
        if (versionByte != 0x6f) {
          return false;
        }
      } else if (address.startsWith('2')) {
        if (versionByte != 0xc4) {
          return false;
        }
      }
      return true;
    } else if (address.startsWith('bc1p') ||
        address.startsWith('tb1p') ||
        address.startsWith('bcrt1p')) {
      var codec = bech32m.Bech32mCodec().decode(address);
      if (codec.hrp != 'bc' && codec.hrp != 'tb' && codec.hrp != 'bcrt') {
        return false;
      }
      if (codec.data[0] != 1) return false;
      if (codec.data[0] > 16) return false;
      return true;
    } else if (address.startsWith('bc1q') ||
        address.startsWith('tb1q') ||
        address.startsWith('bcrt1q')) {
      var codec = Bech32Codec().decode(address);
      if (codec.hrp != 'bc' && codec.hrp != 'tb' && codec.hrp != 'bcrt') {
        return false;
      }
      if (codec.data.isEmpty || codec.data[0] > 16) return false;
      if (codec.data.length < 2 || codec.data.length > 66) return false;
      return true;
    }

    return false;
  }

  /// Check if the given mnemonic word is in the word list.
  static bool isInMnemonicWordList(String word) {
    return english_words.wordList.contains(word);
  }

  /// Check if the given mnemonic is valid.
  static bool validateMnemonic(String mnemonicList) {
    List<String> mnemonic = mnemonicList.split(' ');

    final words = english_words.wordList;
    String binaryMnemonic = '';
    for (String word in mnemonic) {
      int index = words.indexOf(word);
      if (index < 0) {
        return false;
      }
      String binIndex = Converter.decToBin(index).padLeft(11, '0');
      binaryMnemonic = binaryMnemonic + binIndex;
    }

    //validate mnemonic
    return _validateChecksum(binaryMnemonic);
  }

  static bool _validateChecksum(String fullBinary) {
    // print("full : " + fullBinary.length.toString());
    int wordLength = (fullBinary.length ~/ 11);
    // print("wordLength : " + wordLength.toString());

    int checksumLength = wordLength ~/ 3;
    // print("checksumLength : " + checksumLength.toString());

    String body = fullBinary.substring(0, fullBinary.length - checksumLength);
    String checkSum = fullBinary.substring(
        fullBinary.length - checksumLength, fullBinary.length);

    // print("body : " + Converter.binToHex(body));
    // print("hash : " +
    //     Converter.bytesToBin(Hash.sha256fromByte(Converter.binToBytes(body))));
    String target =
        (Converter.bytesToBin(Hash.sha256fromByte(Converter.binToBytes(body))))
            .substring(0, checksumLength);

    // print("checksum : " + checkSum + " target : " + target);
    if (checkSum == target) {
      return true;
    } else {
      return false;
    }
  }

  static bool validateDerivationPath(String derivationPath) {
    // Updated regex: allows m/ and segments with optional ' or h suffix
    final regex = RegExp(r"^m(\/\d+['h]?)*$");

    if (!regex.hasMatch(derivationPath)) {
      return false;
    }

    final segments = derivationPath.split('/');

    // First segment must be 'm'
    if (segments[0] != 'm') {
      return false;
    }

    for (int i = 1; i < segments.length; i++) {
      final segment = segments[i];

      // Validate: must be digits followed optionally by ' or h
      if (!RegExp(r"^\d+(['h])?$").hasMatch(segment)) {
        return false;
      }

      // Strip suffix and check range
      final numberPart = segment.replaceAll(RegExp(r"['h]"), '');
      final number = int.tryParse(numberPart);

      if (number == null || number < 0 || number >= 0x80000000) {
        return false;
      }
    }

    return true;
  }

  static double satoshiToBitcoin(int satoshi) {
    return satoshi / 100000000.0;
  }

  /// 부동 소숫점 연산 시 오차가 발생할 수 있으므로 Decimal이용
  static int bitcoinToSatoshi(double bitcoin) {
    return (Decimal.parse(bitcoin.toString()) * Decimal.parse('100000000'))
        .toDouble()
        .toInt();
  }

  static int getAccountIndexFromDerivationPath(String derivationPath) {
    List<String> pathList = derivationPath.split('/');
    return int.parse(pathList.last);
  }

  static bool isChangeFromDerivationPath(String derivationPath) {
    List<String> pathList = derivationPath.split('/');
    return pathList[pathList.length - 2] == '1';
  }

  static Uint8List aggregatePublicKey(List<String> publicKeyList,
      {bool isXOnly = true}) {
    List<Uint8List> publicKeysBytes =
        publicKeyList.map((e) => Codec.decodeHex(e)).toList();

    List<Uint8List> prefixedPublicKeyList = [];
    for (Uint8List publicKey in publicKeysBytes) {
      if (publicKey.length == 32) {
        prefixedPublicKeyList.add(Uint8List.fromList([0x02, ...publicKey]));
      } else if (publicKey.length == 33) {
        prefixedPublicKeyList.add(publicKey);
      } else {
        throw ArgumentError(
            "publicKey must be 32 or 33 bytes (got ${publicKey.length})");
      }
    }

    late Uint8List secondKey = Uint8List(0);
    for (Uint8List key in prefixedPublicKeyList) {
      if (Codec.encodeHex(prefixedPublicKeyList[0]) != Codec.encodeHex(key)) {
        secondKey = key;
        break;
      }
    }

    String concatenatedPublicKey =
        prefixedPublicKeyList.map((e) => Codec.encodeHex(e)).join();

    Uint8List Q = prefixedPublicKeyList[0];

    for (int i = 0; i < prefixedPublicKeyList.length; i++) {
      Uint8List coefficient = Uint8List(0);
      if (Codec.encodeHex(prefixedPublicKeyList[i]) ==
          Codec.encodeHex(secondKey)) {
        coefficient = Uint8List.fromList(List<int>.generate(
            32,
            (i) => int.parse(
                BigInt.one
                    .toRadixString(16)
                    .padLeft(64, '0')
                    .substring(i * 2, i * 2 + 2),
                radix: 16)));
      } else {
        String data = Hash.taggedHash(
                'KeyAgg list', Codec.decodeHex(concatenatedPublicKey)) +
            Codec.encodeHex(prefixedPublicKeyList[i]);
        coefficient = Codec.decodeHex(
            Hash.taggedHash('KeyAgg coefficient', Codec.decodeHex(data)));
      }

      if (i == 0) {
        Q = Ecc.pointMultiplyScalar(
            prefixedPublicKeyList[i], coefficient, true)!;
      } else {
        Q = Ecc.pointCombine(
            Q,
            Ecc.pointMultiplyScalar(
                prefixedPublicKeyList[i], coefficient, true)!,
            true)!;
      }
    }

    if (isXOnly) {
      return Q.sublist(1);
    } else {
      return Q;
    }
  }

  static double estimateVirtualByte(
      AddressType addressType, int numberOfInputs, int numberOfOutputs,
      {int? requiredSignature, int? totalSigner}) {
    final int baseByte = 12;
    final int inputSize = 41;
    final int outputSize = 34;
    int signatureSize = 73;
    int pubKeySize = 34;

    int nonWitnessSize = baseByte;
    int witnessSize = 1; // number of witness
    if (addressType.isTaproot) {
      signatureSize = 65; // 64 + 1(length)
      pubKeySize = 0; // 32 + 1(length)
    }
    if (addressType == AddressType.p2wpkh) {
      nonWitnessSize += numberOfInputs * inputSize;
      nonWitnessSize += numberOfOutputs * outputSize;
      witnessSize = numberOfInputs * (signatureSize + pubKeySize + 1);
    } else if (addressType == AddressType.p2wsh) {
      if (requiredSignature == null || totalSigner == null) {
        throw ArgumentError(
            'requiredSignature and totalSignature is required for p2wsh');
      }
      nonWitnessSize += numberOfInputs * inputSize;
      nonWitnessSize += numberOfOutputs * outputSize;

      // 각 입력당 witness 크기 계산
      for (int i = 0; i < numberOfInputs; i++) {
        witnessSize += 1; // 00
        witnessSize += requiredSignature * signatureSize;
        int scriptSize = 0;
        scriptSize += 3; // m,n,OP_CHECKMULTISIG
        scriptSize += totalSigner * pubKeySize + 1;
        witnessSize += scriptSize;
        witnessSize += totalSigner + 1; //script size
      }
    } else {
      throw Exception('Unsupported address type');
    }

    double vByte = ((nonWitnessSize * 4) + witnessSize) / 4;
    return vByte;
  }
}
