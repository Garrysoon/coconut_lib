@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

List<UTXO> manyUtxoList = [
  UTXO('14bb0d89a09a7ce559330855581382c96c57a3c0bdd7b77c87d10479b671709b', 0,
      21000, 'm/84/1/0/0/2', 1722588900, 4322),
  UTXO('0a355cdeb93d9104bf8ef33e9cde1094fd84fb9e425f98ddefd4fd0b937cc868', 0,
      21000, 'm/84/1/0/0/3', 1722589200, 4323),
  UTXO('f2e60d1b9b6a5a94e146fc4a4a2bb53b9506ad92ef8b8c203e3515273757c9e8', 0,
      1000000, 'm/84/1/0/0/5', 1723439400, 7157),
  UTXO('311714f3ad222dd314ad3f2276ebfdfc2ef8ca804bacf61be36c032d7efc0f5c', 1,
      95999716, 'm/84/1/0/1/3', 1723440300, 7160),
  UTXO('3cbe3e9268fe6f17a29b4f51c5ebf8edbd86fbbeeed18be8d92e71d630f25faf', 1,
      95999574, 'm/84/1/0/1/4', 1723529700, 7458),
  UTXO('5bb9e2c8b50e0508cfbec3ab147936bf482f38584c0153f94be53d673c428615', 0,
      100000, 'm/84/1/0/0/6', 1723538400, 7487),
  UTXO('16498840d43c759998275f6f097b9897e52752965b52d91972aa30c95ee2f07f', 0,
      21000, 'm/84/1/0/0/9', 1723541400, 7497),
  UTXO('1361c5a3aed69088eda87dfc3853dad89bdea6e3c8c95f728f3687bd47ed831d', 0,
      4000000, 'm/84/1/0/0/8', 1723541401, 7497),
  UTXO('00b1d81325575dc361dde360cbeb119f18133846ae2c7ca34b831ec850519d5c', 1,
      99899858, 'm/84/1/0/1/5', 1723614000, 7739),
  UTXO('f21638ffb29e64820ce05e1e3fea2118f9940061bbbc47debd9046ff349b6a43', 0,
      100000000, 'm/84/1/0/0/10', 1723615800, 7745),
  UTXO('99189a10b85488e950b181a796eb94fc9e72781671c5fd6dd3086e6bcd2db2a6', 0,
      21000, 'm/84/1/0/0/11', 1723615801, 7745),
  UTXO('b5b9656068d3029b8b68da8c213a89f1bd5f96d6fccd932bb6a27b563a222b80', 0,
      21000, 'm/84/1/0/0/12', 1723616100, 7746),
];

String descriptor =
    'wsh(sortedmulti(2,[AEF5B293/48\'/1\'/0\'/2\']Vpub5nPUGCe9LkKe84RidJpnT4PXxqFCMnp7MFBvksxDAvKGQMuBaCnrS72AXwoWM6JmvDfAdUoAiRPHwAFTP2RvE5kLgkcyMRjgHAqWVkEdWPb/<0;1>/*,[62A936C3/48\'/1\'/0\'/2\']Vpub5nJPDy5rAwoiBH3yiGuABQT8KXzfiq1YWexHeYs3RN2vui8Whp3JsqbWjiEqN5joJWMH7jsjp81CD8AZsaNGhd6DrdNUTneAEEBDaXt1N5d/<0;1>/*,[62A936C3/48\'/1\'/0\'/2\']Vpub5nJPDy5rAwoiBH3yiGuABQT8KXzfiq1YWexHeYs3RN2vui8Whp3JsqbWjiEqN5joJWMH7jsjp81CD8AZsaNGhd6DrdNUTneAEEBDaXt1N5d/<0;1>/*))#5x00xzuf';
void main() async {
  group('MultisignatureWallet', () {
    WalletStatus walletStatus = WalletStatus(
      utxoList: manyUtxoList,
      balance:
          Balance(manyUtxoList.fold(0, (sum, utxo) => sum + utxo.amount), 0),
      transactionList: [],
      blockHeaderMap: {},
      receiveAddressBalanceMap: {},
      changeAddressBalanceMap: {},
      receiveUsedIndexList: [],
      changeUsedIndexList: [],
      receiveMaxGap: 0,
      changeMaxGap: 0,
    );

    // Make WatchOnlyWallet for multisig
    MultisignatureWallet watchOnlyWallet =
        MultisignatureWallet.fromDescriptor(descriptor);

    watchOnlyWallet.walletStatus = walletStatus;

    group('getUtxoList', () {
      test('파라미터가 없을 경우 전체 UTXO를 반환한다.', () {
        List<UTXO> utxoList = watchOnlyWallet.getUtxoList();

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
      });

      test('count 갯수만큼 UTXO를 반환한다.', () {
        List<UTXO> utxoList = watchOnlyWallet.getUtxoList(cursor: 0, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.transactionHash,
            'b5b9656068d3029b8b68da8c213a89f1bd5f96d6fccd932bb6a27b563a222b80');
        expect(utxoList.last.transactionHash,
            '1361c5a3aed69088eda87dfc3853dad89bdea6e3c8c95f728f3687bd47ed831d');
      });

      test('cursor 위치 부터 count 갯수만큼 UTXO를 반환한다.', () {
        List<UTXO> utxoList = watchOnlyWallet.getUtxoList(cursor: 3, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.transactionHash,
            '00b1d81325575dc361dde360cbeb119f18133846ae2c7ca34b831ec850519d5c');
        expect(utxoList.last.transactionHash,
            '3cbe3e9268fe6f17a29b4f51c5ebf8edbd86fbbeeed18be8d92e71d630f25faf');
      });

      test('cursor가 전체 UTXO 갯수보다 클 경우 빈 리스트를 반환한다.', () {
        List<UTXO> utxoList =
            watchOnlyWallet.getUtxoList(cursor: 100, count: 5);

        expect(utxoList.isEmpty, isTrue);
      });

      test('count가 전체 UTXO 갯수보다 클 경우 전체 UTXO를 반환한다.', () {
        List<UTXO> utxoList =
            watchOnlyWallet.getUtxoList(cursor: 0, count: 100);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
      });

      test('order 파라미터가 금액 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            watchOnlyWallet.getUtxoList(order: UtxoOrderEnum.byAmountAsc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
        expect(utxoList.first.amount, 21000);
        expect(utxoList.last.amount, 100000000);
      });

      test('금액 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            watchOnlyWallet.getUtxoList(order: UtxoOrderEnum.byAmountDesc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
        expect(utxoList.first.amount, 100000000);
        expect(utxoList.last.amount, 21000);
      });

      test('타임스탬프 오름차순일 경우 UTXO를 오름차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            watchOnlyWallet.getUtxoList(order: UtxoOrderEnum.byTimestampAsc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
        expect(utxoList.first.timestamp, 1722588900);
        expect(utxoList.last.timestamp, 1723616100);
      });

      test('타임스탬프 내림차순일 경우 UTXO를 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList =
            watchOnlyWallet.getUtxoList(order: UtxoOrderEnum.byTimestampDesc);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
        expect(utxoList.first.timestamp, 1723616100);
        expect(utxoList.last.timestamp, 1722588900);
      });

      test('order 파라미터가 없을 경우 UTXO를 타임스탬프 내림차순으로 정렬하여 반환한다.', () {
        List<UTXO> utxoList = watchOnlyWallet.getUtxoList();

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, manyUtxoList.length);
        expect(utxoList.first.timestamp, 1723616100);
        expect(utxoList.last.timestamp, 1722588900);
      });

      test('금액 오름차순, cursor 3, count 7 테스트', () {
        List<UTXO> utxoList = watchOnlyWallet.getUtxoList(
            order: UtxoOrderEnum.byAmountAsc, cursor: 3, count: 7);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 7);
        expect(utxoList.first.amount, 21000);
        expect(utxoList.last.amount, 95999716);
      });

      test('타임스탬프 오름차순, cursor 5, count 5 테스트', () {
        List<UTXO> utxoList = watchOnlyWallet.getUtxoList(
            order: UtxoOrderEnum.byTimestampAsc, cursor: 5, count: 5);

        expect(utxoList.isNotEmpty, isTrue);
        expect(utxoList.length, 5);
        expect(utxoList.first.timestamp, 1723538400);
        expect(utxoList.last.timestamp, 1723615800);
      });
    });
  });
}
