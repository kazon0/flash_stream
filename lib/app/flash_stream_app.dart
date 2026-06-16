import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/transfer_socket_service.dart';
import '../providers/history_provider.dart';
import '../providers/transfer_provider.dart';
import '../storage/transfer_record_store.dart';
import '../views/transfer/transfer_page.dart';
import 'app_theme.dart';

class FlashStreamApp extends StatelessWidget {
  const FlashStreamApp({required this.recordStore, super.key});

  final TransferRecordStore recordStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransferProvider(
            socketService: TransferSocketService(),
            recordStore: recordStore,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(recordStore)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'FlashStream',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const TransferPage(),
      ),
    );
  }
}
