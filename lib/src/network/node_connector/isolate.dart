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
    var result = await _send(IsolateMessageType.broadcast, rawTransaction);

    if (result.value is String) {
      return result as Result<String, CoconutError>;
    }

    return result as Result<String, CoconutError>;
  }

  @override
  Future<Result<WalletStatus, CoconutError>> fullSync(WalletBase wallet) async {
    var result = await _send(IsolateMessageType.fullSync, wallet);

    if (result.value is WalletStatus) {
      return result as Result<WalletStatus, CoconutError>;
    }

    return Result.failure(
        CoconutError(ErrorCodeEnum.unknownError, 'Unknown response type'));
  }

  @override
  Future<Result<BlockTimestamp, CoconutError>> getBlock() async {
    var result = await _send(IsolateMessageType.getBlock, null);

    if (result.value is BlockTimestamp) {
      return result as Result<BlockTimestamp, CoconutError>;
    }

    return Result.failure(
        CoconutError(ErrorCodeEnum.unknownError, 'Unknown response type'));
  }

  @override
  Future<Result<int, CoconutError>> getNetworkMinimumFeeRate() async {
    var result = await _send(IsolateMessageType.getNetworkMinimumFeeRate, null);

    return result as Result<int, CoconutError>;
  }

  @override
  Future<Result<String, CoconutError>> getTransaction(String txHash) async {
    var result = await _send(IsolateMessageType.getTransaction, txHash);

    return result as Result<String, CoconutError>;
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
