import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../providers/transfer_provider.dart';

class ReceiverPanel extends StatelessWidget {
  const ReceiverPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferProvider>();

    return Card(
      color: AppColors.slate,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inbox, color: AppColors.slateDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '接收文件',
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
              provider.isListening
                  ? '其他设备现在可以找到这台手机并发送文件。'
                  : '打开接收后，附近同一网络内的设备可以发现这台手机。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slateDeep,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.isListening
                    ? provider.stopListening
                    : provider.startListening,
                icon: Icon(
                  provider.isListening ? Icons.stop_circle : Icons.download,
                ),
                label: Text(provider.isListening ? '停止接收' : '开始接收'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.slateButton,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
