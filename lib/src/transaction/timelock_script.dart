part of '../../coconut_lib.dart';

/// Represents a Timelock script for Taproot script path spending.
///
/// Timelock script is used in Taproot to create conditional spending paths
/// with time-based conditions. This class supports emergency recovery scripts
/// with CLTV (CheckLockTimeVerify) or CSV (CheckSequenceVerify) timelocks.
class TimelockScript extends Script {
  TimelockScript(super._cmds);

  /// Parse the timelock script from the given script hex.
  factory TimelockScript.parse(String script) {
    List<dynamic> cmds = Script.parseToCommand(Codec.decodeHex(script));
    return TimelockScript(cmds);
  }

  /// Create a timelock script for emergency recovery with CLTV (CheckLockTimeVerify).
  ///
  /// [locktime] The locktime value (block height or timestamp).
  /// [beneficiaryPublicKey] The x-only public key (32 bytes) for emergency recovery.
  ///
  /// Script structure: <locktime> OP_CHECKLOCKTIMEVERIFY OP_DROP <emergency_pubkey> OP_CHECKSIG
  factory TimelockScript.withCheckLockTimeVerify(
      int locktime, Uint8List beneficiaryPublicKey) {
    if (beneficiaryPublicKey.length != 32) {
      throw ArgumentError(
          'Beneficiary public key must be 32 bytes (x-only public key)');
    }

    List<dynamic> cmds = [];

    // Push locktime (4 bytes, little-endian)
    Uint8List locktimeBytes = Converter.intToLittleEndianBytes(locktime, 4);
    cmds.add(locktimeBytes);

    // OP_CHECKLOCKTIMEVERIFY
    cmds.add(ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY'));

    // OP_DROP (remove the locktime from stack after verification)
    cmds.add(ScriptOperationCode.getHex('OP_DROP'));

    // Push beneficiary public key (32 bytes)
    cmds.add(beneficiaryPublicKey);

    // OP_CHECKSIG
    cmds.add(ScriptOperationCode.getHex('OP_CHECKSIG'));

    return TimelockScript(cmds);
  }

  /// Create a timelock script for emergency recovery with CSV (CheckSequenceVerify).
  ///
  /// [sequence] The sequence value (relative block height or time).
  /// [beneficiaryPublicKey] The x-only public key (32 bytes) for emergency recovery.
  ///
  /// Script structure: <sequence> OP_CHECKSEQUENCEVERIFY OP_DROP <beneficiary_pubkey> OP_CHECKSIG
  factory TimelockScript.withCheckSequenceVerify(
      int sequence, Uint8List beneficiaryPublicKey) {
    if (beneficiaryPublicKey.length != 32) {
      throw ArgumentError(
          'Beneficiary public key must be 32 bytes (x-only public key)');
    }

    List<dynamic> cmds = [];

    // Push sequence (4 bytes, little-endian)
    Uint8List sequenceBytes = Converter.intToLittleEndianBytes(sequence, 4);
    cmds.add(sequenceBytes);

    // OP_CHECKSEQUENCEVERIFY
    cmds.add(ScriptOperationCode.getHex('OP_CHECKSEQUENCEVERIFY'));

    // OP_DROP (remove the sequence from stack after verification)
    cmds.add(ScriptOperationCode.getHex('OP_DROP'));

    // Push beneficiary public key (32 bytes)
    cmds.add(beneficiaryPublicKey);

    // OP_CHECKSIG
    cmds.add(ScriptOperationCode.getHex('OP_CHECKSIG'));

    return TimelockScript(cmds);
  }

  /// Get the beneficiary public key from the timelock script.
  ///
  /// Returns the x-only public key (32 bytes) used for emergency recovery.
  Uint8List? getBeneficiaryPublicKey() {
    // The public key should be the second-to-last element (before OP_CHECKSIG)
    // Structure: <locktime/sequence> OP_CHECKLOCKTIMEVERIFY/OP_CHECKSEQUENCEVERIFY OP_DROP <pubkey> OP_CHECKSIG
    for (int i = commands.length - 2; i >= 0; i--) {
      if (commands[i] is Uint8List) {
        Uint8List data = commands[i] as Uint8List;
        if (data.length == 32) {
          return data;
        }
      }
    }
    return null;
  }

  /// Get the timelock value from the timelock script.
  ///
  /// Returns the locktime (for CLTV) or sequence (for CSV) value.
  int? getTimelockValue() {
    // The timelock value should be the first element
    if (commands.isNotEmpty && commands[0] is Uint8List) {
      Uint8List timelockBytes = commands[0] as Uint8List;
      if (timelockBytes.length == 4) {
        return Converter.littleEndianToInt(timelockBytes);
      }
    }
    return null;
  }

  /// Get the timelock type (CLTV or CSV).
  ///
  /// Returns 'CLTV' if OP_CHECKLOCKTIMEVERIFY is used, 'CSV' if OP_CHECKSEQUENCEVERIFY is used.
  String? getTimelockType() {
    int cltvOpcode = ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY');
    int csvOpcode = ScriptOperationCode.getHex('OP_CHECKSEQUENCEVERIFY');

    for (var cmd in commands) {
      if (cmd is int) {
        if (cmd == cltvOpcode) {
          return 'CLTV';
        } else if (cmd == csvOpcode) {
          return 'CSV';
        }
      }
    }
    return null;
  }

  /// Validate that the timelock script has the correct structure for beneficiary recovery.
  bool isValidTimelockScript() {
    // Should have at least: <timelock> <opcode> OP_DROP <pubkey> OP_CHECKSIG
    if (commands.length < 5) {
      return false;
    }

    // First element should be 4-byte timelock value
    if (commands[0] is! Uint8List || (commands[0] as Uint8List).length != 4) {
      return false;
    }

    // Should have OP_CHECKLOCKTIMEVERIFY or OP_CHECKSEQUENCEVERIFY
    int cltvOpcode = ScriptOperationCode.getHex('OP_CHECKLOCKTIMEVERIFY');
    int csvOpcode = ScriptOperationCode.getHex('OP_CHECKSEQUENCEVERIFY');
    bool hasTimelockOpcode = false;
    for (var cmd in commands) {
      if (cmd is int && (cmd == cltvOpcode || cmd == csvOpcode)) {
        hasTimelockOpcode = true;
        break;
      }
    }
    if (!hasTimelockOpcode) {
      return false;
    }

    // Should have OP_DROP
    int dropOpcode = ScriptOperationCode.getHex('OP_DROP');
    bool hasDrop = commands.any((cmd) => cmd is int && cmd == dropOpcode);
    if (!hasDrop) {
      return false;
    }

    // Should have OP_CHECKSIG at the end
    int checksigOpcode = ScriptOperationCode.getHex('OP_CHECKSIG');
    if (commands.last != checksigOpcode) {
      return false;
    }

    // Should have 32-byte public key
    Uint8List? pubkey = getBeneficiaryPublicKey();
    if (pubkey == null || pubkey.length != 32) {
      return false;
    }

    return true;
  }
}
