import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceService {
  final String apiKey;

  PlaceService(this.apiKey);

  /// Fetches place suggestions using the new Places API (New)
  /// Endpoint: https://places.googleapis.com/v1/places:autocomplete
  Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String query,
    String sessionToken,
  ) async {
    if (query.isEmpty) return [];

    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey},
      body: jsonEncode({
        'input': query,
        'sessionToken': sessionToken,
        'includedRegionCodes': ['lk'], // Restrict to Sri Lanka
      }),
    );

    debugPrint("PlaceService: Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['suggestions'] != null) {
        final suggestions = List<Map<String, dynamic>>.from(
          result['suggestions'].map((s) {
            final prediction = s['placePrediction'];
            return {
              'place_id': prediction['placeId'], // New API uses 'placeId'
              'description': prediction['text']['text'], // New API structure
            };
          }),
        );
        debugPrint("PlaceService: Found ${suggestions.length} suggestions");
        return suggestions;
      }
      debugPrint("PlaceService: Zero results found or empty suggestions");
      return [];
    } else {
      debugPrint("PlaceService: HTTP Error: ${response.body}");
      throw Exception('Failed to load suggestions: ${response.body}');
    }
  }

  /// Fetches place details using the new Places API (New)
  /// Endpoint: https://places.googleapis.com/v1/places/{placeId}
  Future<Map<String, dynamic>> getPlaceDetails(
    String placeId,
    String sessionToken,
  ) async {
    final uri = Uri.https('places.googleapis.com', '/v1/places/$placeId', {
      'fields': 'location,formattedAddress,displayName',
      'sessionToken': sessionToken,
    });

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        // Using FieldMask header is also an option, but query param 'fields' works
        'X-Goog-FieldMask': 'location,formattedAddress,displayName',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      // New API Response Structure
      // { "formattedAddress": "...", "location": { "latitude": ..., "longitude": ... }, "displayName": { "text": "..." } }

      if (result['location'] != null) {
        return {
          'lat': result['location']['latitude'],
          'lng': result['location']['longitude'],
          'address': result['formattedAddress'] ?? "Unknown Address",
          'name': result['displayName']?['text'] ?? "Unknown Place",
        };
      }
      throw Exception('Location data missing in response');
    } else {
      debugPrint("PlaceService: Details Error: ${response.body}");
      throw Exception('Failed to load place details: ${response.body}');
    }
  }

  /// Reverse Geocoding - Uses the Geocoding API (Legacy/Stand-alone, usually enabled separately)
  /// Endpoint: https://maps.googleapis.com/maps/api/geocode/json
  /// Note: The "New" Places API does not replace Geocoding API yet.
  Future<String> getAddressFromLatLng(LatLng position) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${position.latitude},${position.longitude}',
      'key': apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        if (result['results'].isNotEmpty) {
          return result['results'][0]['formatted_address'];
        }
      }
    }
    return "Unknown Location";
  }

  /// Fetches directions between origin and destination with optional waypoints.
  /// Uses the Directions API.
  Future<List<LatLng>> getDirections(
    LatLng origin,
    LatLng destination,
    List<LatLng> waypoints,
  ) async {
    // Construct waypoints string
    String waypointsString = '';
    if (waypoints.isNotEmpty) {
      final List<String> waypointList = waypoints
          .map((point) => '${point.latitude},${point.longitude}')
          .toList();
      // optimize:true reorders waypoints to minimize time/distance
      waypointsString = 'optimize:true|${waypointList.join('|')}';
    }

    final queryParameters = {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': apiKey,
    };

    if (waypointsString.isNotEmpty) {
      queryParameters['waypoints'] = waypointsString;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      queryParameters,
    );

    debugPrint("PlaceService: Fetching directions...");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // Decode polyline
        final points = result['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(points);
      }
      debugPrint("PlaceService: Directions Error: ${result['error_message']}");
      throw Exception(result['error_message']);
    } else {
      debugPrint("PlaceService: HTTP Error: ${response.body}");
      throw Exception('Failed to load directions');
    }
  }

  /// Decodes a Google Maps encoded polyline string into a list of LatLng.
  /// Simple variable-length integer decoding.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return polyline;
  }
}
