part of '../../coconut_lib.dart';

class WitnessScript extends Script {
  WitnessScript(super._cmds);

  /// Parse the script from the given script hex.
  factory WitnessScript.parse(String script) {
    List<dynamic> cmds = Script.parse(Converter.hexToBytes(script));
    _validateScript(cmds);
    return WitnessScript(cmds);
  }

  static void _validateScript(List<dynamic> cmds) {
    // Check if the script ends with OP_CHECKMULTISIG.
    if (cmds.isEmpty || cmds.last != 174) {
      throw FormatException("Not a multisig script: Missing OP_CHECKMULTISIG");
    }

    int m = cmds[0];
    int n = cmds[cmds.length - 2];

    // The second-to-last element must be the number of public keys.
    int totalSigner = n - 80;
    if (totalSigner < 1 || totalSigner > 15) {
      throw FormatException("Invalid number of total signer$totalSigner.");
    }

    if (totalSigner != cmds.length - 3) {
      throw FormatException("Invalid number of elements in script");
    }

    // The first element must be the required number of signatures.
    int requiredSignature = m - 80;
    if (requiredSignature < 1 || requiredSignature > totalSigner) {
      throw FormatException("Invalid required signatures");
    }

    List<dynamic> pubKeys = cmds.sublist(1, 1 + totalSigner);

    // Check if the public keys size
    for (var pubKey in pubKeys) {
      if (pubKey.length != 33 && pubKey.length != 65) {
        throw FormatException(
            "Invalid public key length: ${pubKey.length} bytes");
      }
    }
    // Check if the public keys are in lexicographical order.
    for (int i = 0; i < pubKeys.length - 1; i++) {
      Uint8List key1 = pubKeys[i];
      Uint8List key2 = pubKeys[i + 1];
      if (_compareUint8Lists(key1, key2) > 0) {
        throw FormatException("Public keys are not in lexicographical order.");
      }
    }
  }

  static int _compareUint8Lists(Uint8List a, Uint8List b) {
    int minLength = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLength; i++) {
      if (a[i] != b[i]) {
        return a[i] - b[i];
      }
    }
    return a.length - b.length;
  }

  static WitnessScript p2wsh(
      int requiredSignature, int totalSigner, List<Uint8List> publicKeys) {
    List<dynamic> cmds = [];

    publicKeys.sort((a, b) {
      for (int i = 0; i < a.length && i < b.length; i++) {
        if (a[i] != b[i]) {
          return a[i].compareTo(b[i]);
        }
      }
      return a.length
          .compareTo(b.length); // Compare by length if all bytes are equal
    });

    cmds.add(ScriptOperationCode.getHex('OP_${requiredSignature.toString()}'));
    for (var publicKey in publicKeys) {
      cmds.add(publicKey);
    }
    cmds.add(ScriptOperationCode.getHex('OP_${totalSigner.toString()}'));
    cmds.add(ScriptOperationCode.getHex('OP_CHECKMULTISIG'));
    return WitnessScript(cmds);
  }

  int getRequiredSignature() {
    late int required;
    String opCode = ScriptOperationCode.getOpCode(commands[0]);
    try {
      required = int.parse(opCode.replaceAll("OP_", ""));
    } catch (e) {
      throw Exception('Script is not a P2WSH');
    }
    return required;
  }

  List<Uint8List> getPublicKeys() {
    List<Uint8List> publicKeys = [];
    for (dynamic cmd in commands) {
      if (cmd is Uint8List) {
        publicKeys.add(cmd);
      }
    }
    return publicKeys;
  }
}
