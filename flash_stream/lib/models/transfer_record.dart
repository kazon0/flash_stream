import 'transfer_direction.dart';
import 'transfer_status.dart';

class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.md5,
    required this.direction,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.path,
  });

  final String id;
  final String fileName;
  final int fileSize;
  final String md5;
  final TransferDirection direction;
  final TransferStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? path;

  TransferRecord copyWith({
    TransferStatus? status,
    DateTime? completedAt,
    String? path,
  }) {
    return TransferRecord(
      id: id,
      fileName: fileName,
      fileSize: fileSize,
      md5: md5,
      direction: direction,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      path: path ?? this.path,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSize': fileSize,
      'md5': md5,
      'direction': direction.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'path': path,
    };
  }

  factory TransferRecord.fromJson(Map<dynamic, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      md5: json['md5'] as String,
      direction: TransferDirection.values.byName(json['direction'] as String),
      status: TransferStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      path: json['path'] as String?,
    );
  }
}
