import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class SoftRadar extends StatefulWidget {
  const SoftRadar({
    required this.active,
    this.icon = Icons.search_rounded,
    super.key,
  });

  final bool active;
  final IconData icon;

  @override
  State<SoftRadar> createState() => _SoftRadarState();
}

class _SoftRadarState extends State<SoftRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoftRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final delay in const [0.0, 0.33, 0.66])
                _RadarRing(progress: (_controller.value + delay) % 1),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.slate,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: AppColors.slateDeep, size: 28),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 0.55 + progress * 1.2;
    final opacity = (1 - progress).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.slateButton.withValues(alpha: 0.34),
              width: 5 - progress * 3,
            ),
          ),
        ),
      ),
    );
  }
}

class GummyLoader extends StatefulWidget {
  const GummyLoader({super.key});

  @override
  State<GummyLoader> createState() => _GummyLoaderState();
}

class _GummyLoaderState extends State<GummyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: _scaleFor(index),
                  child: const CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.slateDeep,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _scaleFor(int index) {
    final shifted = (_controller.value + index * 0.18) % 1;
    return shifted < 0.45 ? 0.4 + shifted / 0.45 * 0.8 : 0.4;
  }
}
