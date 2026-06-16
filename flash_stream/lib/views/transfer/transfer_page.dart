import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../providers/history_provider.dart';
import '../history/history_page.dart';
import 'widgets/connection_status_card.dart';
import 'widgets/receiver_panel.dart';
import 'widgets/sender_panel.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransferPageContent();
  }
}

class _TransferPageContent extends StatefulWidget {
  const _TransferPageContent();

  @override
  State<_TransferPageContent> createState() => _TransferPageContentState();
}

class _TransferPageContentState extends State<_TransferPageContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 4, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlashStream',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
              SizedBox(height: 2),
              Text(
                '轻松分享，随时传递',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: '传输记录',
            onPressed: () {
              context.read<HistoryProvider>().load();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
              );
            },
            icon: const Icon(Icons.history),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: const [
            ConnectionStatusCard(),
            SizedBox(height: 18),
            ReceiverPanel(),
            SizedBox(height: 18),
            SenderPanel(),
          ],
        ),
      ),
    );
  }
}
