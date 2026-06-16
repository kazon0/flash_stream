import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../core/constants/transfer_constants.dart';

class FileChunkService {
  const FileChunkService();

  Future<IsolateFileWriter> openChunkedWrite(
    File file, {
    FileMode mode = FileMode.append,
  }) {
    return IsolateFileWriter.open(file, mode: mode);
  }

  Stream<List<int>> openChunkedRead(File file, {int offset = 0}) async* {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final isolate = await Isolate.spawn<_ChunkReadRequest>(
      _readChunksInIsolate,
      _ChunkReadRequest(
        path: file.path,
        offset: offset,
        sendPort: receivePort.sendPort,
      ),
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    Object? isolateError;
    final errorSubscription = errorPort.listen((message) {
      isolateError = message;
      receivePort.close();
    });

    try {
      await for (final message in receivePort) {
        if (isolateError != null) {
          throw FileSystemException(
            'File chunk isolate failed: $isolateError',
            file.path,
          );
        }

        if (message == null) {
          break;
        }

        if (message is _ChunkReadFailure) {
          throw FileSystemException(message.message, file.path);
        }

        if (message is Uint8List) {
          yield message;
        }
      }
    } finally {
      isolate.kill(priority: Isolate.immediate);
      await errorSubscription.cancel();
      receivePort.close();
      errorPort.close();
      exitPort.close();
    }
  }
}

class IsolateFileWriter {
  IsolateFileWriter._({
    required File file,
    required Isolate isolate,
    required SendPort commandPort,
    required ReceivePort responsePort,
  }) : _file = file,
       _isolate = isolate,
       _commandPort = commandPort,
       _responsePort = responsePort {
    _responseSubscription = _responsePort.listen(_handleResponse);
  }

  final File _file;
  final Isolate _isolate;
  final SendPort _commandPort;
  final ReceivePort _responsePort;
  late final StreamSubscription<dynamic> _responseSubscription;
  final Map<int, Completer<void>> _pending = <int, Completer<void>>{};
  var _nextId = 0;
  var _closed = false;

  static Future<IsolateFileWriter> open(
    File file, {
    FileMode mode = FileMode.append,
  }) async {
    final initPort = ReceivePort();
    final responsePort = ReceivePort();
    final isolate = await Isolate.spawn<_ChunkWriteRequest>(
      _writeChunksInIsolate,
      _ChunkWriteRequest(
        path: file.path,
        mode: mode,
        initPort: initPort.sendPort,
        responsePort: responsePort.sendPort,
      ),
    );

    final commandPort = await initPort.first as SendPort;
    initPort.close();
    return IsolateFileWriter._(
      file: file,
      isolate: isolate,
      commandPort: commandPort,
      responsePort: responsePort,
    );
  }

  Future<void> write(List<int> bytes) {
    if (_closed) {
      throw StateError('File writer is already closed');
    }

    final id = _nextId++;
    final completer = Completer<void>();
    _pending[id] = completer;
    _commandPort.send(<String, Object?>{
      'type': 'write',
      'id': id,
      'bytes': Uint8List.fromList(bytes),
    });
    return completer.future;
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    final id = _nextId++;
    final completer = Completer<void>();
    _pending[id] = completer;
    _commandPort.send(<String, Object?>{'type': 'close', 'id': id});
    await completer.future;
    await _responseSubscription.cancel();
    _responsePort.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  void _handleResponse(dynamic message) {
    if (message is! Map) {
      return;
    }

    final id = message['id'] as int?;
    if (id == null) {
      return;
    }

    final completer = _pending.remove(id);
    if (completer == null) {
      return;
    }

    final error = message['error'];
    if (error == null) {
      completer.complete();
    } else {
      completer.completeError(
        FileSystemException(error.toString(), _file.path),
      );
    }
  }
}

class _ChunkReadRequest {
  const _ChunkReadRequest({
    required this.path,
    required this.offset,
    required this.sendPort,
  });

  final String path;
  final int offset;
  final SendPort sendPort;
}

class _ChunkReadFailure {
  const _ChunkReadFailure(this.message);

  final String message;
}

class _ChunkWriteRequest {
  const _ChunkWriteRequest({
    required this.path,
    required this.mode,
    required this.initPort,
    required this.responsePort,
  });

  final String path;
  final FileMode mode;
  final SendPort initPort;
  final SendPort responsePort;
}

void _readChunksInIsolate(_ChunkReadRequest request) {
  final file = File(request.path);
  RandomAccessFile? raf;
  try {
    raf = file.openSync();
    raf.setPositionSync(request.offset);
    final buffer = Uint8List(TransferConstants.chunkSize);

    while (true) {
      final read = raf.readIntoSync(buffer);
      if (read == 0) {
        break;
      }
      request.sendPort.send(Uint8List.fromList(buffer.sublist(0, read)));
    }
    request.sendPort.send(null);
  } catch (error) {
    request.sendPort.send(_ChunkReadFailure(error.toString()));
  } finally {
    raf?.closeSync();
  }
}

void _writeChunksInIsolate(_ChunkWriteRequest request) {
  final commandPort = ReceivePort();
  request.initPort.send(commandPort.sendPort);

  RandomAccessFile? raf;
  try {
    raf = File(request.path).openSync(mode: request.mode);
  } catch (error) {
    request.responsePort.send(<String, Object?>{
      'id': -1,
      'error': error.toString(),
    });
    commandPort.close();
    return;
  }

  commandPort.listen((dynamic message) {
    if (message is! Map) {
      return;
    }

    final id = message['id'] as int;
    try {
      switch (message['type']) {
        case 'write':
          final bytes = message['bytes'] as Uint8List;
          raf!.writeFromSync(bytes);
          request.responsePort.send(<String, Object?>{'id': id});
        case 'close':
          raf!.closeSync();
          raf = null;
          request.responsePort.send(<String, Object?>{'id': id});
          commandPort.close();
      }
    } catch (error) {
      request.responsePort.send(<String, Object?>{
        'id': id,
        'error': error.toString(),
      });
    }
  });
}
