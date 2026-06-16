import 'package:flutter/material.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../../../core/utils/file_type_icon.dart';
import '../../../models/transfer_record.dart';

class FileSummaryTile extends StatelessWidget {
  const FileSummaryTile({
    required this.record,
    required this.onOpen,
    this.subtitle,
    super.key,
  });

  final TransferRecord record;
  final VoidCallback? onOpen;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = FileTypeIcon.colorFor(record.fileName);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    FileTypeIcon.iconFor(record.fileName),
                    color: color,
                    size: 30,
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Text(
                      FileTypeIcon.labelFor(record.fileName),
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ??
                        '${record.direction.label} · ${FileSizeFormatter.format(record.fileSize)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
