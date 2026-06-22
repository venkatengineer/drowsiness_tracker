import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/open_maps_api.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';
import 'create_trip_screen.dart';

class StartDrivingScreen extends StatefulWidget {
  const StartDrivingScreen({super.key});

  @override
  State<StartDrivingScreen> createState() => _StartDrivingScreenState();
}

class _StartDrivingScreenState extends State<StartDrivingScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  PlaceResult? _startPlace;
  PlaceResult? _destination;
  bool _isInitializingCamera = false;
  bool _isStartingMonitoring = false;
  bool _isMonitoring = false;
  bool _showCameraPreview = false;
  String? _cameraError;
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

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed && _isMonitoring) {
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
    if (_isStartingMonitoring || _isMonitoring) return;
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

      setState(() {
        _startPlace = start;
        _destination = destination;
        _isMonitoring = true;
        _showCameraPreview = false;
      });
      _focusSelectedPlaces();
      await _initializeCamera();
    } on _LocationSetupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isStartingMonitoring = false);
    }
  }

  void _focusSelectedPlaces() {
    final start = _startPlace;
    final end = _destination;
    if (start == null || end == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = [
        LatLng(start.latitude, start.longitude),
        LatLng(end.latitude, end.longitude),
      ];
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(60, 190, 60, 260),
        ),
      );
    });
  }

  Widget _mapMarker({
    required Color color,
    required IconData icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
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
    await _cameraController?.dispose();
    if (!mounted) return;
    setState(() {
      _cameraController = null;
      _isMonitoring = false;
      _showCameraPreview = false;
      _cameraError = null;
      _startPlace = null;
      _destination = null;
    });
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
    if (_isMonitoring) {
      final startPoint = LatLng(_startPlace!.latitude, _startPlace!.longitude);
      final endPoint = LatLng(_destination!.latitude, _destination!.longitude);

      return Scaffold(
        body: Stack(
          children: [
            // Map
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: startPoint,
                  initialZoom: 10,
                  minZoom: 3,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.driver_assist',
                    maxZoom: 19,
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [startPoint, endPoint],
                        color: AppColors.info,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: startPoint,
                        width: 44,
                        height: 44,
                        child: _mapMarker(
                          color: AppColors.safe,
                          icon: Icons.trip_origin_rounded,
                        ),
                      ),
                      Marker(
                        point: endPoint,
                        width: 44,
                        height: 44,
                        child: _mapMarker(
                          color: AppColors.urgent,
                          icon: Icons.location_on_rounded,
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),

            // Top Floating Header: Navigation Card
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.safe.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: AppColors.safe,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Navigating to destination',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.color
                                          ?.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _destination!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
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

            // Picture-in-Picture (PIP) Camera Preview Panel OR Floating Preview Button
            if (_showCameraPreview)
              Positioned(
                bottom: 110,
                right: 16,
                child: SizedBox(
                  width: 150,
                  height: 200,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 20,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _CameraPreviewPanel(
                              controller: _cameraController,
                              isInitializing: _isInitializingCamera,
                              error: _cameraError,
                              onRetry: _initializeCamera,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: IconButton.filled(
                          iconSize: 16,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => setState(() => _showCameraPreview = false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                bottom: 110,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'preview_camera_fab',
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => setState(() => _showCameraPreview = true),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Preview Camera'),
                ),
              ),

            // Floating Bottom Stop Button
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 24,
                    child: GlassButton(
                      label: 'Stop Monitoring',
                      icon: Icons.stop_rounded,
                      color: AppColors.urgent,
                      onPressed: _stopMonitoring,
                    ),
                  ),
                ),
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
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.68),
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
                  if (_isMonitoring) ...[
                    const SizedBox(height: 18),
                    _ActiveTripCard(
                      start: _startPlace!,
                      destination: _destination!,
                    ),
                  ],
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
                            isMonitoring: _isMonitoring,
                            isCameraReady: _isCameraReady,
                            isInitializing: _isInitializingCamera,
                            error: _cameraError,
                            onRetry: _initializeCamera,
                          ),
                        if (_isMonitoring && _isCameraReady) ...[
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
                  if (!_isMonitoring)
                    GlassButton(
                      label: _isStartingMonitoring
                          ? 'Getting Current Location...'
                          : 'Start Monitoring',
                      icon: _isStartingMonitoring
                          ? Icons.sync_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.safe,
                      onPressed: _startMonitoring,
                    )
                  else
                    GlassButton(
                      label: 'Stop Monitoring',
                      icon: Icons.stop_rounded,
                      color: AppColors.urgent,
                      onPressed: _stopMonitoring,
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
    if (_isMonitoring && _isCameraReady) {
      return const _MonitoringStatus(
        label: 'Monitoring active',
        color: AppColors.safe,
        icon: Icons.check_circle_outline_rounded,
      );
    }
    return const _MonitoringStatus(
      label: 'Ready to start monitoring',
      color: AppColors.info,
      icon: Icons.shield_outlined,
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.start, required this.destination});

  final PlaceResult start;
  final PlaceResult destination;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Trip', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _TripLocationRow(
            icon: Icons.my_location_rounded,
            color: AppColors.safe,
            label: 'Current location',
            value: start.name,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: SizedBox(height: 16, child: VerticalDivider(width: 1)),
          ),
          _TripLocationRow(
            icon: Icons.location_on_rounded,
            color: AppColors.urgent,
            label: 'Destination',
            value: destination.name,
          ),
        ],
      ),
    );
  }
}

class _TripLocationRow extends StatelessWidget {
  const _TripLocationRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
                isCameraReady ? Icons.visibility_off_outlined : Icons.videocam_outlined,
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
        child: Center(
          child: CameraPreview(activeController),
        ),
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
