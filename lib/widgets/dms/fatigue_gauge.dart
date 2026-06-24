import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class FatigueGauge extends StatelessWidget {
  const FatigueGauge({required this.level, super.key});

  final String level; // 'Low', 'Moderate', 'High', 'Critical'

  Color _getLevelColor() {
    return switch (level.toLowerCase()) {
      'low' => AppColors.safe,
      'moderate' => AppColors.warning,
      'high' || 'critical' => AppColors.urgent,
      _ => AppColors.safe,
    };
  }

  double _getGaugeValue() {
    return switch (level.toLowerCase()) {
      'low' => 0.25,
      'moderate' => 0.55,
      'high' => 0.80,
      'critical' => 0.95,
      _ => 0.25,
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getLevelColor();
    final progressValue = _getGaugeValue();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Fatigue Meter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progressValue),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 12,
                      color: activeColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
