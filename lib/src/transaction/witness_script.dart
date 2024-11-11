part of '../../coconut_lib.dart';

class WitnessScript extends Script {
  WitnessScript(super._cmds);

  /// Parse the script from the given script hex.
  factory WitnessScript.parse(String script) {
    //print("script : " + Converter.hexToBytes(script).toString());
    return WitnessScript(Script.parse(Converter.hexToBytes(script)));
  }

  static WitnessScript p2wsh(
      int requiredSignature, int totalSignature, List<Uint8List> publicKeys) {
    List<dynamic> cmds = [];
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
    String opCode =
        ScriptOperationCode.getOpCode(commands[0]).replaceAll("OP_", "");
    try {
      required = int.parse(opCode);
    } catch (e) {
      throw Exception('Script is not a P2WSH');
    }
    return required;
  }
}
