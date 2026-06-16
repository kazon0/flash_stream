import '../models/transfer_record.dart';

abstract class TransferRecordStore {
  Future<void> init();

  Future<void> upsert(TransferRecord record);

  List<TransferRecord> getAll();

  List<TransferRecord> search(String keyword);
}
