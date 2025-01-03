part of '../../../coconut_lib.dart';

class IsolateConnectorData {
  final SendPort _sendPort;
  final NodeClientFactory _factory;
  final String _host;
  final int _port;
  final bool _ssl;

  SendPort get sendPort => _sendPort;

  IsolateConnectorData(
      this._sendPort, this._factory, this._host, this._port, this._ssl);
}

enum IsolateMessageType {
  broadcast,
  fullSync,
  getNetworkMinimumFeeRate,
  getBlock,
  getTransaction,
}

abstract class IsolateManager {
  Future<void> initialize(
      NodeClientFactory factory, String host, int port, bool ssl);
  Future<Result<String, CoconutError>> broadcast(String rawTransaction);
  Future<Result<WalletStatus, CoconutError>> fullSync(WalletBase wallet);
  Future<Result<int, CoconutError>> getNetworkMinimumFeeRate();
  Future<Result<BlockTimestamp, CoconutError>> getBlock();
  Future<Result<String, CoconutError>> getTransaction(String txHash);
  void dispose();
}

class DefaultIsolateManager implements IsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort;
  late Completer<void> _isolateReady;

  DefaultIsolateManager() : _receivePort = ReceivePort() {
    _isolateReady = Completer<void>();
  }

  Future<Result<T, CoconutError>> _handleResult<T>(
      Result<dynamic, CoconutError> result) {
    if (result.value is T) {
      return Future.value(result as Result<T, CoconutError>);
    }
    return Future.value(Result.failure(
        CoconutError(ErrorCodeEnum.unknownError, 'Unknown response type')));
  }

  @override
  Future<void> initialize(
      NodeClientFactory factory, String host, int port, bool ssl) async {
    try {
      var data =
          IsolateConnectorData(_receivePort.sendPort, factory, host, port, ssl);
      _isolate = await Isolate.spawn<IsolateConnectorData>(_isolateEntry, data);
      _receivePort.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          _isolateReady.complete();
        }
      }, onError: (error) {
        print('Error in ReceivePort: $error');
        throw error;
      });
      await _isolateReady.future;
    } catch (e) {
      print('Initialization error: $e');
      _isolateReady.completeError(e);
    }
  }

  @override
  Future<Result<String, CoconutError>> broadcast(String rawTransaction) async {
    return _handleResult<String>(
        await _send(IsolateMessageType.broadcast, rawTransaction));
  }

  @override
  Future<Result<WalletStatus, CoconutError>> fullSync(WalletBase wallet) async {
    return _handleResult<WalletStatus>(
        await _send(IsolateMessageType.fullSync, wallet));
  }

  @override
  Future<Result<int, CoconutError>> getNetworkMinimumFeeRate() async {
    return _handleResult<int>(
        await _send(IsolateMessageType.getNetworkMinimumFeeRate, null));
  }

  @override
  Future<Result<BlockTimestamp, CoconutError>> getBlock() async {
    return _handleResult<BlockTimestamp>(
        await _send(IsolateMessageType.getBlock, null));
  }

  @override
  Future<Result<String, CoconutError>> getTransaction(String txHash) async {
    return _handleResult<String>(
        await _send(IsolateMessageType.getTransaction, txHash));
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static void _isolateEntry(IsolateConnectorData data) async {
    final port = ReceivePort();
    data.sendPort.send(port.sendPort);

    port.listen((message) async {
      if (message is List && message.length == 3) {
        final nodeClient =
            await data._factory.create(data._host, data._port, ssl: data._ssl);
        IsolateMessageType messageType = message[0];
        SendPort replyPort = message[1];
        try {
          switch (messageType) {
            case IsolateMessageType.broadcast:
              String rawTransaction = message[2];
              var broadcastResult = await nodeClient.broadcast(rawTransaction);
              replyPort.send(broadcastResult);
              break;
            case IsolateMessageType.fullSync:
              WalletBase wallet = message[2];
              var syncResult = await nodeClient.fullSync(wallet);
              replyPort.send(syncResult);
              break;
            case IsolateMessageType.getNetworkMinimumFeeRate:
              var feeRateResult = await nodeClient.getNetworkMinimumFeeRate();
              replyPort.send(feeRateResult);
              break;
            case IsolateMessageType.getBlock:
              var blockResult = await nodeClient.getBlock();
              replyPort.send(blockResult);
              break;
            case IsolateMessageType.getTransaction:
              String txHash = message[2];
              var transactionResult = await nodeClient.getTransaction(txHash);
              replyPort.send(transactionResult);
              break;
          }
          nodeClient.dispose();
        } catch (e) {
          print('Error in isolate processing: $e');
          replyPort.send(Result.failure(CoconutError(
              ErrorCodeEnum.unknownError, 'Error in isolate processing')));
        }
      }
    }, onError: (error) {
      print('Error in isolate ReceivePort: $error');
    });
  }

  Future<Result<dynamic, CoconutError>> _send(
      IsolateMessageType messageType, message) async {
    if (_sendPort == null) {
      throw Exception('Isolate not initialized');
    }

    final responsePort = ReceivePort();
    _sendPort!.send([messageType, responsePort.sendPort, message]);

    var result = await responsePort.first;
    responsePort.close();

    if (result is Result<dynamic, CoconutError>) {
      return result;
    }

    return Result.failure(
        CoconutError(ErrorCodeEnum.unknownError, 'Unknown response type'));
  }
}
