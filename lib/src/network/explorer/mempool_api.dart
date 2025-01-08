part of '../../../coconut_lib.dart';

class MempoolApi {
  static Client client = Client();

  static String get host {
    switch (BitcoinNetwork.currentNetwork._name) {
      case 'mainnet':
        return 'https://mempool.space';
      case 'testnet':
        return 'https://mempool.space/testnet';
      case 'regtest':
        return 'https://regtest-mempool.coconut.onl';
      default:
        return 'https://mempool.space';
    }
  }

  static Future<RecommendedFee> getRecommendFee() async {
    String urlString = '$host/api/v1/fees/recommended';
    final url = Uri.parse(urlString);
    final response = await client.get(url);

    Map<String, dynamic> jsonMap = jsonDecode(response.body);

    return RecommendedFee.fromJson(jsonMap);
  }
}
