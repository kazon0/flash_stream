import 'dart:io';

import 'package:flash_stream/core/constants/transfer_constants.dart';
import 'package:flash_stream/services/file_chunk_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads file chunks from offset in isolate', () async {
    final tempDir = await Directory.systemTemp.createTemp('flash_stream_test_');
    final file = File('${tempDir.path}/payload.bin');
    final bytes = List<int>.generate(
      TransferConstants.chunkSize + 256,
      (index) => index % 256,
    );
    await file.writeAsBytes(bytes);

    try {
      final chunks = await const FileChunkService()
          .openChunkedRead(file, offset: 128)
          .toList();
      final readBytes = chunks.expand((chunk) => chunk).toList();

      expect(readBytes, bytes.skip(128).toList());
      expect(chunks.length, greaterThanOrEqualTo(2));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('writes file chunks in isolate', () async {
    final tempDir = await Directory.systemTemp.createTemp('flash_stream_test_');
    final file = File('${tempDir.path}/received.part');
    final first = List<int>.generate(1024, (index) => index % 256);
    final second = List<int>.generate(2048, (index) => (index + 7) % 256);

    try {
      final writer = await const FileChunkService().openChunkedWrite(file);
      await writer.write(first);
      await writer.write(second);
      await writer.close();

      final bytes = await file.readAsBytes();
      expect(bytes, <int>[...first, ...second]);
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
