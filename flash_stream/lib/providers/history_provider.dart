import 'package:flutter/foundation.dart';

import '../models/transfer_record.dart';
import '../services/file_action_service.dart';
import '../storage/transfer_record_store.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(
    this._store, {
    FileActionService fileActionService = const FileActionService(),
  }) : _fileActionService = fileActionService;

  final TransferRecordStore _store;
  final FileActionService _fileActionService;
  String _keyword = '';
  List<TransferRecord> _records = const [];

  String get keyword => _keyword;

  List<TransferRecord> get records => List.unmodifiable(_records);

  void load() {
    _records = _store.search(_keyword);
    notifyListeners();
  }

  void search(String value) {
    _keyword = value;
    load();
  }

  Future<String> openRecord(TransferRecord record) {
    return _fileActionService.openFile(record.path);
  }

  Future<void> shareRecord(TransferRecord record) {
    return _fileActionService.shareFile(record.path);
  }

  Future<String?> exportRecord(TransferRecord record) {
    return _fileActionService.exportFile(record.path);
  }
}
