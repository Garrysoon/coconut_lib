part of '../../../coconut_lib.dart';

/// @nodoc
abstract class NodeClient {
  int get gapLimit => 20;
  int get reqId;

  Future<Result<String, CoconutError>> broadcast(String rawTransaction);

  Future<Result<WalletStatus, CoconutError>> fullSync(WalletBase wallet);

  Future<Result<int, CoconutError>> getNetworkMinimumFeeRate();

  Future<Result<BlockTimestamp, CoconutError>> getBlock();

  Future<Result<String, CoconutError>> getTransaction(String txHash);

  void dispose();
}

/// Factory for creating NodeClient instances
abstract class NodeClientFactory {
  Future<NodeClient> create(String host, int port, {bool ssl = true});
}

/// Default implementation of NodeClientFactory that creates ElectrumApi instances
class ElectrumNodeClientFactory implements NodeClientFactory {
  @override
  Future<NodeClient> create(String host, int port, {bool ssl = true}) async {
    return ElectrumApi.connectSync(host, port, ssl: ssl);
  }
}
