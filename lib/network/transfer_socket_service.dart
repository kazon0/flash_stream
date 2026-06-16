import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../core/constants/transfer_constants.dart';
import '../core/errors/transfer_exception.dart';
import '../models/transfer_direction.dart';
import '../models/transfer_event.dart';
import '../models/transfer_record.dart';
import '../models/transfer_status.dart';
import '../protocol/binary_protocol.dart';
import '../protocol/transfer_header.dart';
import '../services/checksum_service.dart';
import '../services/file_chunk_service.dart';
import 'raw_socket_connection.dart';

class TransferSocketService {
  TransferSocketService({
    ChecksumService checksumService = const ChecksumService(),
    FileChunkService fileChunkService = const FileChunkService(),
  }) : _checksumService = checksumService,
       _fileChunkService = fileChunkService;

  final ChecksumService _checksumService;
  final FileChunkService _fileChunkService;
  RawServerSocket? _server;
  static const int _ackSuccess = 1;
  static const int _ackFailure = 0;

  Future<void> startServer({
    required int port,
    required void Function(TransferEvent event) onEvent,
  }) async {
    await stopServer();
    _server = await RawServerSocket.bind(InternetAddress.anyIPv4, port);
    onEvent(
      const TransferEvent(
        status: TransferStatus.listening,
        message: '正在等待其他设备发送文件',
      ),
    );

    _server!.listen((RawSocket socket) async {
      unawaited(_handleIncoming(RawSocketConnection(socket), onEvent));
    });
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  Stream<TransferEvent> sendFile({
    required String ip,
    required int port,
    required File file,
  }) async* {
    if (!await file.exists()) {
      throw const TransferException('文件不存在');
    }

    final fileName = file.uri.pathSegments.last;
    final fileSize = await file.length();

    yield const TransferEvent(
      status: TransferStatus.hashing,
      message: '正在准备文件',
    );
    final md5 = await _checksumService.calculateMd5(file.path);
    final taskId = TransferHeader.stableTaskId(
      fileName: fileName,
      fileSize: fileSize,
      md5: md5,
    );

    final rawSocket = await RawSocket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 5),
    );
    final connection = RawSocketConnection(rawSocket);

    try {
      yield const TransferEvent(status: TransferStatus.connecting);
      final header = TransferHeader(
        taskId: taskId,
        fileName: fileName,
        fileSize: fileSize,
        md5: md5,
      );

      await connection.writeAll(BinaryProtocol.encodeHeader(header));

      final reader = connection.createReader();
      final resumeOffsetBytes = await reader.readExactly(8);
      final resumeOffset = BinaryProtocol.decodeResumeOffset(resumeOffsetBytes);

      final record = TransferRecord(
        id: taskId,
        fileName: fileName,
        fileSize: fileSize,
        md5: md5,
        direction: TransferDirection.send,
        status: TransferStatus.sending,
        createdAt: DateTime.now(),
        path: file.path,
      );

      var sent = resumeOffset;
      yield TransferEvent(
        status: TransferStatus.sending,
        record: record,
        transferredBytes: sent,
        totalBytes: fileSize,
        progress: fileSize == 0 ? 1 : sent / fileSize,
      );

      await for (final chunk in _fileChunkService.openChunkedRead(
        file,
        offset: resumeOffset,
      )) {
        await connection.writeAll(chunk);
        sent += chunk.length;
        yield TransferEvent(
          status: TransferStatus.sending,
          record: record,
          transferredBytes: sent,
          totalBytes: fileSize,
          progress: sent / fileSize,
        );
      }

      yield TransferEvent(
        status: TransferStatus.verifying,
        record: record,
        transferredBytes: fileSize,
        totalBytes: fileSize,
        progress: 1,
        message: '已发送，等待对方保存',
      );
      connection.shutdownSend();
      final ackBytes = await reader
          .readExactly(1)
          .timeout(const Duration(seconds: 30));
      if (ackBytes.first != _ackSuccess) {
        yield TransferEvent(
          status: TransferStatus.failed,
          record: record.copyWith(status: TransferStatus.failed),
          transferredBytes: fileSize,
          totalBytes: fileSize,
          progress: 1,
          message: '对方保存失败',
        );
        return;
      }

      await connection.close();

      yield TransferEvent(
        status: TransferStatus.completed,
        record: record.copyWith(
          status: TransferStatus.completed,
          completedAt: DateTime.now(),
        ),
        transferredBytes: fileSize,
        totalBytes: fileSize,
        progress: 1,
        message: '发送完成',
      );
    } catch (error) {
      yield TransferEvent(
        status: TransferStatus.failed,
        message: '发送失败: $error',
      );
      rethrow;
    } finally {
      connection.destroy();
    }
  }

  Future<void> _handleIncoming(
    RawSocketConnection connection,
    void Function(TransferEvent event) onEvent,
  ) async {
    try {
      final reader = connection.createReader();
      final headerLengthBytes = await reader.readExactly(4);
      final headerLength = ByteData.view(
        headerLengthBytes.buffer,
      ).getUint32(0, Endian.big);
      final headerPayload = await reader.readExactly(headerLength);
      final headerFrame = Uint8List(4 + headerLength);
      headerFrame.setRange(0, 4, headerLengthBytes);
      headerFrame.setRange(4, headerFrame.length, headerPayload);
      final header = BinaryProtocol.decodeHeader(headerFrame);

      final saveDir = await getApplicationDocumentsDirectory();
      final partialFile = File(
        '${saveDir.path}/${header.taskId}${TransferConstants.partialExtension}',
      );
      final finalFile = File('${saveDir.path}/${header.fileName}');
      final resumeOffset = await _resolveResumeOffset(
        partialFile: partialFile,
        fileSize: header.fileSize,
      );
      await connection.writeAll(
        BinaryProtocol.encodeResumeOffset(resumeOffset),
      );

      final record = TransferRecord(
        id: header.taskId,
        fileName: header.fileName,
        fileSize: header.fileSize,
        md5: header.md5,
        direction: TransferDirection.receive,
        status: TransferStatus.receiving,
        createdAt: header.createdAt ?? DateTime.now(),
        path: finalFile.path,
      );

      var received = resumeOffset;
      final writer = await _fileChunkService.openChunkedWrite(
        partialFile,
        mode: FileMode.append,
      );
      try {
        onEvent(
          TransferEvent(
            status: TransferStatus.receiving,
            record: record,
            transferredBytes: received,
            totalBytes: header.fileSize,
            progress: header.fileSize == 0 ? 1 : received / header.fileSize,
          ),
        );

        while (received < header.fileSize) {
          final chunk = await reader.readAvailable();
          if (chunk == null) {
            break;
          }
          final remain = header.fileSize - received;
          final bytes = chunk.length > remain
              ? chunk.sublist(0, remain)
              : chunk;
          await writer.write(bytes);
          received += bytes.length;
          onEvent(
            TransferEvent(
              status: TransferStatus.receiving,
              record: record,
              transferredBytes: received,
              totalBytes: header.fileSize,
              progress: received / header.fileSize,
            ),
          );
        }
      } finally {
        await writer.close();
      }

      if (received != header.fileSize) {
        await connection.writeAll([_ackFailure]);
        onEvent(
          TransferEvent(
            status: TransferStatus.failed,
            record: record.copyWith(status: TransferStatus.failed),
            message: '连接中断，已保留临时文件用于续传',
          ),
        );
        return;
      }

      onEvent(
        TransferEvent(
          status: TransferStatus.verifying,
          record: record,
          transferredBytes: received,
          totalBytes: header.fileSize,
          progress: 1,
          message: '正在保存文件',
        ),
      );
      final actualMd5 = await _checksumService.calculateMd5(partialFile.path);
      if (actualMd5 != header.md5) {
        await partialFile.delete();
        await connection.writeAll([_ackFailure]);
        onEvent(
          TransferEvent(
            status: TransferStatus.failed,
            record: record.copyWith(status: TransferStatus.failed),
            message: '文件接收失败',
          ),
        );
        return;
      }

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partialFile.rename(finalFile.path);
      await connection.writeAll([_ackSuccess]);
      onEvent(
        TransferEvent(
          status: TransferStatus.completed,
          record: record.copyWith(
            status: TransferStatus.completed,
            completedAt: DateTime.now(),
            path: finalFile.path,
          ),
          transferredBytes: header.fileSize,
          totalBytes: header.fileSize,
          progress: 1,
          message: '接收完成',
        ),
      );
    } catch (error) {
      onEvent(
        TransferEvent(status: TransferStatus.failed, message: '接收失败: $error'),
      );
    } finally {
      connection.destroy();
    }
  }

  Future<int> _resolveResumeOffset({
    required File partialFile,
    required int fileSize,
  }) async {
    if (!await partialFile.exists()) {
      return 0;
    }

    final partialLength = await partialFile.length();
    if (partialLength <= fileSize) {
      return partialLength;
    }

    await partialFile.delete();
    return 0;
  }
}
