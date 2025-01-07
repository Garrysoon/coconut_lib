part of '../../../coconut_lib.dart';

class NodeConnector {
  final IsolateManager _isolateManager;
  Completer<void>? _syncCompleter;
  final String _host;
  final int _port;
  final bool _ssl;
  SocketConnectionStatus _connectionStatus = SocketConnectionStatus.connecting;
  final Map<int, BlockTimestamp> _blockMap = {};
  int _currentHeight = 0;
  DateTime? _lastBlockUpdatedAt;

  bool get isSyncing => _syncCompleter != null;
  SocketConnectionStatus get connectionStatus => _connectionStatus;
  DateTime? get lastBlockUpdatedAt => _lastBlockUpdatedAt;
  String get host => _host;
  int get port => _port;
  bool get ssl => _ssl;
  BlockTimestamp get currentBlock {
    var block = _blockMap[_currentHeight]!;

    _fetchBlockSync();

    return block;
  }

  NodeConnector._(this._isolateManager, this._host, this._port, this._ssl);

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
    await connector._fetchBlockSync();

    connector._connectionStatus = SocketConnectionStatus.connected;
    return connector;
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
      if (_connectionStatus != SocketConnectionStatus.connected) {
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

  Future<Result<String, CoconutError>> getTransaction(String txHash) async {
    return _isolateManager.getTransaction(txHash);
  }

  void stopFetching() {
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      _syncCompleter?.completeError(CoconutError(
          ErrorCodeEnum.networkDisconnected, 'Network disconnected.'));
    }
    dispose();
  }

  void dispose() {
    _connectionStatus = SocketConnectionStatus.terminated;
    _syncCompleter = null;
    _isolateManager.dispose();
  }

  Future<BlockTimestamp> _fetchBlockSync() async {
    if (_isShouldFetchBlock()) {
      var result = await _isolateManager.getBlock();
      if (result.isFailure) {
        throw result.error!;
      }

      var block = result.value!;
      _currentHeight = block.height;
      _blockMap[_currentHeight] = block;
      return block;
    }

    return _blockMap[_currentHeight]!;
  }

  bool _isShouldFetchBlock() {
    var now = DateTime.now();
    if (_connectionStatus == SocketConnectionStatus.connected &&
        _lastBlockUpdatedAt != null) {
      var lastUpdatedAt = _lastBlockUpdatedAt!.add(Duration(seconds: 10));
      if (now.isBefore(lastUpdatedAt)) {
        return false;
      }
    }
    _lastBlockUpdatedAt = now;
    return true;
  }
}
