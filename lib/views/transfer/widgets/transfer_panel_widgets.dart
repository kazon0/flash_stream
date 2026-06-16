import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../models/transfer_record.dart';
import 'file_summary_tile.dart';
import 'soft_radar.dart';

class PanelShell extends StatelessWidget {
  const PanelShell({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SoftIcon(icon: icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class SoftIcon extends StatelessWidget {
  const SoftIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: AppColors.slateDeep, size: 21),
    );
  }
}

class SearchStateCard extends StatelessWidget {
  const SearchStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.animate,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBDD9EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SoftRadar(active: animate, icon: icon),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class TransferInlineCard extends StatelessWidget {
  const TransferInlineCard({
    required this.title,
    required this.detail,
    required this.record,
    required this.progress,
    required this.transferredBytes,
    required this.totalBytes,
    required this.memoryText,
    this.onOpen,
    this.showActions = false,
    this.onExport,
    this.onShare,
    super.key,
  });

  final String title;
  final String detail;
  final TransferRecord record;
  final double progress;
  final int transferredBytes;
  final int totalBytes;
  final String memoryText;
  final VoidCallback? onOpen;
  final bool showActions;
  final VoidCallback? onExport;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final percent = (normalizedProgress * 100).toStringAsFixed(0);
    final transferred = FileSizeFormatter.format(transferredBytes);
    final total = FileSizeFormatter.format(
      totalBytes == 0 ? record.fileSize : totalBytes,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.slateDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FileSummaryTile(record: record, subtitle: detail, onOpen: onOpen),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: normalizedProgress == 0 ? null : normalizedProgress,
              backgroundColor: const Color(0xFFE5EDF4),
              color: AppColors.slateButton,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricTile(label: '已传输', value: '$transferred / $total'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricTile(label: '内存占用', value: memoryText),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text('导出'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('分享'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
