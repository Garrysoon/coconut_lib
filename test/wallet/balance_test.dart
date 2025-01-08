@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Balance', () {
    group('operator +', () {
      test('Add balances.', () {
        Balance balance1 = Balance(1, 2);
        Balance balance2 = Balance(3, 4);
        Balance balance3 = balance1 + balance2;
        expect(balance3.confirmed, 4);
        expect(balance3.unconfirmed, 6);
      });
    });

    group('toJason', () {
      test('Convert to JSON.', () {
        Balance balance = Balance(1, 2);
        String jsonStr = balance.toJson();
        expect(jsonStr, '{"confirmed":1,"unconfirmed":2}');
        expect(Balance.fromJson(jsonStr), isA<Balance>());
      });
    });
  });
}
