import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class FileActionService {
  const FileActionService();

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
    return FilePicker.saveFile(
      dialogTitle: '导出文件',
      fileName: fileName,
      bytes: await source.readAsBytes(),
    );
  }
}
