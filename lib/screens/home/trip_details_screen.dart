import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'trip_screen.dart'; // Import to use the Trip data model

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({required this.trip, super.key});

  final Trip trip;

  Color _getRiskColor() {
    switch (trip.riskLevel.toLowerCase()) {
      case 'high':
        return AppColors.urgent;
      case 'medium':
      case 'moderate':
        return AppColors.warning;
      default:
        return AppColors.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trip Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () => _showPdfExportDialog(context),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text(
                'Convert to PDF',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card - Trip Name and Basic Info
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                trip.tripName,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: riskColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '${trip.riskLevel} Risk',
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // Summary details row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 550;
                            final children = [
                              _SummaryItem(
                                label: 'Date',
                                value: trip.date,
                                icon: Icons.calendar_today_rounded,
                              ),
                              _SummaryItem(
                                label: 'Duration',
                                value: trip.duration,
                                icon: Icons.timer_rounded,
                              ),
                              _SummaryItem(
                                label: 'Time Window',
                                value: '${trip.startTime} - ${trip.endTime}',
                                icon: Icons.schedule_rounded,
                              ),
                            ];

                            if (isWide) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: children
                                    .map((item) => Expanded(child: item))
                                    .toList(),
                              );
                            } else {
                              return Column(
                                children: children
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: item,
                                      ),
                                    )
                                    .toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Visual Analytics & Gauges
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visual Analytics',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 500;

                            final gauges = [
                              _AnalyticsGauge(
                                value: trip.alertnessScore,
                                label: 'Alertness Score',
                                centerText:
                                    '${(trip.alertnessScore * 100).toInt()}%',
                                activeColor: AppColors.safe,
                              ),
                              _AnalyticsGauge(
                                value: trip.drowsinessScore,
                                label: 'Drowsiness Score',
                                centerText:
                                    '${(trip.drowsinessScore * 100).toInt()}%',
                                activeColor: trip.drowsinessScore >= 0.30
                                    ? AppColors.urgent
                                    : (trip.drowsinessScore >= 0.15
                                          ? AppColors.warning
                                          : AppColors.safe),
                              ),
                              _AnalyticsGauge(
                                value: trip.fatigueLevel.toLowerCase() == 'high'
                                    ? 0.85
                                    : (trip.fatigueLevel.toLowerCase() ==
                                              'moderate'
                                          ? 0.50
                                          : 0.15),
                                label: 'Fatigue Level',
                                centerText: trip.fatigueLevel,
                                activeColor:
                                    trip.fatigueLevel.toLowerCase() == 'high'
                                    ? AppColors.urgent
                                    : (trip.fatigueLevel.toLowerCase() ==
                                              'moderate'
                                          ? AppColors.warning
                                          : AppColors.safe),
                              ),
                            ];

                            if (isWide) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: gauges,
                              );
                            } else {
                              return Column(
                                children: gauges
                                    .map(
                                      (gauge) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                        ),
                                        child: gauge,
                                      ),
                                    )
                                    .toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Driver Monitoring Statistics
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Monitoring Statistics',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 550;

                            final stats = [
                              _StatItem(
                                label: 'Yawns Detected',
                                value: trip.yawns.toString(),
                                icon: Icons.sentiment_dissatisfied_outlined,
                                color: AppColors.warning,
                              ),
                              _StatItem(
                                label: 'Total Eye Blinks',
                                value: trip.eyeBlinks.toString(),
                                icon: Icons.remove_red_eye_outlined,
                                color: AppColors.info,
                              ),
                              _StatItem(
                                label: 'Prolonged Closures',
                                value: trip.prolongedClosures.toString(),
                                icon: Icons.visibility_off_outlined,
                                color: AppColors.urgent,
                              ),
                              _StatItem(
                                label: 'Head Tilts',
                                value: trip.headTilts.toString(),
                                icon: Icons.screen_rotation_rounded,
                                color: AppColors.warning,
                              ),
                              _StatItem(
                                label: 'Drowsiness Alerts',
                                value: trip.drowsinessAlerts.toString(),
                                icon: Icons.add_alert_rounded,
                                color: AppColors.urgent,
                              ),
                              _StatItem(
                                label: 'Max Continuous Drive',
                                value: trip.maxContinuousDriving,
                                icon: Icons.local_shipping_outlined,
                                color: AppColors.safe,
                              ),
                            ];

                            if (isWide) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 3.8,
                                    ),
                                itemCount: stats.length,
                                itemBuilder: (context, index) => stats[index],
                              );
                            } else {
                              return Column(
                                children: stats
                                    .map(
                                      (stat) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                        ),
                                        child: stat,
                                      ),
                                    )
                                    .toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPdfExportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PdfExportDialog(trip: trip);
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyticsGauge extends StatelessWidget {
  const _AnalyticsGauge({
    required this.value,
    required this.label,
    required this.centerText,
    required this.activeColor,
  });

  final double value;
  final String label;
  final String centerText;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Track circle
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 9,
                color: activeColor.withValues(alpha: 0.1),
              ),
            ),
            // Progress arc
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                color: activeColor,
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
            // Value text
            Text(
              centerText,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfExportDialog extends StatefulWidget {
  const _PdfExportDialog({required this.trip});

  final Trip trip;

  @override
  State<_PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<_PdfExportDialog> {
  int _currentStep = 0;
  bool _isFinished = false;
  late Timer _timer;

  final List<String> _steps = [
    'Gathering trip telemetry data...',
    'Analyzing eye closures & yawn intervals...',
    'Rendering PDF statistics cards...',
    'Compiling layout & formatting details...',
    'Saving report to local storage...',
  ];

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  void _startGeneration() {
    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isFinished = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassCard(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.urgent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Converting to PDF',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step Progress Checklist
            for (int i = 0; i < _steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: i < _currentStep
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.safe,
                            size: 19,
                          )
                        : (i == _currentStep && !_isFinished)
                        ? const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : i == _steps.length - 1 && _isFinished
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.safe,
                            size: 19,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.2),
                            size: 18,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _steps[i],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: i <= _currentStep
                            ? theme.textTheme.bodyMedium?.color
                            : theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.4,
                              ),
                        fontWeight: i == _currentStep
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              if (i < _steps.length - 1) const SizedBox(height: 10),
            ],

            const SizedBox(height: 28),

            // Linear Progress Indicator
            if (!_isFinished) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ] else ...[
              // Success notice
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.safe.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.safe.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.done_all_rounded, color: AppColors.safe),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Report generated as ${widget.trip.tripName.replaceAll(' → ', '_')}_Report.pdf',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.safe,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simulated opening of PDF document...'),
                        ),
                      );
                    },
                    child: const Text('Open PDF'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
