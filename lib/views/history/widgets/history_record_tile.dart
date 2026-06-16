import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../../../models/transfer_record.dart';
import '../../../providers/history_provider.dart';

class HistoryRecordTile extends StatelessWidget {
  const HistoryRecordTile({required this.record, super.key});

  final TransferRecord record;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HistoryProvider>();

    return ListTile(
      leading: Icon(
        record.direction.name == 'send' ? Icons.north_east : Icons.south_west,
      ),
      title: Text(
        record.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${record.direction.label} · ${record.status.label} · '
        '${FileSizeFormatter.format(record.fileSize)}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          try {
            if (value == 'open') {
              final message = await provider.openRecord(record);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            } else if (value == 'export') {
              final path = await provider.exportRecord(record);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(path == null ? '已取消导出' : '已导出')),
              );
            } else if (value == 'share') {
              await provider.shareRecord(record);
            }
          } catch (error) {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$error')));
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'open',
            child: ListTile(
              leading: Icon(Icons.folder_open),
              title: Text('打开'),
            ),
          ),
          PopupMenuItem(
            value: 'export',
            child: ListTile(leading: Icon(Icons.save_alt), title: Text('导出')),
          ),
          PopupMenuItem(
            value: 'share',
            child: ListTile(leading: Icon(Icons.ios_share), title: Text('分享')),
          ),
        ],
      ),
    );
  }
}
