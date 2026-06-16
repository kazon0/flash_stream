import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class RawSocketConnection {
  RawSocketConnection(this._socket) {
    _subscription = _socket.listen(
      _handleEvent,
      onError: _readController.addError,
      onDone: () {
        if (!_readController.isClosed) {
          _readController.close();
        }
      },
    );
  }

  final RawSocket _socket;
  final StreamController<Uint8List> _readController =
      StreamController<Uint8List>();
  late final StreamSubscription<RawSocketEvent> _subscription;

  RawSocketChunkReader createReader() {
    return RawSocketChunkReader(_readController.stream);
  }

  Future<void> writeAll(List<int> bytes) async {
    var offset = 0;
    while (offset < bytes.length) {
      final written = _socket.write(bytes, offset, bytes.length - offset);
      if (written > 0) {
        offset += written;
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        _socket.writeEventsEnabled = true;
      }
    }
  }

  void shutdownSend() {
    _socket.shutdown(SocketDirection.send);
  }

  Future<void> close() async {
    await _socket.close();
    await _subscription.cancel();
    if (!_readController.isClosed) {
      await _readController.close();
    }
  }

  void destroy() {
    unawaited(_socket.close());
    unawaited(_subscription.cancel());
    if (!_readController.isClosed) {
      unawaited(_readController.close());
    }
  }

  void _handleEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read || event == RawSocketEvent.readClosed) {
      while (_socket.available() > 0) {
        final data = _socket.read();
        if (data == null || data.isEmpty) {
          break;
        }
        _readController.add(data);
      }
      if (event == RawSocketEvent.readClosed && !_readController.isClosed) {
        _readController.close();
      }
    }
  }
}

class RawSocketChunkReader {
  RawSocketChunkReader(Stream<Uint8List> stream)
    : _iterator = StreamIterator(stream);

  final StreamIterator<Uint8List> _iterator;
  Uint8List _buffer = Uint8List(0);
  int _offset = 0;

  int get bufferedLength => _buffer.length - _offset;

  Uint8List takeBuffered([int? maxBytes]) {
    final available = bufferedLength;
    if (available <= 0) {
      return Uint8List(0);
    }
    final take = maxBytes == null || maxBytes > available
        ? available
        : maxBytes;
    final bytes = _buffer.sublist(_offset, _offset + take);
    _offset += take;
    _compactIfNeeded();
    return bytes;
  }

  Future<Uint8List> readExactly(int length) async {
    final builder = BytesBuilder(copy: false);
    while (builder.length < length) {
      if (bufferedLength == 0) {
        final hasNext = await _iterator.moveNext();
        if (!hasNext) {
          throw const SocketException(
            'RawSocket closed before enough bytes arrived',
          );
        }
        _buffer = _iterator.current;
        _offset = 0;
      }

      final need = length - builder.length;
      final take = need < bufferedLength ? need : bufferedLength;
      builder.add(_buffer.sublist(_offset, _offset + take));
      _offset += take;
      _compactIfNeeded();
    }
    return builder.takeBytes();
  }

  Future<Uint8List?> readAvailable() async {
    final buffered = takeBuffered();
    if (buffered.isNotEmpty) {
      return buffered;
    }
    final hasNext = await _iterator.moveNext();
    if (!hasNext) {
      return null;
    }
    return _iterator.current;
  }

  void _compactIfNeeded() {
    if (_offset >= _buffer.length) {
      _buffer = Uint8List(0);
      _offset = 0;
    }
  }
}
