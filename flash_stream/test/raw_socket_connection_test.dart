import 'dart:convert';
import 'dart:io';

import 'package:flash_stream/network/raw_socket_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes and reads exact bytes over RawSocket', () async {
    final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final serverSocketFuture = server.first;
    final clientSocket = await RawSocket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
    );
    final serverSocket = await serverSocketFuture;

    final client = RawSocketConnection(clientSocket);
    final receiver = RawSocketConnection(serverSocket);

    try {
      await client.writeAll(utf8.encode('flash-stream'));
      final bytes = await receiver.createReader().readExactly(12);

      expect(utf8.decode(bytes), 'flash-stream');
    } finally {
      client.destroy();
      receiver.destroy();
      await server.close();
    }
  });
}
