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
    final params = <String, String>{
      'size': '640x960',
      'maptype': 'mapnik',
    };

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
