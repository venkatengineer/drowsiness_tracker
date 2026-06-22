import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/open_maps_api.dart';
import '../../core/services/trip_api.dart';
import '../../widgets/glass_card.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({
    super.key,
    this.initialStartPlace,
    this.lockStartLocation = false,
  });

  final PlaceResult? initialStartPlace;
  final bool lockStartLocation;

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  static const _initialCenter = LatLng(20.5937, 78.9629);

  final _mapController = MapController();
  final _tripApi = TripApi();
  final _mapsApi = OpenMapsApi();

  PlaceResult? _startPlace;
  PlaceResult? _endPlace;
  bool _selectingStart = true;
  bool _isResolvingPoint = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startPlace = widget.initialStartPlace;
    _selectingStart = !widget.lockStartLocation;
    if (_startPlace != null) _focusSelectedPlaces();
  }

  @override
  void dispose() {
    _mapsApi.close();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openPlaceSearch({required bool forStart}) async {
    if (forStart && widget.lockStartLocation) return;
    setState(() => _selectingStart = forStart);
    final place = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PlaceSearchSheet(
        mapsApi: _mapsApi,
        title: forStart ? 'Choose starting point' : 'Choose destination',
      ),
    );

    if (place == null || !mounted) return;
    _setPlace(place, forStart: forStart);
  }

  void _setPlace(PlaceResult place, {required bool forStart}) {
    setState(() {
      if (forStart) {
        _startPlace = place;
        _selectingStart = _endPlace != null;
      } else {
        _endPlace = place;
        _selectingStart = _startPlace == null;
      }
    });
    _focusSelectedPlaces();
  }

  void _swapPlaces() {
    if (widget.lockStartLocation) return;
    if (_startPlace == null && _endPlace == null) return;
    setState(() {
      final oldStart = _startPlace;
      _startPlace = _endPlace;
      _endPlace = oldStart;
    });
    _focusSelectedPlaces();
  }

  Future<void> _selectPointOnMap(TapPosition _, LatLng point) async {
    if (_isResolvingPoint) return;
    setState(() => _isResolvingPoint = true);

    try {
      final place = await _mapsApi.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      _setPlace(
        place,
        forStart: widget.lockStartLocation ? false : _selectingStart,
      );
    } on OpenMapsApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isResolvingPoint = false);
    }
  }

  void _focusSelectedPlaces() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = [
        if (_startPlace case final place?)
          LatLng(place.latitude, place.longitude),
        if (_endPlace case final place?) LatLng(place.latitude, place.longitude),
      ];
      if (points.isEmpty) return;
      if (points.length == 1) {
        _mapController.move(points.first, 14);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(60, 190, 60, 230),
          ),
        );
      }
    });
  }

  Future<void> _saveTrip() async {
    final start = _startPlace;
    final end = _endPlace;
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both a starting point and destination.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _tripApi.createTrip(
        startDestination: start.name,
        endDestination: end.name,
        startLatitude: start.latitude,
        startLongitude: start.longitude,
        endLatitude: end.latitude,
        endLongitude: end.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully.')),
      );
      Navigator.of(context).pop(end);
    } on TripApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startPoint = _startPlace == null
        ? null
        : LatLng(_startPlace!.latitude, _startPlace!.longitude);
    final endPoint = _endPlace == null
        ? null
        : LatLng(_endPlace!.latitude, _endPlace!.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lockStartLocation ? 'Choose Destination' : 'Create Trip',
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 4.8,
                minZoom: 3,
                maxZoom: 19,
                onTap: _selectPointOnMap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.driver_assist',
                  maxZoom: 19,
                ),
                if (startPoint != null && endPoint != null)
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
                    if (startPoint != null)
                      _mapMarker(
                        point: startPoint,
                        color: AppColors.safe,
                        icon: Icons.trip_origin_rounded,
                      ),
                    if (endPoint != null)
                      _mapMarker(
                        point: endPoint,
                        color: AppColors.urgent,
                        icon: Icons.location_on_rounded,
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
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _LocationCard(
                  startPlace: _startPlace,
                  endPlace: _endPlace,
                  selectingStart: _selectingStart,
                  lockStartLocation: widget.lockStartLocation,
                  onStartTap: () => _openPlaceSearch(forStart: true),
                  onEndTap: () => _openPlaceSearch(forStart: false),
                  onSwap: _swapPlaces,
                  onSelectStart: () {
                    if (!widget.lockStartLocation) {
                      setState(() => _selectingStart = true);
                    }
                  },
                  onSelectEnd: () => setState(() => _selectingStart = false),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _BottomActionCard(
                  isSaving: _isSaving,
                  hasRoute: _startPlace != null && _endPlace != null,
                  actionLabel: widget.lockStartLocation
                      ? 'Start Monitoring'
                      : 'Create Trip',
                  onSave: _saveTrip,
                ),
              ),
            ),
          ),
          if (_isResolvingPoint)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Marker _mapMarker({
    required LatLng point,
    required Color color,
    required IconData icon,
  }) {
    return Marker(
      point: point,
      width: 52,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.startPlace,
    required this.endPlace,
    required this.selectingStart,
    required this.lockStartLocation,
    required this.onStartTap,
    required this.onEndTap,
    required this.onSwap,
    required this.onSelectStart,
    required this.onSelectEnd,
  });

  final PlaceResult? startPlace;
  final PlaceResult? endPlace;
  final bool selectingStart;
  final bool lockStartLocation;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final VoidCallback onSwap;
  final VoidCallback onSelectStart;
  final VoidCallback onSelectEnd;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 24,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.78 : 0.88,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _LocationField(
                  label: 'From',
                  value: startPlace?.name,
                  color: AppColors.safe,
                  selected: selectingStart,
                  locked: lockStartLocation,
                  onTap: onStartTap,
                  onMapSelectionTap: onSelectStart,
                ),
                const SizedBox(height: 10),
                _LocationField(
                  label: 'To',
                  value: endPlace?.name,
                  color: AppColors.urgent,
                  selected: !selectingStart,
                  locked: false,
                  onTap: onEndTap,
                  onMapSelectionTap: onSelectEnd,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Swap locations',
            onPressed: lockStartLocation ? null : onSwap,
            icon: Icon(
              lockStartLocation ? Icons.my_location_rounded : Icons.swap_vert_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.locked,
    required this.onTap,
    required this.onMapSelectionTap,
  });

  final String label;
  final String? value;
  final Color color;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onMapSelectionTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? color : Theme.of(context).colorScheme.outlineVariant;
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onMapSelectionTap,
                child: Icon(
                  label == 'From' ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      value ?? 'Search or tap the map',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: value == null
                            ? Theme.of(context).hintColor
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(locked ? Icons.lock_rounded : Icons.search_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionCard extends StatelessWidget {
  const _BottomActionCard({
    required this.isSaving,
    required this.hasRoute,
    required this.actionLabel,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasRoute;
  final String actionLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 24,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.8 : 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasRoute
                      ? 'Route ready. Review the pins and create your trip.'
                      : 'Choose a field, then search or tap anywhere on the map.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.route_rounded),
            label: Text(isSaving ? 'Saving trip...' : actionLabel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.mapsApi, required this.title});

  final OpenMapsApi mapsApi;
  final String title;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PlaceResult> _results = const [];
  bool _isSearching = false;
  String? _message;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = const [];
        _message = 'Enter at least 3 characters.';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 650), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _message = null;
    });
    try {
      final results = await widget.mapsApi.search(query.trim());
      if (!mounted || query != _controller.text) return;
      setState(() {
        _results = results;
        _message = results.isEmpty ? 'No matching locations found.' : null;
      });
    } on OpenMapsApiException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                if (value.trim().length >= 3) _search(value);
              },
              decoration: InputDecoration(
                hintText: 'Search city, area, or address',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    leading: const CircleAvatar(
                      child: Icon(Icons.location_on_outlined),
                    ),
                    title: Text(
                      result.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.north_west_rounded, size: 18),
                    onTap: () => Navigator.of(context).pop(result),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
