import 'package:coconut_lib/coconut_lib.dart';

class TestNodeClient implements NodeClient {
  @override
  int get gapLimit => 20;

  @override
  int get reqId => 1;

  @override
  Future<Result<String, CoconutError>> broadcast(String rawTransaction) async {
    return Result.success('txid');
  }

  @override
  Future<Result<WalletStatus, CoconutError>> fullSync(WalletBase wallet) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<BlockTimestamp, CoconutError>> getBlock() async {
    return Result.success(BlockTimestamp(
        100, DateTime.fromMillisecondsSinceEpoch(1234567890000)));
  }

  @override
  Future<Result<int, CoconutError>> getNetworkMinimumFeeRate() async {
    return Result.success(1000);
  }

  @override
  Future<Result<String, CoconutError>> getTransaction(String txHash) async {
    return Result.success('transaction_data');
  }

  @override
  void dispose() {}
}

class TestNodeClientFactory implements NodeClientFactory {
  @override
  Future<NodeClient> create(String host, int port, {bool ssl = false}) async {
    return TestNodeClient();
  }
}
