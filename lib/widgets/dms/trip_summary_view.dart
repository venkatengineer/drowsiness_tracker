import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class TripSummaryView extends StatelessWidget {
  const TripSummaryView({
    required this.startPlace,
    required this.destination,
    required this.durationSeconds,
    required this.breakDurationSeconds,
    required this.safetyScore,
    required this.alertCount,
    required this.eyeClosureCount,
    required this.yawnCount,
    required this.neckDropCount,
    required this.driverStatusText,
    required this.onDone,
    super.key,
  });

  final String startPlace;
  final String destination;
  final int durationSeconds;
  final int breakDurationSeconds;
  final int safetyScore;
  final int alertCount;
  final int eyeClosureCount;
  final int yawnCount;
  final int neckDropCount;
  final String driverStatusText;
  final VoidCallback onDone;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getRatingStars(int score) {
    if (score >= 90) return '⭐⭐⭐⭐⭐ Excellent';
    if (score >= 80) return '⭐⭐⭐⭐ Good';
    if (score >= 60) return '⭐⭐⭐ Average';
    return '⭐⭐ Poor';
  }

  @override
  Widget build(BuildContext context) {
    final double distanceVal = durationSeconds * 0.018; // simulated distance
    const int avgSpeed = 64;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trip Report Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Header Destination Info
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$startPlace → $destination',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trip Performance Rating:',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          _getRatingStars(safetyScore),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Core Stats Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Trip Analytics',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _summaryRow(
                      context,
                      'Total Duration',
                      _formatDuration(durationSeconds),
                    ),
                    _summaryRow(
                      context,
                      'Total Break Duration',
                      _formatDuration(breakDurationSeconds),
                    ),
                    _summaryRow(
                      context,
                      'Distance Travelled',
                      '${distanceVal.toStringAsFixed(1)} km',
                    ),
                    _summaryRow(context, 'Average Speed', '$avgSpeed km/h'),
                    _summaryRow(
                      context,
                      'Driver Active Status',
                      driverStatusText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Telemetry Checklist/Events Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Safety Telemetry Log',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _summaryRow(
                      context,
                      'Safety Score',
                      '$safetyScore/100',
                      valueColor: safetyScore >= 80
                          ? AppColors.safe
                          : (safetyScore >= 60
                                ? AppColors.warning
                                : AppColors.urgent),
                    ),
                    _summaryRow(
                      context,
                      'Drowsiness Alerts',
                      '$alertCount',
                      valueColor: alertCount > 0
                          ? AppColors.urgent
                          : Colors.white,
                    ),
                    _summaryRow(
                      context,
                      'Eye Closure Events',
                      '$eyeClosureCount',
                    ),
                    _summaryRow(context, 'Yawning Events', '$yawnCount'),
                    _summaryRow(context, 'Neck Droop Events', '$neckDropCount'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share & Export Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Simulated sharing of analytics report...',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Report'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Simulated PDF export generation completed!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Export PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Done Button
              ElevatedButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.done_all_rounded),
                label: const Text(
                  'Finish Trip',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safe,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
