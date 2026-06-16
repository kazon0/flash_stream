import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/transfer_constants.dart';

class FileActionService {
  const FileActionService();

  static const MethodChannel _exportChannel = MethodChannel(
    'flash_stream/file_export',
  );

  Future<String> openFile(String? path) async {
    if (path == null || path.isEmpty) {
      return '文件路径不存在';
    }
    if (!await File(path).exists()) {
      return '文件已不存在: $path';
    }
    final result = await OpenFilex.open(path);
    return result.message;
  }

  Future<void> shareFile(String? path) async {
    if (path == null || path.isEmpty || !await File(path).exists()) {
      throw const FileSystemException('文件不存在，无法分享');
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  Future<String?> exportFile(String? path) async {
    if (path == null || path.isEmpty) {
      throw const FileSystemException('文件路径不存在');
    }
    final source = File(path);
    if (!await source.exists()) {
      throw FileSystemException('文件已不存在', path);
    }

    final fileName = source.uri.pathSegments.last;
    if (Platform.isAndroid || Platform.isIOS) {
      return _exportChannel.invokeMethod<String>('exportFile', <String, String>{
        'path': source.path,
        'fileName': fileName,
      });
    }

    final targetPath = await FilePicker.saveFile(
      dialogTitle: '导出文件',
      fileName: fileName,
    );
    if (targetPath == null) {
      return null;
    }

    await _copyFileChunked(source, File(targetPath));
    return targetPath;
  }

  Future<void> _copyFileChunked(File source, File target) async {
    if (source.path == target.path) {
      return;
    }

    final input = await source.open();
    final output = await target.open(mode: FileMode.write);
    try {
      final buffer = List<int>.filled(TransferConstants.chunkSize, 0);
      while (true) {
        final read = await input.readInto(buffer);
        if (read == 0) {
          break;
        }
        await output.writeFrom(buffer, 0, read);
      }
    } finally {
      await input.close();
      await output.close();
    }
  }
}
