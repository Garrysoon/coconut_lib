@Tags(['unit', 'network'])
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'socket_manager_test.mocks.dart';

class Callback extends Mock {
  void call();
}

@GenerateMocks([Socket, SecureSocket, SocketFactory, Callback])
void main() {
  group('SocketManager', () {
    late MockSocket mockSocket;
    late MockSocketFactory mockSocketFactory;
    late MockSocketFactory mockErrorSocketFactory;
    late SocketManager socketManager;
    late MockCallback mockCallback;

    setUp(() async {
      mockSocket = MockSocket();
      mockSocketFactory = MockSocketFactory();
      mockErrorSocketFactory = MockSocketFactory();
      mockCallback = MockCallback();

      when(mockSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenAnswer((invocation) =>
              StreamController<Uint8List>().stream.listen(null));
      when(mockSocket.close()).thenAnswer((_) async {});
      when(mockSocketFactory.createSocket('localhost', 1234))
          .thenAnswer((e) async => mockSocket);
      socketManager = SocketManager(factory: mockSocketFactory);
      when(mockErrorSocketFactory.createSocket('localhost', 1234))
          .thenThrow(Error());
    });

    test('서버에 성공적으로 연결되어야 함', () async {
      await socketManager.connect('localhost', 1234, ssl: false);

      expect(socketManager.connectionStatus, SocketConnectionStatus.connected);
      verify(mockSocketFactory.createSocket('localhost', 1234)).called(1);
    });

    test('메시지를 보내고 응답 데이터를 처리해야 함', () async {
      when(mockSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenAnswer((invocation) {
        final onData =
            invocation.positionalArguments[0] as void Function(Uint8List);
        final data = utf8.encode('{"id": 1, "message": "pong"}');
        onData(Uint8List.fromList(data));
        return Stream<Uint8List>.empty().listen(null);
      });

      await socketManager.connect('localhost', 1234, ssl: false);

      Completer completer = Completer();
      socketManager.setCompleter(1, completer);

      await socketManager.send('{"id": 1, "message": "ping"}');

      var result = await completer.future;

      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], equals(1));
      expect(result['message'], equals('pong'));
    });

    test('메시지를 보낼 때 연결이 끊어지면 다시 연결을 시도해야 함', () async {
      MockSocketFactory mockSocketFactory = MockSocketFactory();
      when(mockSocketFactory.createSocket('localhost', 1234))
          .thenAnswer((e) async => mockSocket);
      SocketManager socketManager = SocketManager(factory: mockSocketFactory);

      expect(() => socketManager.send('{"id": 1, "message": "ping"}'),
          throwsA(isA<SocketException>()));
    });

    test('분할된 JSON 데이터를 처리해야 함', () async {
      // Simulate fragmented JSON data reception
      when(mockSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenAnswer((invocation) {
        final onData =
            invocation.positionalArguments[0] as void Function(Uint8List);
        final part1 = utf8.encode('{ "id": 1,');
        final part2 = utf8.encode('"result": {"test":[]}}');

        // Send the first part
        onData(Uint8List.fromList(part1));
        // Send the second part after a slight delay
        Future.delayed(Duration(milliseconds: 1), () {
          onData(Uint8List.fromList(part2));
        });

        return Stream<Uint8List>.empty().listen(null);
      });

      await socketManager.connect('localhost', 1234, ssl: false);

      Completer completer = Completer();
      socketManager.setCompleter(1, completer);

      // Wait for the result from the completer
      var result = await completer.future;

      // Verify the result is a valid JSON object
      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], equals(1));
      expect(result['result'], isA<Map<String, dynamic>>());
      expect(result['result']['test'], isA<List>());
    });

    test('연결 오류를 처리해야 함', () async {
      when(mockSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenThrow(Error());

      await socketManager.connect('localhost', 1234, ssl: false);

      expect(
          socketManager.connectionStatus, SocketConnectionStatus.reconnecting);
    });

    test('최대 연결 시도 횟수 초과 시 종료 상태로 변경되어야 함', () async {
      SocketManager socketManager = SocketManager(
          factory: mockErrorSocketFactory,
          reconnectDelaySeconds: 0,
          maxConnectionAttempts: 3);

      await socketManager.connect('localhost', 1234, ssl: false);

      await Future.delayed(Duration(milliseconds: 1));

      expect(socketManager.connectionStatus, SocketConnectionStatus.terminated);
      verify(mockErrorSocketFactory.createSocket('localhost', 1234)).called(3);
    });

    test('재연결 시도 시 콜백 함수가 실행되어야 함', () async {
      SocketManager socketManager = SocketManager(
          factory: mockErrorSocketFactory,
          reconnectDelaySeconds: 0,
          maxConnectionAttempts: 1);

      socketManager.onReconnect = mockCallback.call;

      await socketManager.connect('localhost', 1234, ssl: false);

      await Future.delayed(Duration(milliseconds: 1));

      verify(mockCallback.call()).called(1);
    });

    test('연결 시도 시 상태가 `connecting`으로 변경되어야 함', () async {
      MockSocketFactory mockSocketFactory = MockSocketFactory();
      when(mockSocketFactory.createSocket('localhost', 1234))
          .thenAnswer((e) async {
        await Future.delayed(Duration(seconds: 1));
        return mockSocket;
      });
      SocketManager socketManager = SocketManager(factory: mockSocketFactory);

      socketManager.connect('localhost', 1234, ssl: false);

      await Future.delayed(Duration(milliseconds: 50));

      expect(socketManager.connectionStatus, SocketConnectionStatus.connecting);
    });

    test('소켓 연결을 종료해야 함', () async {
      await socketManager.connect('localhost', 1234, ssl: false);
      await socketManager.disconnect();

      expect(socketManager.connectionStatus, SocketConnectionStatus.terminated);
      verify(mockSocket.close()).called(1);
    });

    // ... existing code ...

    test('onDone 이벤트 발생 시 연결 상태가 terminated로 변경되어야 함', () async {
      late void Function() onDone;

      when(mockSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenAnswer((invocation) {
        onDone = invocation.namedArguments[#onDone] as void Function();
        return StreamController<Uint8List>().stream.listen(null);
      });

      await socketManager.connect('localhost', 1234, ssl: false);
      expect(socketManager.connectionStatus, SocketConnectionStatus.connected);

      onDone();

      expect(socketManager.connectionStatus, SocketConnectionStatus.terminated);
    });

    test('onError 이벤트 발생 시 재연결을 시도해야 함', () async {
      late void Function(dynamic) onError;

      when(mockSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenAnswer((invocation) {
        onError = invocation.namedArguments[#onError] as void Function(dynamic);
        return StreamController<Uint8List>().stream.listen(null);
      });

      await socketManager.connect('localhost', 1234, ssl: false);
      expect(socketManager.connectionStatus, SocketConnectionStatus.connected);

      onError('테스트 에러');

      expect(
          socketManager.connectionStatus, SocketConnectionStatus.reconnecting);
    });
  });

  group('SocketManager SSL', () {
    late MockSecureSocket mockSecureSocket;
    late MockSocketFactory mockSocketFactory;
    late SocketManager socketManager;

    setUp(() async {
      mockSecureSocket = MockSecureSocket();
      mockSocketFactory = MockSocketFactory();
      socketManager = SocketManager(factory: mockSocketFactory);
      when(mockSocketFactory.createSecureSocket('localhost', 1234))
          .thenAnswer((e) async => mockSecureSocket);
      when(mockSecureSocket.listen(any,
              onError: anyNamed('onError'),
              onDone: anyNamed('onDone'),
              cancelOnError: anyNamed('cancelOnError')))
          .thenAnswer((invocation) =>
              StreamController<Uint8List>().stream.listen(null));
    });

    test('SSL 서버에 성공적으로 연결되어야 함', () async {
      await socketManager.connect('localhost', 1234, ssl: true);

      expect(socketManager.connectionStatus, SocketConnectionStatus.connected);
      verify(mockSocketFactory.createSecureSocket('localhost', 1234)).called(1);
    });
  });
}
