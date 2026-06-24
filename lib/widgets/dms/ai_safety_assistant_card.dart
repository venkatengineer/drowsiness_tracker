import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class AISafetyAssistantCard extends StatelessWidget {
  const AISafetyAssistantCard({required this.recommendation, super.key});

  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final isAlert =
        recommendation.contains('⚠️') ||
        recommendation.toLowerCase().contains('drowsiness') ||
        recommendation.toLowerCase().contains('alert');
    final isWarning =
        recommendation.toLowerCase().contains('yawning') ||
        recommendation.toLowerCase().contains('fatigue');

    Color getBorderColor() {
      if (isAlert) return AppColors.urgent;
      if (isWarning) return AppColors.warning;
      return isDark ? Colors.white12 : Colors.black12;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getBorderColor(), width: 1.2),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Row(
          children: [
            Icon(
              isAlert
                  ? Icons.warning_amber_rounded
                  : (isWarning ? Icons.coffee_rounded : Icons.shield_outlined),
              color: isAlert
                  ? AppColors.urgent
                  : (isWarning ? AppColors.warning : AppColors.safe),
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI SAFETY ASSISTANT',
                    style: TextStyle(
                      fontSize: 9,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    recommendation,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
