import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../models/transfer_direction.dart';
import '../../../models/transfer_status.dart';
import '../../../providers/transfer_provider.dart';
import 'transfer_panel_widgets.dart';

class SenderPanel extends StatelessWidget {
  const SenderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferProvider>();
    final record = provider.currentRecord;
    final isSendRecord = record?.direction == TransferDirection.send;
    final isTransferActive =
        isSendRecord &&
        (provider.status == TransferStatus.hashing ||
            provider.status == TransferStatus.connecting ||
            provider.status == TransferStatus.sending ||
            provider.status == TransferStatus.verifying ||
            provider.status == TransferStatus.completed);

    return PanelShell(
      children: [
        PanelHeader(
          icon: Icons.send_rounded,
          title: '发送到附近设备',
          subtitle: '先查找，再选择设备',
          trailing: TextButton.icon(
            onPressed: provider.isScanning ? null : provider.scanDevices,
            icon: provider.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded, size: 18),
            label: Text(provider.isScanning ? '查找中' : '查找'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.slateDeep,
              backgroundColor: AppColors.slate,
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
        if (provider.isScanning)
          const SearchStateCard(
            icon: Icons.search_rounded,
            title: '正在查找附近设备',
            subtitle: '让另一台手机保持接收页面打开，并连接同一 Wi-Fi。',
            animate: true,
          )
        else if (provider.discoveredDevices.isNotEmpty) ...[
          _DeviceList(provider: provider),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: provider.selectedDevice == null
                  ? null
                  : provider.pickAndSendToSelectedDevice,
              icon: const Icon(Icons.file_upload_rounded),
              label: const Text('选择文件并发送'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.slateButton,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ] else if (provider.hasScannedDevices)
          Column(
            children: [
              const SearchStateCard(
                icon: Icons.wifi_off_rounded,
                title: '未发现接收设备',
                subtitle: '请先在另一台手机点击“接收”，然后重新查找。',
                animate: false,
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.scanDevices,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新查找'),
                ),
              ),
            ],
          )
        else
          const SearchStateCard(
            icon: Icons.devices_rounded,
            title: '查找接收设备',
            subtitle: '另一台手机打开接收后，点击右上角“查找”。',
            animate: false,
          ),
        if (isTransferActive && record != null) ...[
          const SizedBox(height: 12),
          TransferInlineCard(
            title: provider.status == TransferStatus.completed
                ? '发送完成'
                : provider.status.label,
            detail: provider.selectedDevice == null
                ? '正在发送文件'
                : '发送到 ${provider.selectedDevice!.name}',
            record: record,
            progress: provider.progress,
            transferredBytes: provider.transferredBytes,
            totalBytes: provider.totalBytes,
            memoryText: '低 · 分片传输',
            onOpen: provider.status == TransferStatus.completed
                ? () => _showMessage(context, provider.openCurrentFile())
                : null,
            showActions: provider.status == TransferStatus.completed,
            onExport: () => _showExportMessage(context, provider),
            onShare: () => _shareCurrent(context, provider),
          ),
        ],
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

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.provider});

  final TransferProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final device in provider.discoveredDevices)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Material(
              color: provider.selectedDevice?.ip == device.ip
                  ? AppColors.slate
                  : const Color(0xFFF8FBFD),
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () => provider.selectDevice(device),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 57),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    children: [
                      const SoftIcon(icon: Icons.smartphone_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '附近可接收 · 同一网络',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.selectedDevice?.ip == device.ip)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.slateButton,
                        )
                      else
                        const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
