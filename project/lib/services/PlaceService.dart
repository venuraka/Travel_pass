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
}
