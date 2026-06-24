import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/dms_providers.dart';
import '../glass_card.dart';

class DriverStatusCard extends StatelessWidget {
  const DriverStatusCard({
    required this.status,
    required this.eyes,
    required this.mouth,
    required this.neck,
    super.key,
  });

  final DMSStatus status;
  final String eyes;
  final String mouth;
  final String neck;

  Color _getStatusColor() {
    return switch (status) {
      DMSStatus.safe => AppColors.safe,
      DMSStatus.warning => AppColors.warning,
      DMSStatus.drowsy => AppColors.urgent,
    };
  }

  String _getStatusText() {
    return switch (status) {
      DMSStatus.safe => 'SAFE',
      DMSStatus.warning => 'WARNING',
      DMSStatus.drowsy => 'DROWSY',
    };
  }

  IconData _getStatusIcon() {
    return switch (status) {
      DMSStatus.safe => Icons.check_circle_outline_rounded,
      DMSStatus.warning => Icons.error_outline_rounded,
      DMSStatus.drowsy => Icons.warning_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final statusColor = _getStatusColor();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver Status',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(), color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _indicatorRow(
            context,
            'Eyes Detection',
            eyes,
            eyes.toLowerCase().contains('open')
                ? AppColors.safe
                : AppColors.urgent,
          ),
          const SizedBox(height: 8),
          _indicatorRow(
            context,
            'Mouth Detection',
            mouth,
            mouth.toLowerCase().contains('closed')
                ? AppColors.safe
                : AppColors.warning,
          ),
          const SizedBox(height: 8),
          _indicatorRow(
            context,
            'Neck Alignment',
            neck,
            neck.toLowerCase().contains('normal')
                ? AppColors.safe
                : AppColors.warning,
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hub_outlined,
                color: secondaryTextColor.withValues(alpha: 0.35),
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                'Future YOLO Inference Integration Active',
                style: TextStyle(
                  color: secondaryTextColor.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicatorRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
