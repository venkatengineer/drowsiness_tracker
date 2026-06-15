import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';

class StartDrivingScreen extends StatelessWidget {
  const StartDrivingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Start Driving',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor driver alertness in real time.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Status: Waiting for Camera',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Monitoring',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),
                        CustomPaint(
                          painter: _DashedBorderPainter(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videocam_outlined,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Camera Feed Coming Soon',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 680;
                      final cards = const [
                        _StatCard(
                          label: 'Blink Count',
                          value: '0',
                          icon: Icons.remove_red_eye_outlined,
                        ),
                        _StatCard(
                          label: 'Yawns',
                          value: '0',
                          icon: Icons.sentiment_dissatisfied_outlined,
                        ),
                        _StatCard(
                          label: 'Drowsiness Score',
                          value: '0%',
                          icon: Icons.speed_outlined,
                        ),
                      ];
                      if (!isWide) {
                        return Column(
                          children: [
                            for (final card in cards) ...[
                              card,
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (final card in cards)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  GlassButton(
                    label: 'Start Monitoring',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.safe,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 10.0;
    const dashGap = 7.0;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
