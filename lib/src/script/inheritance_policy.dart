part of '../../coconut_lib.dart';

class InheritancePolicy extends Policy {
  TaprootWallet beneficiaryWallet;
  int locktime;

  InheritancePolicy(this.beneficiaryWallet, this.locktime) : super();

  factory InheritancePolicy.fromDescriptor(String descriptor, int locktime) {
    Descriptor beneficiaryDescriptor = Descriptor.parse(descriptor);
    if (!beneficiaryDescriptor._addressType.isTaproot) {
      throw Exception('Only Taproot address type is supported.');
    } else if (beneficiaryDescriptor._keyOriginExpressionList.length > 1) {
      throw Exception('Only single signature address type is supported.');
    } else if (beneficiaryDescriptor.miniscriptList.length > 0) {
      throw Exception('Taproot script is not supported.');
    } else {
      TaprootWallet beneficiaryWallet =
          TaprootWallet.fromDescriptor(descriptor);
      return InheritancePolicy(beneficiaryWallet, locktime);
    }
  }

  @override
  Script toScript(int addressIndex, {bool isChange = false}) {
    List<dynamic> cmds = [];
    Uint8List beneficiaryPublicKey = beneficiaryWallet.keyStoreList[0]
        .getPublicKeyBytes(addressIndex, isChange: isChange);

    Uint8List locktimeBytes = Converter.intToLittleEndianBytes(locktime, 4);
    cmds.add(locktimeBytes);
    cmds.add(ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY'));
    cmds.add(ScriptOperationCode.getHex('OP_DROP'));
    cmds.add(beneficiaryPublicKey);
    cmds.add(ScriptOperationCode.getHex('OP_CHECKSIG'));

    return Script(cmds);
  }

  @override
  String toMiniscript() {
    return 'and_v(v:pk(${beneficiaryWallet.getKeyOriginExpression()}),older($locktime))';
  }

  static Policy fromMiniscript(String miniscript) {
    RegExpMatch match =
        RegExp(r'and_v\(v:pk\((.+)\),older\((\d+)\)\)').firstMatch(miniscript)!;
    String pubkeyHex = match.group(1)!;
    int locktime = int.parse(match.group(2)!);
    return InheritancePolicy(
        TaprootWallet.fromKeyOriginExpression(pubkeyHex), locktime);
  }
}
