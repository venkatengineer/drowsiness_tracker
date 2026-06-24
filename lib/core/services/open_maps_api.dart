import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class OpenMapsApi {
  OpenMapsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PlaceResult?> geocode(String query) async {
    final results = await search(query, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  Future<List<PlaceResult>> search(String query, {int limit = 5}) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '$limit',
      'addressdetails': '0',
    });

    late http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'driver_assist_flutter_app',
          'Accept': 'application/json',
        },
      );
    } catch (_) {
      throw const OpenMapsApiException('Unable to reach OpenStreetMap.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenMapsApiException(
        'OpenStreetMap search failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return const [];
    }

    return decoded.whereType<Map<String, dynamic>>().map((place) {
      return PlaceResult(
        name: place['display_name'] as String? ?? query,
        latitude: double.parse(place['lat'].toString()),
        longitude: double.parse(place['lon'].toString()),
      );
    }).toList();
  }

  Future<PlaceResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'jsonv2',
      'zoom': '18',
    });

    late http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } catch (_) {
      throw const OpenMapsApiException('Unable to reach OpenStreetMap.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenMapsApiException(
        'OpenStreetMap lookup failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OpenMapsApiException('No address was found at this point.');
    }

    return PlaceResult(
      name: decoded['display_name'] as String? ?? 'Selected location',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<PlaceResult>> fetchRoutePoints({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final uri = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/'
      '$startLongitude,$startLatitude;$endLongitude,$endLatitude'
      '?geometries=polyline',
    );

    late http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } catch (_) {
      throw const OpenMapsApiException('Unable to reach OSRM routing server.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenMapsApiException(
        'OSRM routing failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OpenMapsApiException('Invalid response from routing server.');
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const OpenMapsApiException('No route found between coordinates.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as String?;
    if (geometry == null) {
      throw const OpenMapsApiException('No geometry found in route.');
    }

    return _decodePolyline(geometry);
  }

  List<PlaceResult> _decodePolyline(String encoded) {
    final List<PlaceResult> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(
        PlaceResult(
          name: 'Route coordinate',
          latitude: lat / 1E5,
          longitude: lng / 1E5,
        ),
      );
    }
    return points;
  }

  void close() => _client.close();

  static const _headers = {
    'User-Agent': 'driver_assist_flutter_app',
    'Accept': 'application/json',
  };

  String staticMapUrl({
    required PlaceResult? start,
    required PlaceResult? end,
    required String fallbackQuery,
  }) {
    final params = <String, String>{'size': '640x960', 'maptype': 'mapnik'};

    if (start != null && end != null) {
      final centerLat = (start.latitude + end.latitude) / 2;
      final centerLon = (start.longitude + end.longitude) / 2;
      params['center'] = '$centerLat,$centerLon';
      params['zoom'] = '10';
      params['markers'] =
          '${start.latitude},${start.longitude},green-pushpin|${end.latitude},${end.longitude},red-pushpin';
    } else if (start != null || end != null) {
      final place = start ?? end!;
      params['center'] = '${place.latitude},${place.longitude}';
      params['zoom'] = '13';
      params['markers'] = '${place.latitude},${place.longitude},red-pushpin';
    } else if (fallbackQuery.isNotEmpty) {
      params['center'] = fallbackQuery;
      params['zoom'] = '11';
    } else {
      params['center'] = '21.1466,79.0889';
      params['zoom'] = '4';
    }

    return Uri.https(
      'staticmap.openstreetmap.de',
      '/staticmap.php',
      params,
    ).toString();
  }
}

class OpenMapsApiException implements Exception {
  const OpenMapsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
