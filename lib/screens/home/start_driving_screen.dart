import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/dms_providers.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/services/open_maps_api.dart';
import '../../widgets/dms/camera_calibration_view.dart';
import '../../widgets/dms/safety_score_card.dart';
import '../../widgets/dms/driver_status_card.dart';
import '../../widgets/dms/fatigue_gauge.dart';
import '../../widgets/dms/ai_safety_assistant_card.dart';
import '../../widgets/dms/trip_info_card.dart';
import '../../widgets/dms/event_statistics_card.dart';
import '../../widgets/dms/timeline_card.dart';
import '../../widgets/dms/break_recommendation_card.dart';
import '../../widgets/dms/trip_control_panel.dart';
import '../../widgets/dms/trip_summary_view.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';
import 'create_trip_screen.dart';

class StartDrivingScreen extends ConsumerStatefulWidget {
  const StartDrivingScreen({super.key});

  @override
  ConsumerState<StartDrivingScreen> createState() => _StartDrivingScreenState();
}

class _StartDrivingScreenState extends ConsumerState<StartDrivingScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializingCamera = false;
  bool _isStartingMonitoring = false;
  bool _showCameraPreview = true;
  String? _cameraError;
  bool _isMapReady = false;

  // Flutter Map Controller
  final _mapController = MapController();

  bool get _isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final tripState = ref.read(tripProvider);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed &&
        (tripState.status == TripStatus.active ||
            tripState.status == TripStatus.calibrating)) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startMonitoring() async {
    if (_isStartingMonitoring) return;
    setState(() => _isStartingMonitoring = true);

    try {
      final start = await _getCurrentPlace();
      if (!mounted) return;

      final destination = await Navigator.of(context).push<PlaceResult>(
        MaterialPageRoute(
          builder: (_) => CreateTripScreen(
            initialStartPlace: start,
            lockStartLocation: true,
          ),
        ),
      );
      if (destination == null || !mounted) return;

      ref.read(tripProvider.notifier).enterCalibration(start, destination);

      // Trigger route retrieval asynchronously
      _fetchRoute(start, destination);

      await _initializeCamera();
    } on _LocationSetupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isStartingMonitoring = false);
    }
  }

  Future<void> _fetchRoute(PlaceResult start, PlaceResult end) async {
    final mapsApi = OpenMapsApi();
    try {
      final routePlaceResults = await mapsApi.fetchRoutePoints(
        startLatitude: start.latitude,
        startLongitude: start.longitude,
        endLatitude: end.latitude,
        endLongitude: end.longitude,
      );

      if (!mounted) return;

      final points = routePlaceResults
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      ref.read(tripProvider.notifier).setRoutePoints(points);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusSelectedPlaces(start, end, points);
        }
      });
    } catch (e) {
      debugPrint('OSRM routing error: $e');
      if (!mounted) return;
      final fallbackPoints = [
        LatLng(start.latitude, start.longitude),
        LatLng(end.latitude, end.longitude),
      ];
      ref.read(tripProvider.notifier).setRoutePoints(fallbackPoints);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusSelectedPlaces(start, end, fallbackPoints);
        }
      });
    } finally {
      mapsApi.close();
    }
  }

  void _focusSelectedPlaces(
    PlaceResult start,
    PlaceResult end,
    List<LatLng> points,
  ) {
    if (points.isEmpty) return;
    if (!_isMapReady) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _mapMarker({required Color color, required IconData icon}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }

  Future<PlaceResult> _getCurrentPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _LocationSetupException(
        'Turn on location services to start monitoring.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const _LocationSetupException(
        'Location permission is required to set the trip starting point.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const _LocationSetupException(
        'Location permission is blocked. Enable it in device settings.',
      );
    }

    late Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const _LocationSetupException(
        'Unable to determine your current location. Try again outdoors.',
      );
    }

    final mapsApi = OpenMapsApi();
    try {
      return await mapsApi.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on OpenMapsApiException {
      return PlaceResult(
        name: 'Current location',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } finally {
      mapsApi.close();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) return;
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraError = 'No camera was found on this device.');
        }
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController?.dispose();
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
    } on CameraException catch (error) {
      await controller?.dispose();
      if (mounted) setState(() => _cameraError = _cameraMessageFor(error));
    } catch (_) {
      await controller?.dispose();
      if (mounted) setState(() => _cameraError = 'Unable to start the camera.');
    } finally {
      if (mounted) setState(() => _isInitializingCamera = false);
    }
  }

  Future<void> _stopMonitoring() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.stop_circle_outlined,
                      color: AppColors.urgent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'End Trip',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to end this trip monitoring session?\n\nThis will generate a final analytics summary.',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.urgent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('End Trip'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    ref.read(tripProvider.notifier).stopTrip();
  }

  void _finishStopMonitoring() async {
    await _cameraController?.dispose();
    if (!mounted) return;
    setState(() {
      _cameraController = null;
      _isMapReady = false;
      _showCameraPreview = false;
    });
    ref.read(tripProvider.notifier).reset();
    ref.read(safetyScoreProvider.notifier).state = 100;
    ref.read(driverStatusProvider.notifier).state = DriverStatusState();
    ref.read(fatigueLevelProvider.notifier).state = 'Low';
    ref.read(eventStatisticsProvider.notifier).state = EventStatisticsState();
    ref.read(breakRecommendationProvider.notifier).state =
        'Driver appears alert.';
    ref.read(timelineEventsProvider.notifier).reset();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _cameraMessageFor(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        'Camera permission is required to monitor drowsiness.',
      _ => error.description ?? 'Unable to start the camera.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    ref.watch(
      dmsSimulationProvider,
    ); // Auto-starts / stops simulation based on status!

    // Camera Calibration Screen
    if (tripState.status == TripStatus.calibrating) {
      return CameraCalibrationView(
        cameraController: _cameraController,
        isInitializing: _isInitializingCamera,
        error: _cameraError,
        onRetryCamera: _initializeCamera,
        onStartTrip: () {
          setState(() {
            _showCameraPreview = false;
          });
          ref.read(tripProvider.notifier).startTrip();
        },
      );
    }

    // Trip Summary Screen
    if (tripState.status == TripStatus.completed) {
      final safetyScore = ref.watch(safetyScoreProvider);
      final driverStatus = ref.watch(driverStatusProvider);
      final eventStats = ref.watch(eventStatisticsProvider);

      return TripSummaryView(
        startPlace: tripState.startPlace?.name ?? 'Current Location',
        destination: tripState.destination?.name ?? 'Destination',
        durationSeconds: tripState.durationSeconds,
        breakDurationSeconds: tripState.breakDurationSeconds,
        safetyScore: safetyScore,
        alertCount: eventStats.totalAlerts,
        eyeClosureCount: eventStats.eyeClosures,
        yawnCount: eventStats.yawns,
        neckDropCount: eventStats.neckDroops,
        driverStatusText:
            '${driverStatus.eyes} | ${driverStatus.mouth} | ${driverStatus.neck}',
        onDone: _finishStopMonitoring,
      );
    }

    if (tripState.status == TripStatus.active ||
        tripState.status == TripStatus.paused) {
      final startPoint = tripState.startPlace != null
          ? LatLng(
              tripState.startPlace!.latitude,
              tripState.startPlace!.longitude,
            )
          : const LatLng(0, 0);
      final endPoint = tripState.destination != null
          ? LatLng(
              tripState.destination!.latitude,
              tripState.destination!.longitude,
            )
          : const LatLng(0, 0);

      // Watch DMS States
      final safetyScore = ref.watch(safetyScoreProvider);
      final driverStatus = ref.watch(driverStatusProvider);
      final fatigueLevel = ref.watch(fatigueLevelProvider);
      final eventStats = ref.watch(eventStatisticsProvider);
      final recommendation = ref.watch(breakRecommendationProvider);
      final timelineEvents = ref.watch(timelineEventsProvider);

      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 1. TOP STATUS SECTION (Compact Card)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.safe.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.safe,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: AppColors.safe,
                                  size: 8,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TRIP ACTIVE',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.safe,
                                        letterSpacing: 1.0,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white60,
                                        fontSize: 10,
                                      ),
                                ),
                                Text(
                                  tripState.destination?.name ?? 'Coimbatore',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right Info: Time & Duration
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDuration(tripState.durationSeconds),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const Text(
                                'Elapsed',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white70,
                            ),
                            tooltip: 'Trip Menu',
                            onSelected: (value) {
                              if (value == 'preview_camera') {
                                setState(() {
                                  _showCameraPreview = !_showCameraPreview;
                                });
                              } else if (value == 'end_trip') {
                                _stopMonitoring();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'preview_camera',
                                child: Row(
                                  children: [
                                    Icon(
                                      _showCameraPreview
                                          ? Icons.videocam_off_outlined
                                          : Icons.videocam_outlined,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _showCameraPreview
                                          ? 'Hide Camera'
                                          : 'Preview Camera',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'end_trip',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.stop_circle_outlined,
                                      color: AppColors.urgent,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text('End Trip'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. SCROLLABLE ADAS MONITORING DASHBOARD CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Side-by-side: Safety Score & Fatigue Gauge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SafetyScoreCard(score: safetyScore),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FatigueGauge(level: fatigueLevel),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Driver Status (Eyes, Mouth, Neck alignment checks)
                          DriverStatusCard(
                            status: driverStatus.status,
                            eyes: driverStatus.eyes,
                            mouth: driverStatus.mouth,
                            neck: driverStatus.neck,
                          ),
                          const SizedBox(height: 14),

                          // AI Safety Assistant Card
                          AISafetyAssistantCard(recommendation: recommendation),
                          const SizedBox(height: 14),

                          // Trip Information Card
                          TripInfoCard(
                            destination:
                                tripState.destination?.name ?? 'Destination',
                            durationSeconds: tripState.durationSeconds,
                          ),
                          const SizedBox(height: 14),

                          // Event Statistics Card
                          EventStatisticsCard(
                            eyeClosures: eventStats.eyeClosures,
                            yawns: eventStats.yawns,
                            neckDroops: eventStats.neckDroops,
                            alerts: eventStats.totalAlerts,
                          ),
                          const SizedBox(height: 14),

                          // Break Recommendation Card
                          BreakRecommendationCard(
                            driveTimeSeconds: tripState.durationSeconds,
                            riskLevel: fatigueLevel,
                          ),
                          const SizedBox(height: 14),

                          // Chronological Event Timeline Log
                          TimelineCard(events: timelineEvents),
                          const SizedBox(height: 14),

                          // 20-25% Height Contextual Mini Map
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                height: 170,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: startPoint,
                                          initialZoom: 10,
                                          minZoom: 3,
                                          maxZoom: 19,
                                          onMapReady: () {
                                            setState(() {
                                              _isMapReady = true;
                                            });
                                            if (tripState
                                                    .routePoints
                                                    .isNotEmpty &&
                                                tripState.startPlace != null &&
                                                tripState.destination != null) {
                                              _focusSelectedPlaces(
                                                tripState.startPlace!,
                                                tripState.destination!,
                                                tripState.routePoints,
                                              );
                                            }
                                          },
                                          interactionOptions:
                                              const InteractionOptions(
                                                flags:
                                                    InteractiveFlag.all &
                                                    ~InteractiveFlag.rotate,
                                              ),
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.example.driver_assist',
                                            maxZoom: 19,
                                            tileBuilder:
                                                (context, tileWidget, tile) {
                                                  return ColorFiltered(
                                                    colorFilter:
                                                        const ColorFilter.matrix(
                                                          [
                                                            -0.2126,
                                                            -0.7152,
                                                            -0.0722,
                                                            0,
                                                            255, // Red
                                                            -0.2126,
                                                            -0.7152,
                                                            -0.0722,
                                                            0,
                                                            255, // Green
                                                            -0.2126,
                                                            -0.7152,
                                                            -0.0722,
                                                            0,
                                                            255, // Blue
                                                            0,
                                                            0,
                                                            0,
                                                            1,
                                                            0, // Alpha
                                                          ],
                                                        ),
                                                    child: tileWidget,
                                                  );
                                                },
                                          ),
                                          if (tripState.routePoints.isNotEmpty)
                                            PolylineLayer(
                                              polylines: [
                                                Polyline(
                                                  points: tripState.routePoints,
                                                  color: AppColors.info,
                                                  strokeWidth: 4,
                                                ),
                                              ],
                                            ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: startPoint,
                                                width: 24,
                                                height: 24,
                                                child: _mapMarker(
                                                  color: AppColors.safe,
                                                  icon:
                                                      Icons.trip_origin_rounded,
                                                ),
                                              ),
                                              Marker(
                                                point: endPoint,
                                                width: 24,
                                                height: 24,
                                                child: _mapMarker(
                                                  color: AppColors.urgent,
                                                  icon:
                                                      Icons.location_on_rounded,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Mini map content HUD
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        right: 10,
                                        child: GlassCard(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          borderRadius: 12,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.navigation,
                                                    size: 14,
                                                    color: AppColors.info,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Remaining: 34 km',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'ETA: 10:45 AM',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.white70,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. FIXED BOTTOM ACTION BAR
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TripControlPanel(onEndTrip: _stopMonitoring),
            ),

            // 4. FLOATING CAMERA PREVIEW OVERLAY
            if (_showCameraPreview && _isCameraReady)
              Positioned(
                bottom: 120,
                right: 16,
                child: _FloatingCameraPreview(
                  controller: _cameraController!,
                  onClose: () {
                    setState(() {
                      _showCameraPreview = false;
                    });
                  },
                ),
              ),
          ],
        ),
      );
    }

    final status = _monitoringStatus;

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
                    'Start Driving',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set your destination and monitor driver alertness.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(status.icon, color: status.color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            status.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: status.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Driver Monitoring',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (_isCameraReady)
                              _LiveBadge(visible: _showCameraPreview),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_showCameraPreview)
                          AspectRatio(
                            aspectRatio: 3 / 4,
                            child: _CameraPreviewPanel(
                              controller: _cameraController,
                              isInitializing: _isInitializingCamera,
                              error: _cameraError,
                              onRetry: _initializeCamera,
                            ),
                          )
                        else
                          _HiddenCameraPanel(
                            isMonitoring: false,
                            isCameraReady: _isCameraReady,
                            isInitializing: _isInitializingCamera,
                            error: _cameraError,
                            onRetry: _initializeCamera,
                          ),
                        if (_isCameraReady) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => setState(
                              () => _showCameraPreview = !_showCameraPreview,
                            ),
                            icon: Icon(
                              _showCameraPreview
                                  ? Icons.videocam_off_outlined
                                  : Icons.preview_rounded,
                            ),
                            label: Text(
                              _showCameraPreview
                                  ? 'Hide Camera Preview'
                                  : 'Preview Camera',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassButton(
                    label: _isStartingMonitoring
                        ? 'Getting Current Location...'
                        : 'Start Monitoring',
                    icon: _isStartingMonitoring
                        ? Icons.sync_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.safe,
                    onPressed: _startMonitoring,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _MonitoringStatus get _monitoringStatus {
    if (_isStartingMonitoring) {
      return const _MonitoringStatus(
        label: 'Getting your current location',
        color: AppColors.info,
        icon: Icons.my_location_rounded,
      );
    }
    if (_isInitializingCamera) {
      return const _MonitoringStatus(
        label: 'Starting camera monitoring',
        color: AppColors.info,
        icon: Icons.sync_rounded,
      );
    }
    if (_cameraError != null) {
      return const _MonitoringStatus(
        label: 'Camera permission required',
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    }
    return const _MonitoringStatus(
      label: 'Ready to start monitoring',
      color: AppColors.info,
      icon: Icons.shield_outlined,
    );
  }
}

class _HiddenCameraPanel extends StatelessWidget {
  const _HiddenCameraPanel({
    required this.isMonitoring,
    required this.isCameraReady,
    required this.isInitializing,
    required this.error,
    required this.onRetry,
  });

  final bool isMonitoring;
  final bool isCameraReady;
  final bool isInitializing;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = isCameraReady
        ? 'Camera is active. The preview is hidden.'
        : isInitializing
        ? 'Initializing the front camera...'
        : error ?? 'Start monitoring to activate the camera.';
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCameraReady
                    ? Icons.visibility_off_outlined
                    : Icons.videocam_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              if (isMonitoring && error != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Try Again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraPreviewPanel extends StatelessWidget {
  const _CameraPreviewPanel({
    required this.controller,
    required this.isInitializing,
    required this.error,
    required this.onRetry,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    final isReady =
        activeController != null && activeController.value.isInitialized;
    if (!isReady) {
      return _HiddenCameraPanel(
        isMonitoring: true,
        isCameraReady: false,
        isInitializing: isInitializing,
        error: error,
        onRetry: onRetry,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.black,
        child: Center(child: CameraPreview(activeController)),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.safe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        visible ? 'PREVIEW' : 'ACTIVE',
        style: const TextStyle(
          color: AppColors.safe,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MonitoringStatus {
  const _MonitoringStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _LocationSetupException implements Exception {
  const _LocationSetupException(this.message);

  final String message;
}

class _FloatingCameraPreview extends StatelessWidget {
  const _FloatingCameraPreview({
    required this.controller,
    required this.onClose,
  });

  final CameraController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 147, // 3:4 aspect ratio
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(controller)),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.safe.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 6),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
