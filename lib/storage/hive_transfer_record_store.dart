import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/transfer_constants.dart';
import '../models/transfer_record.dart';
import 'transfer_record_store.dart';

class HiveTransferRecordStore implements TransferRecordStore {
  Box<dynamic>? _box;

  Box<dynamic> get _records {
    final box = _box;
    if (box == null) {
      throw StateError('Transfer record store is not initialized');
    }
    return box;
  }

  @override
  Future<void> init() async {
    try {
      _box = await Hive.openBox<dynamic>(TransferConstants.hiveBoxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(TransferConstants.hiveBoxName);
      _box = await Hive.openBox<dynamic>(TransferConstants.hiveBoxName);
    }
  }

  @override
  Future<void> upsert(TransferRecord record) async {
    await _records.put(record.id, record.toJson());
  }

  @override
  List<TransferRecord> getAll() {
    final records = _records.values
        .whereType<Map<dynamic, dynamic>>()
        .map(TransferRecord.fromJson)
        .toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  List<TransferRecord> search(String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) {
      return getAll();
    }
    return getAll().where((record) {
      return record.fileName.toLowerCase().contains(normalized) ||
          record.md5.toLowerCase().contains(normalized) ||
          record.status.label.toLowerCase().contains(normalized) ||
          record.direction.label.toLowerCase().contains(normalized);
    }).toList();
  }
}
