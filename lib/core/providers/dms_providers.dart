import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_provider.dart';

// Driver Status
enum DMSStatus { safe, warning, drowsy }

class DriverStatusState {
  final DMSStatus status;
  final String eyes;
  final String mouth;
  final String neck;

  DriverStatusState({
    this.status = DMSStatus.safe,
    this.eyes = 'Eyes Open',
    this.mouth = 'Mouth Closed',
    this.neck = 'Neck Normal',
  });

  DriverStatusState copyWith({
    DMSStatus? status,
    String? eyes,
    String? mouth,
    String? neck,
  }) {
    return DriverStatusState(
      status: status ?? this.status,
      eyes: eyes ?? this.eyes,
      mouth: mouth ?? this.mouth,
      neck: neck ?? this.neck,
    );
  }
}

// Event Stats
class EventStatisticsState {
  final int eyeClosures;
  final int yawns;
  final int neckDroops;
  final int totalAlerts;

  EventStatisticsState({
    this.eyeClosures = 0,
    this.yawns = 0,
    this.neckDroops = 0,
    this.totalAlerts = 0,
  });

  EventStatisticsState copyWith({
    int? eyeClosures,
    int? yawns,
    int? neckDroops,
    int? totalAlerts,
  }) {
    return EventStatisticsState(
      eyeClosures: eyeClosures ?? this.eyeClosures,
      yawns: yawns ?? this.yawns,
      neckDroops: neckDroops ?? this.neckDroops,
      totalAlerts: totalAlerts ?? this.totalAlerts,
    );
  }
}

// Timeline Event
class TimelineEvent {
  final String time;
  final String title;
  final String description;
  final String type; // 'info', 'warning', 'danger', 'success'

  TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.type,
  });
}

// Providers definition
final safetyScoreProvider = StateProvider<int>((ref) => 100);
final driverStatusProvider = StateProvider<DriverStatusState>(
  (ref) => DriverStatusState(),
);
final fatigueLevelProvider = StateProvider<String>(
  (ref) => 'Low',
); // 'Low', 'Moderate', 'High', 'Critical'
final eventStatisticsProvider = StateProvider<EventStatisticsState>(
  (ref) => EventStatisticsState(),
);
final breakRecommendationProvider = StateProvider<String>(
  (ref) => 'Driver appears alert.',
);
final timelineEventsProvider =
    StateNotifierProvider<TimelineEventsNotifier, List<TimelineEvent>>((ref) {
      return TimelineEventsNotifier();
    });

class TimelineEventsNotifier extends StateNotifier<List<TimelineEvent>> {
  TimelineEventsNotifier() : super([]);

  void addEvent(TimelineEvent event) {
    state = [...state, event];
  }

  void reset() {
    state = [];
  }
}

final dmsSimulationProvider = Provider<DmsSimulationManager>((ref) {
  final manager = DmsSimulationManager(ref);
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

class DmsSimulationManager {
  DmsSimulationManager(this.ref) {
    _init();
  }

  final Ref ref;
  Timer? _timer;
  int _ticks = 0;

  void _init() {
    ref.listen<TripState>(tripProvider, (previous, next) {
      if (next.status == TripStatus.active) {
        _startSimulation();
      } else if (next.status == TripStatus.paused ||
          next.status == TripStatus.idle ||
          next.status == TripStatus.completed) {
        _stopSimulation();
      }
    });
  }

  void _startSimulation() {
    _timer?.cancel();
    _ticks = 0;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Clear and add start event
    ref.read(timelineEventsProvider.notifier).reset();
    ref
        .read(timelineEventsProvider.notifier)
        .addEvent(
          TimelineEvent(
            time: timeStr,
            title: 'Trip Started',
            description: 'DMS active monitoring systems online.',
            type: 'success',
          ),
        );

    ref.read(safetyScoreProvider.notifier).state = 100;
    ref.read(driverStatusProvider.notifier).state = DriverStatusState();
    ref.read(fatigueLevelProvider.notifier).state = 'Low';
    ref.read(eventStatisticsProvider.notifier).state = EventStatisticsState();
    ref.read(breakRecommendationProvider.notifier).state =
        'Driver appears alert.';

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final tripState = ref.read(tripProvider);
      if (tripState.status != TripStatus.active) return;

      _ticks++;

      final currentStats = ref.read(eventStatisticsProvider);
      int closures = currentStats.eyeClosures;
      int yawns = currentStats.yawns;
      int droops = currentStats.neckDroops;
      int alerts = currentStats.totalAlerts;

      DMSStatus status = DMSStatus.safe;
      String eyes = 'Eyes Open';
      String mouth = 'Mouth Closed';
      String neck = 'Neck Normal';
      String recommendation = 'Driver appears alert.';

      final simulationTime = DateTime.now();
      final simTimeStr =
          '${simulationTime.hour.toString().padLeft(2, '0')}:${simulationTime.minute.toString().padLeft(2, '0')}';

      if (_ticks % 3 == 0) {
        mouth = 'Yawn';
        yawns++;
        status = DMSStatus.warning;
        recommendation = 'Consider taking a break in 15 minutes.';
        ref
            .read(timelineEventsProvider.notifier)
            .addEvent(
              TimelineEvent(
                time: simTimeStr,
                title: 'Yawn Detected',
                description:
                    'Simulated drowsiness check triggered yawning alert.',
                type: 'warning',
              ),
            );
      } else if (_ticks % 5 == 0) {
        neck = 'Neck Droop';
        droops++;
        status = DMSStatus.warning;
        recommendation = 'Fatigue indicators increasing.';
        ref
            .read(timelineEventsProvider.notifier)
            .addEvent(
              TimelineEvent(
                time: simTimeStr,
                title: 'Neck Droop Warning',
                description: 'Slow neck movements detected.',
                type: 'warning',
              ),
            );
      } else if (_ticks % 7 == 0) {
        eyes = 'Eyes Closed';
        closures++;
        alerts++;
        status = DMSStatus.drowsy;
        recommendation = '⚠️ Drowsiness alert! Audio alert warning sounded.';
        ref
            .read(timelineEventsProvider.notifier)
            .addEvent(
              TimelineEvent(
                time: simTimeStr,
                title: 'Eye Closure Warning',
                description: 'Prolonged eye closure duration exceeded limits.',
                type: 'danger',
              ),
            );
      }

      final totalEvents = closures + yawns + droops;
      final score = (100 - (totalEvents * 4) - (alerts * 8)).clamp(0, 100);

      String fatigue = 'Low';
      if (score > 80) {
        fatigue = 'Low';
      } else if (score > 55) {
        fatigue = 'Moderate';
      } else if (score > 35) {
        fatigue = 'High';
      } else {
        fatigue = 'Critical';
      }

      ref.read(safetyScoreProvider.notifier).state = score;
      ref.read(driverStatusProvider.notifier).state = DriverStatusState(
        status: status,
        eyes: eyes,
        mouth: mouth,
        neck: neck,
      );
      ref.read(fatigueLevelProvider.notifier).state = fatigue;
      ref.read(eventStatisticsProvider.notifier).state = EventStatisticsState(
        eyeClosures: closures,
        yawns: yawns,
        neckDroops: droops,
        totalAlerts: alerts,
      );
      ref.read(breakRecommendationProvider.notifier).state = recommendation;
    });
  }

  void _stopSimulation() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}
