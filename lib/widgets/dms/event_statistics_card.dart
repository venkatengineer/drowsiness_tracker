import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class EventStatisticsCard extends StatelessWidget {
  const EventStatisticsCard({
    required this.eyeClosures,
    required this.yawns,
    required this.neckDroops,
    required this.alerts,
    super.key,
  });

  final int eyeClosures;
  final int yawns;
  final int neckDroops;
  final int alerts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Telemetry Events',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _counterItem('EYE CLOSURES', eyeClosures, AppColors.info),
              _counterItem('YAWNS', yawns, AppColors.warning),
              _counterItem('NECK DROOPS', neckDroops, AppColors.warning),
              _counterItem('TOTAL ALERTS', alerts, AppColors.urgent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
