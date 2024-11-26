@Tags(['integration'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() async {
  String witnessProgram =
      '522103525b642f33199f8adb34c611432158bbfd885c5bed5719e9bc85ba9580bea66821038af6b25b2428600d09f3a9a61cdff43bbe4d76d6ca6cb4f77e0d195007cbc56a210381e1e7501e9a816c4646a012e73500b6524c5249e4d349d18784782d542abb9653ae';
  Script script = WitnessScript.parse(witnessProgram);
  for (var i = 0; i < script.commands.length; i++) {
    print(script.commands[i]);
  }
}
