import '../core/constants/transfer_constants.dart';

class TransferHeader {
  const TransferHeader({
    required this.taskId,
    required this.fileName,
    required this.fileSize,
    required this.md5,
    this.chunkSize = TransferConstants.chunkSize,
    this.offset = 0,
    this.createdAt,
  });

  final String taskId;
  final String fileName;
  final int fileSize;
  final String md5;
  final int chunkSize;
  final int offset;
  final DateTime? createdAt;

  Map<String, Object?> toJson() {
    return {
      'taskId': taskId,
      'fileName': fileName,
      'fileSize': fileSize,
      'md5': md5,
      'chunkSize': chunkSize,
      'offset': offset,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory TransferHeader.fromJson(Map<String, dynamic> json) {
    return TransferHeader(
      taskId: json['taskId'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      md5: json['md5'] as String,
      chunkSize: json['chunkSize'] as int? ?? TransferConstants.chunkSize,
      offset: json['offset'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}
