import 'package:flash_stream/app/flash_stream_app.dart';
import 'package:flash_stream/models/transfer_record.dart';
import 'package:flash_stream/storage/transfer_record_store.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransferRecordStore implements TransferRecordStore {
  final List<TransferRecord> _records = [];

  @override
  Future<void> init() async {}

  @override
  List<TransferRecord> getAll() => List.unmodifiable(_records);

  @override
  List<TransferRecord> search(String keyword) => getAll();

  @override
  Future<void> upsert(TransferRecord record) async {
    _records.removeWhere((item) => item.id == record.id);
    _records.add(record);
  }
}

void main() {
  testWidgets('renders transfer home page', (tester) async {
    await tester.pumpWidget(
      FlashStreamApp(recordStore: FakeTransferRecordStore()),
    );

    expect(find.text('FlashStream'), findsOneWidget);
    expect(find.text('发送'), findsOneWidget);
    expect(find.text('接收'), findsOneWidget);
    expect(find.text('发送到附近设备'), findsOneWidget);

    await tester.tap(find.text('接收'));
    await tester.pumpAndSettle();

    expect(find.text('接收文件'), findsOneWidget);
  });
}
