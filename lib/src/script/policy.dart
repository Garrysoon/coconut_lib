part of '../../coconut_lib.dart';

/// Base class for script policies.
abstract class Policy {
  /// Convert the policy to a script.
  Script toScript(int addressIndex, {bool isChange = false});
  String toMiniscript();

  static Policy fromMiniscript(String miniscript) {
    if (miniscript.startsWith('and_v(v:pk(') && miniscript.contains('older(')) {
      return InheritancePolicy.fromMiniscript(miniscript);
    } else {
      throw Exception('Unsupported miniscript type.');
    }
  }
}
