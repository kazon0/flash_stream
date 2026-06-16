import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/history_provider.dart';
import 'widgets/history_record_tile.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('传输记录')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: provider.search,
              decoration: const InputDecoration(
                labelText: '搜索文件名或状态',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.records.isEmpty
                  ? const Center(child: Text('暂无传输记录'))
                  : ListView.separated(
                      itemCount: provider.records.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return HistoryRecordTile(
                          record: provider.records[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
