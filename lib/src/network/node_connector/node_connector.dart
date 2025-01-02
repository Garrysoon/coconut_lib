part of '../../../coconut_lib.dart';

class NodeConnector {
  final IsolateManager _isolateManager;
  Completer<void>? _syncCompleter;
  String _host;
  int _port;
  bool _ssl;
  bool _isConnected = false;
  final Map<int, BlockTimestamp> _blockMap = {};
  int _currentHeight = 0;
  DateTime? _lastUpdatedAt;
  BlockTimestamp get block =>
      _blockMap[_currentHeight] ?? BlockTimestamp(0, DateTime.now());

  bool get isSyncing => _syncCompleter != null;
  bool get isConnected => _isConnected;

  NodeConnector._(this._isolateManager, this._host, this._port, this._ssl);

  Future<BlockTimestamp> fetchBlockSync() async {
    var now = DateTime.now();
    if (_lastUpdatedAt != null) {
      var lastUpdatedAt = _lastUpdatedAt!.add(Duration(seconds: 10));
      if (now.isBefore(lastUpdatedAt)) {
        return _blockMap[_currentHeight]!;
      }
    }
    var block = (await _isolateManager.getBlock()).value!;
    _currentHeight = block.height;
    _lastUpdatedAt = now;
    _blockMap[_currentHeight] = block;

    return block;
  }

  /// Creates a new NodeConnector instance with custom NodeClientFactory
  static Future<NodeConnector> connectSync(
    String host,
    int port, {
    bool ssl = true,
    NodeClientFactory? nodeClientFactory,
    IsolateManager? isolateManager,
  }) async {
    final manager = isolateManager ?? DefaultIsolateManager();
    final factory = nodeClientFactory ?? ElectrumNodeClientFactory();

    await manager.initialize(factory, host, port, ssl);

    final connector = NodeConnector._(manager, host, port, ssl);
    await connector.fetchBlockSync();

    connector._isConnected = true;
    return connector;
  }

  BlockTimestamp get currentBlock {
    var block = _blockMap[_currentHeight]!;

    fetchBlockSync().then((_) {});

    return block;
  }

  Future<Result<String, CoconutError>> broadcast(String rawTransaction) async {
    return _isolateManager.broadcast(rawTransaction);
  }

  Future<Result<WalletStatus, CoconutError>> fetch(WalletBase wallet) async {
    if (_syncCompleter != null) {
      return Future.value(Result.failure(
          CoconutError(ErrorCodeEnum.alreadySyncing, 'Already syncing.')));
    }
    _syncCompleter = Completer<void>();

    try {
      if (!_isConnected) {
        return Result.failure(CoconutError(ErrorCodeEnum.electrumRpcError,
            'The RPC server is not connected.'));
      }

      return await _isolateManager.fullSync(wallet);
    } finally {
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  Future<Result<int, CoconutError>> getNetworkMinimumFeeRate() async {
    return _isolateManager.getNetworkMinimumFeeRate();
  }

  void stopFetching() {
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      _syncCompleter?.completeError(CoconutError(
          ErrorCodeEnum.networkDisconnected, 'Network disconnected.'));
    }
    dispose();
  }

  void dispose() {
    _syncCompleter = null;
    _isolateManager.dispose();
  }
}
