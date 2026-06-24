import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_button.dart';
import '../glass_card.dart';

class TripControlPanel extends StatelessWidget {
  const TripControlPanel({required this.onEndTrip, super.key});

  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
            Colors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: 24,
            child: Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'End Trip',
                    icon: Icons.stop_rounded,
                    color: AppColors.urgent,
                    onPressed: onEndTrip,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
