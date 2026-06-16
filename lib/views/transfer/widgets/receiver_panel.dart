import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../models/transfer_direction.dart';
import '../../../models/transfer_status.dart';
import '../../../providers/transfer_provider.dart';
import 'transfer_panel_widgets.dart';

class ReceiverPanel extends StatelessWidget {
  const ReceiverPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferProvider>();
    final record = provider.currentRecord;
    final isReceiveRecord = record?.direction == TransferDirection.receive;
    final isReceiving =
        isReceiveRecord &&
        (provider.status == TransferStatus.receiving ||
            provider.status == TransferStatus.verifying);
    final isCompleted =
        isReceiveRecord && provider.status == TransferStatus.completed;

    return PanelShell(
      children: [
        PanelHeader(
          icon: Icons.download_rounded,
          title: '接收文件',
          subtitle: provider.isListening ? '这台手机可被附近设备发现' : '打开后开始等待文件',
          trailing: TextButton.icon(
            onPressed: provider.isListening
                ? provider.stopListening
                : provider.startListening,
            icon: Icon(
              provider.isListening
                  ? Icons.stop_circle_rounded
                  : Icons.download_rounded,
              size: 18,
            ),
            label: Text(provider.isListening ? '停止' : '接收'),
            style: TextButton.styleFrom(
              foregroundColor: provider.isListening
                  ? AppColors.slateDeep
                  : Colors.white,
              backgroundColor: provider.isListening
                  ? AppColors.slate
                  : AppColors.slateButton,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isReceiving && record != null)
          TransferInlineCard(
            title: provider.status.label,
            detail: '正在写入本机',
            record: record,
            progress: provider.progress,
            transferredBytes: provider.transferredBytes,
            totalBytes: provider.totalBytes,
            memoryText: '低 · 写入本机',
          )
        else if (isCompleted && record != null)
          TransferInlineCard(
            title: '接收完成',
            detail: '点击打开',
            record: record,
            progress: 1,
            transferredBytes: record.fileSize,
            totalBytes: record.fileSize,
            memoryText: '已保存',
            onOpen: () => _showMessage(context, provider.openCurrentFile()),
            showActions: true,
            onExport: () => _showExportMessage(context, provider),
            onShare: () => _shareCurrent(context, provider),
          )
        else if (provider.isListening)
          const SearchStateCard(
            icon: Icons.sensors_rounded,
            title: '正在等待接收',
            subtitle: '其他设备可以在附近设备列表中找到这台手机。',
            animate: true,
          )
        else
          const SearchStateCard(
            icon: Icons.inbox_rounded,
            title: '准备接收文件',
            subtitle: '点击右上角“接收”，让附近设备找到这台手机。',
            animate: false,
          ),
      ],
    );
  }

  Future<void> _showMessage(BuildContext context, Future<String> future) async {
    final message = await future;
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showExportMessage(
    BuildContext context,
    TransferProvider provider,
  ) async {
    try {
      final path = await provider.exportCurrentFile();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(path == null ? '已取消导出' : '已导出')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _shareCurrent(
    BuildContext context,
    TransferProvider provider,
  ) async {
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
  }
}
