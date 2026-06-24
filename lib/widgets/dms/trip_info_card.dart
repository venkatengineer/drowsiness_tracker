import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class TripInfoCard extends StatelessWidget {
  const TripInfoCard({
    required this.destination,
    required this.durationSeconds,
    super.key,
  });

  final String destination;
  final int durationSeconds;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Generate realistic simulated values based on duration
    final double distance = durationSeconds * 0.018; // approx 65 km/h
    final int currentSpeed =
        62 +
        (durationSeconds % 17 < 5 ? 8 : (durationSeconds % 13 < 4 ? -7 : 2));
    const int averageSpeed = 64;

    // ETA is target distance (e.g. 45km) minus distance, divided by speed
    final double remainingKm = (45.0 - distance).clamp(0.0, 45.0);
    final int minutesToArrival = (remainingKm / (averageSpeed / 60)).round();
    final arrivalTime = DateTime.now().add(Duration(minutes: minutesToArrival));
    final etaStr =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.info,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Trip Analytics',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn('DESTINATION', destination, AppColors.info),
              _infoColumn(
                'DURATION',
                _formatDuration(durationSeconds),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn(
                'DISTANCE',
                '${distance.toStringAsFixed(1)} km',
                AppColors.safe,
              ),
              _infoColumn('SPEED', '$currentSpeed km/h', AppColors.warning),
              _infoColumn('AVG SPEED', '$averageSpeed km/h', Colors.white70),
              _infoColumn('ETA', etaStr, AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white30,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
