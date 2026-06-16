import 'dart:convert';
import 'dart:typed_data';

import 'transfer_header.dart';

class BinaryProtocol {
  const BinaryProtocol._();

  static Uint8List encodeHeader(TransferHeader header) {
    final payload = utf8.encode(jsonEncode(header.toJson()));
    final bytes = Uint8List(4 + payload.length);
    final data = ByteData.view(bytes.buffer);
    data.setUint32(0, payload.length, Endian.big);
    bytes.setRange(4, bytes.length, payload);
    return bytes;
  }

  static TransferHeader decodeHeader(Uint8List frame) {
    final payloadLength = ByteData.view(
      frame.buffer,
      frame.offsetInBytes,
      4,
    ).getUint32(0, Endian.big);
    final payload = frame.sublist(4, 4 + payloadLength);
    return TransferHeader.fromJson(
      jsonDecode(utf8.decode(payload)) as Map<String, dynamic>,
    );
  }

  static Uint8List encodeResumeOffset(int offset) {
    final bytes = Uint8List(8);
    ByteData.view(bytes.buffer).setUint64(0, offset, Endian.big);
    return bytes;
  }

  static int decodeResumeOffset(Uint8List bytes) {
    return ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      8,
    ).getUint64(0, Endian.big);
  }
}
