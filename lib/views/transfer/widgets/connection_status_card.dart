import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../models/transfer_status.dart';
import '../../../providers/transfer_provider.dart';
import 'file_summary_tile.dart';
import 'soft_radar.dart';

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferProvider>();
    final record = provider.currentRecord;
    final transferred = FileSizeFormatter.format(provider.transferredBytes);
    final total = FileSizeFormatter.format(provider.totalBytes);

    return Card(
      color: AppColors.slate,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  provider.isListening ? Icons.wifi_tethering : Icons.bolt,
                  color: AppColors.slateDeep,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.status.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slateDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (record != null) ...[
              const SizedBox(height: 12),
              FileSummaryTile(
                record: record,
                onOpen: provider.status == TransferStatus.completed
                    ? () async {
                        final message = await provider.openCurrentFile();
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Text(
                    provider.totalBytes == 0 ? '状态良好' : '$transferred / $total',
                    style: const TextStyle(
                      color: AppColors.slateDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (provider.status == TransferStatus.listening ||
                      provider.status == TransferStatus.receiving ||
                      provider.status == TransferStatus.sending)
                    const GummyLoader()
                  else
                    Text(
                      provider.totalBytes == 0
                          ? ''
                          : '${(provider.progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.slateDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: provider.progress == 0 ? null : provider.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.45),
                color: AppColors.slateDeep,
              ),
            ),
            if (provider.status == TransferStatus.completed &&
                record?.path != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final path = await provider.exportCurrentFile();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(path == null ? '已取消导出' : '已导出'),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$error')));
                        }
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('导出'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          await provider.shareCurrentFile();
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$error')));
                        }
                      },
                      icon: const Icon(Icons.ios_share),
                      label: const Text('分享'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
