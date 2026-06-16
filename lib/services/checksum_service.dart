import 'dart:io';
import 'dart:isolate';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../core/constants/transfer_constants.dart';

class ChecksumService {
  const ChecksumService();

  Future<String> calculateMd5(String path) {
    return Isolate.run(() => _calculateMd5Sync(path));
  }
}

String _calculateMd5Sync(String path) {
  final file = File(path);
  final sink = AccumulatorSink<Digest>();
  final input = md5.startChunkedConversion(sink);
  final raf = file.openSync();
  try {
    final buffer = List<int>.filled(TransferConstants.chunkSize, 0);
    while (true) {
      final read = raf.readIntoSync(buffer);
      if (read == 0) {
        break;
      }
      input.add(buffer.take(read).toList());
    }
    input.close();
    return sink.events.single.toString();
  } finally {
    raf.closeSync();
  }
}
