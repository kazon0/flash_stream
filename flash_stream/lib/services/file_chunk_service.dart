import 'dart:io';

class FileChunkService {
  const FileChunkService();

  Stream<List<int>> openChunkedRead(File file, {int offset = 0}) {
    return file.openRead(offset);
  }
}
