import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/flash_stream_app.dart';
import 'storage/hive_transfer_record_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final recordStore = HiveTransferRecordStore();
  await recordStore.init();

  runApp(FlashStreamApp(recordStore: recordStore));
}
