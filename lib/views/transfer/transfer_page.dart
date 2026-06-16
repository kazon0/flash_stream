import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../providers/history_provider.dart';
import '../history/history_page.dart';
import 'widgets/receiver_panel.dart';
import 'widgets/sender_panel.dart';

enum _TransferMode { send, receive }

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
  _TransferMode _mode = _TransferMode.send;

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
        child: Stack(
          children: [
            const Positioned.fill(child: _BrandWatermark()),
            ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        selected: _mode == _TransferMode.send,
                        icon: Icons.send_rounded,
                        title: '发送',
                        subtitle: '选择设备后发送文件',
                        badge: '查找',
                        onTap: () => setState(() => _mode = _TransferMode.send),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeCard(
                        selected: _mode == _TransferMode.receive,
                        icon: Icons.inbox_rounded,
                        title: '接收',
                        subtitle: '让别人找到这台手机',
                        badge: '开启',
                        onTap: () =>
                            setState(() => _mode = _TransferMode.receive),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _mode == _TransferMode.send
                      ? const SenderPanel(key: ValueKey('send-panel'))
                      : const ReceiverPanel(key: ValueKey('receive-panel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandWatermark extends StatelessWidget {
  const _BrandWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -88,
            bottom: -34,
            child: Opacity(
              opacity: 0.065,
              child: Transform.rotate(
                angle: -0.14,
                child: Image.asset(
                  'assets/brand/app_icon.png',
                  width: 358,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE2F1FB) : AppColors.cardWhite,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 116,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? const Color(0xFFB8D9EE) : AppColors.softBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A4A67).withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SoftIcon(icon: icon),
                  const Spacer(),
                  Container(
                    height: 25,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: selected ? 1 : 0.0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: AppColors.slateDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon});

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
