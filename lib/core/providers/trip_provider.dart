import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../services/open_maps_api.dart';

enum TripStatus { idle, calibrating, active, paused, completed }

class TripState {
  final PlaceResult? startPlace;
  final PlaceResult? destination;
  final int durationSeconds;
  final int breakDurationSeconds;
  final TripStatus status;
  final List<Map<String, dynamic>> breaks;
  final List<LatLng> routePoints;
  final bool isLoadingRoute;

  TripState({
    this.startPlace,
    this.destination,
    this.durationSeconds = 0,
    this.breakDurationSeconds = 0,
    this.status = TripStatus.idle,
    this.breaks = const [],
    this.routePoints = const [],
    this.isLoadingRoute = false,
  });

  TripState copyWith({
    PlaceResult? startPlace,
    PlaceResult? destination,
    int? durationSeconds,
    int? breakDurationSeconds,
    TripStatus? status,
    List<Map<String, dynamic>>? breaks,
    List<LatLng>? routePoints,
    bool? isLoadingRoute,
  }) {
    return TripState(
      startPlace: startPlace ?? this.startPlace,
      destination: destination ?? this.destination,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      breakDurationSeconds: breakDurationSeconds ?? this.breakDurationSeconds,
      status: status ?? this.status,
      breaks: breaks ?? this.breaks,
      routePoints: routePoints ?? this.routePoints,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  TripNotifier() : super(TripState());

  Timer? _tripTimer;
  Timer? _breakTimer;
  DateTime? _breakStartTime;

  void enterCalibration(PlaceResult start, PlaceResult destination) {
    state = TripState(
      startPlace: start,
      destination: destination,
      status: TripStatus.calibrating,
      isLoadingRoute: true,
    );
  }

  void startTrip() {
    state = state.copyWith(status: TripStatus.active);
    _startTimers();
  }

  void setLoadingRoute(bool loading) {
    state = state.copyWith(isLoadingRoute: loading);
  }

  void setRoutePoints(List<LatLng> points) {
    state = state.copyWith(routePoints: points, isLoadingRoute: false);
  }

  void _startTimers() {
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TripStatus.active) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      }
    });
  }

  void pauseTrip() {
    if (state.status != TripStatus.active) return;
    _breakStartTime = DateTime.now();
    state = state.copyWith(status: TripStatus.paused);

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TripStatus.paused) {
        state = state.copyWith(
          breakDurationSeconds: state.breakDurationSeconds + 1,
        );
      }
    });
  }

  void resumeTrip() {
    if (state.status != TripStatus.paused) return;
    _breakTimer?.cancel();

    final endTime = DateTime.now();
    final currentBreakDuration = state.breakDurationSeconds;

    final newBreaks = List<Map<String, dynamic>>.from(state.breaks)
      ..add({
        'start': _breakStartTime,
        'end': endTime,
        'duration': currentBreakDuration,
      });

    state = state.copyWith(status: TripStatus.active, breaks: newBreaks);
  }

  void stopTrip() {
    _tripTimer?.cancel();
    _breakTimer?.cancel();
    state = state.copyWith(status: TripStatus.completed);
  }

  void reset() {
    _tripTimer?.cancel();
    _breakTimer?.cancel();
    state = TripState();
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    _breakTimer?.cancel();
    super.dispose();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});
