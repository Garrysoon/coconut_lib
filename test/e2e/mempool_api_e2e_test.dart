@Tags(['e2e'])

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  test('getTransactionStatus가 올바른 형식의 응답을 반환해야 함', () async {
    final status = await MempoolApi.getTransactionStatus(
        '5705602361a79a054449d88b7734ceea869963035bcb35f5d0ec0c8db9d21f37');

    expect(status.confirmed, isTrue);
    expect(status.blockHeight, 50019);
    expect(status.blockHash,
        '0d0dc7f07ddef31e99c52bdead507bc27dac271c13d02e1c875efbf86a5729f3');
    expect(status.blockTime, 1736297700);
  });

  test('getRecommendFee가 올바른 형식의 응답을 반환해야 함', () async {
    final fee = await MempoolApi.getRecommendFee();

    expect(fee.fastestFee, greaterThanOrEqualTo(1));
    expect(fee.halfHourFee, greaterThanOrEqualTo(1));
    expect(fee.hourFee, greaterThanOrEqualTo(1));
    expect(fee.economyFee, greaterThanOrEqualTo(1));
    expect(fee.minimumFee, greaterThanOrEqualTo(1));
  });
}
