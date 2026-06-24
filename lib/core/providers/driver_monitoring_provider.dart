import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_provider.dart';

enum EyesStatus { open, closed }

enum MouthStatus { open, closed }

enum NeckStatus { normal, droop }

enum DriverAlertStatus { safe, warning, drowsy }

enum FatigueLevel { safe, warning, critical }

class DriverMonitoringState {
  final EyesStatus eyes;
  final MouthStatus mouth;
  final NeckStatus neck;
  final DriverAlertStatus alertStatus;
  final int safetyScore;
  final FatigueLevel fatigueLevel;
  final int eyeClosureEvents;
  final int yawnEvents;
  final int neckDroopEvents;
  final int totalAlerts;

  DriverMonitoringState({
    this.eyes = EyesStatus.open,
    this.mouth = MouthStatus.closed,
    this.neck = NeckStatus.normal,
    this.alertStatus = DriverAlertStatus.safe,
    this.safetyScore = 100,
    this.fatigueLevel = FatigueLevel.safe,
    this.eyeClosureEvents = 0,
    this.yawnEvents = 0,
    this.neckDroopEvents = 0,
    this.totalAlerts = 0,
  });

  DriverMonitoringState copyWith({
    EyesStatus? eyes,
    MouthStatus? mouth,
    NeckStatus? neck,
    DriverAlertStatus? alertStatus,
    int? safetyScore,
    FatigueLevel? fatigueLevel,
    int? eyeClosureEvents,
    int? yawnEvents,
    int? neckDroopEvents,
    int? totalAlerts,
  }) {
    return DriverMonitoringState(
      eyes: eyes ?? this.eyes,
      mouth: mouth ?? this.mouth,
      neck: neck ?? this.neck,
      alertStatus: alertStatus ?? this.alertStatus,
      safetyScore: safetyScore ?? this.safetyScore,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      eyeClosureEvents: eyeClosureEvents ?? this.eyeClosureEvents,
      yawnEvents: yawnEvents ?? this.yawnEvents,
      neckDroopEvents: neckDroopEvents ?? this.neckDroopEvents,
      totalAlerts: totalAlerts ?? this.totalAlerts,
    );
  }
}

class DriverMonitoringNotifier extends StateNotifier<DriverMonitoringState> {
  DriverMonitoringNotifier(this.ref) : super(DriverMonitoringState()) {
    _startSimulatedDetections();
  }

  final Ref ref;
  Timer? _simulationTimer;
  int _counter = 0;

  void _startSimulatedDetections() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final tripState = ref.read(tripProvider);
      if (tripState.status != TripStatus.active) return;

      _counter++;
      EyesStatus eyes = EyesStatus.open;
      MouthStatus mouth = MouthStatus.closed;
      NeckStatus neck = NeckStatus.normal;
      DriverAlertStatus alertStatus = DriverAlertStatus.safe;

      int eyeClosures = state.eyeClosureEvents;
      int yawns = state.yawnEvents;
      int neckDroops = state.neckDroopEvents;
      int alerts = state.totalAlerts;

      // Cycle through different simulated events
      if (_counter % 3 == 0) {
        mouth = MouthStatus.open;
        yawns++;
        alertStatus = DriverAlertStatus.warning;
      } else if (_counter % 5 == 0) {
        neck = NeckStatus.droop;
        neckDroops++;
        alertStatus = DriverAlertStatus.warning;
      } else if (_counter % 7 == 0) {
        eyes = EyesStatus.closed;
        eyeClosures++;
        alerts++;
        alertStatus = DriverAlertStatus.drowsy;
      }

      final totalEvents = eyeClosures + yawns + neckDroops;
      final safetyScore = (100 - (totalEvents * 4) - (alerts * 8)).clamp(
        0,
        100,
      );

      FatigueLevel fatigue;
      if (safetyScore > 80) {
        fatigue = FatigueLevel.safe;
      } else if (safetyScore > 50) {
        fatigue = FatigueLevel.warning;
      } else {
        fatigue = FatigueLevel.critical;
      }

      state = state.copyWith(
        eyes: eyes,
        mouth: mouth,
        neck: neck,
        alertStatus: alertStatus,
        safetyScore: safetyScore,
        fatigueLevel: fatigue,
        eyeClosureEvents: eyeClosures,
        yawnEvents: yawns,
        neckDroopEvents: neckDroops,
        totalAlerts: alerts,
      );
    });
  }

  void reset() {
    state = DriverMonitoringState();
    _counter = 0;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}

final driverMonitoringProvider =
    StateNotifierProvider<DriverMonitoringNotifier, DriverMonitoringState>((
      ref,
    ) {
      return DriverMonitoringNotifier(ref);
    });
