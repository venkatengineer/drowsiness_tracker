import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class SafetyScoreCard extends StatelessWidget {
  const SafetyScoreCard({required this.score, super.key});

  final int score;

  Color _getScoreColor() {
    if (score >= 80) return AppColors.safe;
    if (score >= 60) return AppColors.warning;
    return AppColors.urgent;
  }

  String _getScoreLabel() {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Warning';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();
    final scoreLabel = _getScoreLabel();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Safety Score',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  color: scoreColor.withValues(alpha: 0.1),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: val,
                      strokeWidth: 8,
                      color: scoreColor,
                      backgroundColor: Colors.transparent,
                      strokeCap: StrokeCap.round,
                    ),
                  );
                },
              ),
              Text(
                '$score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
