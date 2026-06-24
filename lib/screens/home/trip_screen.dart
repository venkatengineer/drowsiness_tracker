import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'trip_details_screen.dart';

class Trip {
  final String id;
  final String tripName;
  final String date;
  final String duration;
  final double drowsinessScore; // e.g. 0.18 for 18%
  final String status;
  final int yawns;
  final int eyeBlinks;
  final int prolongedClosures;
  final int headTilts;
  final int drowsinessAlerts;
  final double alertnessScore; // e.g. 0.82 for 82%
  final String fatigueLevel; // e.g. Low, Moderate, High
  final String startTime;
  final String endTime;
  final String maxContinuousDriving;
  final String riskLevel;

  const Trip({
    required this.id,
    required this.tripName,
    required this.date,
    required this.duration,
    required this.drowsinessScore,
    required this.status,
    required this.yawns,
    required this.eyeBlinks,
    required this.prolongedClosures,
    required this.headTilts,
    required this.drowsinessAlerts,
    required this.alertnessScore,
    required this.fatigueLevel,
    required this.startTime,
    required this.endTime,
    required this.maxContinuousDriving,
    required this.riskLevel,
  });
}

class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  static const List<Trip> _dummyTrips = [
    Trip(
      id: '1',
      tripName: 'Chennai → Coimbatore',
      date: '12 June 2026',
      duration: '4h 32m',
      drowsinessScore: 0.18,
      status: 'Completed',
      yawns: 23,
      eyeBlinks: 1487,
      prolongedClosures: 8,
      headTilts: 12,
      drowsinessAlerts: 5,
      alertnessScore: 0.82,
      fatigueLevel: 'Moderate',
      startTime: '06:00 AM',
      endTime: '10:32 AM',
      maxContinuousDriving: '2h 15m',
      riskLevel: 'Low',
    ),
    Trip(
      id: '2',
      tripName: 'Bangalore → Chennai',
      date: '10 June 2026',
      duration: '5h 15m',
      drowsinessScore: 0.08,
      status: 'Completed',
      yawns: 12,
      eyeBlinks: 2100,
      prolongedClosures: 2,
      headTilts: 4,
      drowsinessAlerts: 1,
      alertnessScore: 0.92,
      fatigueLevel: 'Low',
      startTime: '02:00 PM',
      endTime: '07:15 PM',
      maxContinuousDriving: '1h 45m',
      riskLevel: 'Low',
    ),
    Trip(
      id: '3',
      tripName: 'Mumbai → Pune',
      date: '08 June 2026',
      duration: '3h 10m',
      drowsinessScore: 0.34,
      status: 'Completed',
      yawns: 41,
      eyeBlinks: 950,
      prolongedClosures: 19,
      headTilts: 22,
      drowsinessAlerts: 14,
      alertnessScore: 0.66,
      fatigueLevel: 'High',
      startTime: '11:30 PM',
      endTime: '02:40 AM',
      maxContinuousDriving: '3h 10m',
      riskLevel: 'High',
    ),
    Trip(
      id: '4',
      tripName: 'Delhi → Agra',
      date: '05 June 2026',
      duration: '4h 00m',
      drowsinessScore: 0.12,
      status: 'Completed',
      yawns: 18,
      eyeBlinks: 1250,
      prolongedClosures: 4,
      headTilts: 8,
      drowsinessAlerts: 3,
      alertnessScore: 0.88,
      fatigueLevel: 'Low',
      startTime: '05:30 AM',
      endTime: '09:30 AM',
      maxContinuousDriving: '2h 00m',
      riskLevel: 'Low',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Trips',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review your completed journeys and driver alertness analytics.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ..._dummyTrips.map((trip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _TripCard(trip: trip),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  Color _getScoreColor() {
    if (widget.trip.drowsinessScore >= 0.30) {
      return AppColors.urgent;
    } else if (widget.trip.drowsinessScore >= 0.15) {
      return AppColors.warning;
    } else {
      return AppColors.safe;
    }
  }

  IconData _getTripIcon() {
    if (widget.trip.drowsinessScore >= 0.30) {
      return Icons.warning_amber_rounded;
    } else if (widget.trip.drowsinessScore >= 0.15) {
      return Icons.directions_car_filled_rounded;
    } else {
      return Icons.offline_pin_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Icon indicator
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(_getTripIcon(), color: scoreColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.trip.tripName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 200),
                                turns: _isExpanded ? 0.25 : 0,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Theme.of(
                                    context,
                                  ).iconTheme.color?.withValues(alpha: 0.5),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Date & Duration row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.trip.date,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.6),
                                    ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.trip.duration,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Badges
                          Row(
                            children: [
                              // Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  widget.trip.status,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.8,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Drowsiness Score
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: scoreColor.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${(widget.trip.drowsinessScore * 100).toInt()}% Drowsiness',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: scoreColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Collapsible area showing details
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        // Quick Stats Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _QuickStat(
                              icon: Icons.sentiment_dissatisfied_outlined,
                              label: 'Yawns',
                              value: widget.trip.yawns.toString(),
                              color: AppColors.warning,
                            ),
                            _QuickStat(
                              icon: Icons.visibility_off_outlined,
                              label: 'Closures',
                              value: widget.trip.prolongedClosures.toString(),
                              color: AppColors.urgent,
                            ),
                            _QuickStat(
                              icon: Icons.add_alert_rounded,
                              label: 'Alerts',
                              value: widget.trip.drowsinessAlerts.toString(),
                              color: AppColors.urgent,
                            ),
                            _QuickStat(
                              icon: Icons.security_rounded,
                              label: 'Safety',
                              value:
                                  '${(widget.trip.alertnessScore * 100).toInt()}%',
                              color: AppColors.safe,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // View Full Analytics Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        TripDetailsScreen(trip: widget.trip),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      final curved = CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                        reverseCurve: Curves.easeInCubic,
                                      );
                                      return FadeTransition(
                                        opacity: curved,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.08, 0.03),
                                            end: Offset.zero,
                                          ).animate(curved),
                                          child: child,
                                        ),
                                      );
                                    },
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics_rounded, size: 18),
                          label: const Text(
                            'View Detailed Report',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
