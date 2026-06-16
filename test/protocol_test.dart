import 'package:flash_stream/protocol/binary_protocol.dart';
import 'package:flash_stream/protocol/transfer_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes and decodes transfer header', () {
    final header = TransferHeader(
      taskId: 'task-1',
      fileName: 'video.mp4',
      fileSize: 1024,
      md5: 'abc123',
      offset: 128,
      createdAt: DateTime.parse('2026-06-16T10:00:00.000'),
    );

    final encoded = BinaryProtocol.encodeHeader(header);
    final decoded = BinaryProtocol.decodeHeader(encoded);

    expect(decoded.taskId, header.taskId);
    expect(decoded.fileName, header.fileName);
    expect(decoded.fileSize, header.fileSize);
    expect(decoded.md5, header.md5);
    expect(decoded.offset, header.offset);
  });

  test('encodes and decodes resume offset', () {
    const offset = 1024 * 1024 * 512;

    final encoded = BinaryProtocol.encodeResumeOffset(offset);
    final decoded = BinaryProtocol.decodeResumeOffset(encoded);

    expect(decoded, offset);
  });
}
