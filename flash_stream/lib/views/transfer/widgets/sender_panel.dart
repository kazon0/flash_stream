import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../providers/transfer_provider.dart';

class SenderPanel extends StatelessWidget {
  const SenderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferProvider>();
    final selectedDevice = provider.selectedDevice;

    return Card(
      color: AppColors.slate,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.slateDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '发送文件',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: provider.isScanning ? null : provider.scanDevices,
                  icon: provider.isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.radar, size: 18),
                  label: Text(provider.isScanning ? '查找中' : '查找'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.slateDeep,
                    backgroundColor: Colors.white.withValues(alpha: 0.55),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.isScanning
                  ? '正在寻找附近正在接收的设备...'
                  : provider.discoveredDevices.isEmpty
                  ? '未发现接收方。请先在另一台设备上点击“开始接收”。'
                  : '选择一个接收设备后发送文件。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slateDeep,
                height: 1.35,
              ),
            ),
            if (selectedDevice != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slateButton),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.near_me, color: AppColors.slateDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '发送到 ${selectedDevice.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      selectedDevice.ip,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: selectedDevice == null
                    ? null
                    : provider.pickAndSendToSelectedDevice,
                icon: const Icon(Icons.file_upload),
                label: const Text('选择文件并发送'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.slateDeep,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (provider.discoveredDevices.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: [
                  for (final device in provider.discoveredDevices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.slateButton),
                        ),
                        tileColor: Colors.white.withValues(alpha: 0.45),
                        dense: true,
                        leading: const Icon(Icons.phone_iphone),
                        title: Text(device.name),
                        subtitle: Text('${device.ip}:${device.port}'),
                        trailing: selectedDevice?.ip == device.ip
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.slateDeep,
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => provider.selectDevice(device),
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
