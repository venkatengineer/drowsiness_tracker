import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/dms_providers.dart';
import '../glass_card.dart';

class TimelineCard extends StatelessWidget {
  const TimelineCard({required this.events, super.key});

  final List<TimelineEvent> events;

  Color _getEventColor(String type) {
    return switch (type) {
      'success' => AppColors.safe,
      'warning' => AppColors.warning,
      'danger' => AppColors.urgent,
      _ => AppColors.info,
    };
  }

  IconData _getEventIcon(String type) {
    return switch (type) {
      'success' => Icons.check_circle_rounded,
      'warning' => Icons.warning_amber_rounded,
      'danger' => Icons.error_rounded,
      _ => Icons.info_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reversedEvents = events.reversed.toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.info,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Safety Event Log',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (reversedEvents.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No events recorded yet.',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reversedEvents.length.clamp(
                0,
                5,
              ), // Show last 5 events
              itemBuilder: (context, index) {
                final event = reversedEvents[index];
                final color = _getEventColor(event.type);
                final icon = _getEventIcon(event.type);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline indicator line & icon
                      Column(
                        children: [
                          Icon(icon, color: color, size: 16),
                          if (index < (reversedEvents.length.clamp(0, 5) - 1))
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: Colors.white10,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Content details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    event.time,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.description,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
