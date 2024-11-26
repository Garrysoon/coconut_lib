part of '../../coconut_lib.dart';

class WitnessScript extends Script {
  WitnessScript(super._cmds);

  /// Parse the script from the given script hex.
  factory WitnessScript.parse(String script) {
    return WitnessScript(Script.parse(Converter.hexToBytes(script)));
  }

  static WitnessScript p2wsh(
      int requiredSignature, int totalSignature, List<Uint8List> publicKeys) {
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
    cmds.add(ScriptOperationCode.getHex('OP_${totalSignature.toString()}'));
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
