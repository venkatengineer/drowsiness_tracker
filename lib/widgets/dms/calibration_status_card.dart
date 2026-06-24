import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class CalibrationStatusCard extends StatefulWidget {
  const CalibrationStatusCard({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<CalibrationStatusCard> createState() => _CalibrationStatusCardState();
}

class _CalibrationStatusCardState extends State<CalibrationStatusCard> {
  bool _faceDetected = false;
  bool _faceCentered = false;
  bool _lightingGood = false;
  bool _cameraStable = false;

  @override
  void initState() {
    super.initState();
    _startStaggeredChecks();
  }

  void _startStaggeredChecks() {
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _faceDetected = true);
    });
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _faceCentered = true);
    });
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _lightingGood = true);
    });
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() => _cameraStable = true);
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calibration Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _checkRow('Face Detected', _faceDetected),
          _checkRow('Face Centered', _faceCentered),
          _checkRow('Lighting Good', _lightingGood),
          _checkRow('Camera Stable', _cameraStable),
        ],
      ),
    );
  }

  Widget _checkRow(String label, bool checked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.safe.withValues(alpha: 0.16)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              checked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: checked
                  ? AppColors.safe
                  : (isDark ? Colors.white30 : Colors.black30),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: checked ? FontWeight.bold : FontWeight.normal,
              color: checked ? primaryTextColor : secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
