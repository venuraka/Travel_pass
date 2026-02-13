import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceService {
  final String apiKey;

  PlaceService(this.apiKey);

  Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String query,
    String sessionToken,
  ) async {
    if (query.isEmpty) return [];

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': query,
          'key': apiKey,
          'sessiontoken': sessionToken,
          'components': 'country:lk',
        });

    print("PlaceService: Fetching suggestions for '$query'");
    final response = await http.get(uri);
    print("PlaceService: Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        print(
          "PlaceService: Found ${result['predictions'].length} suggestions",
        );
        return List<Map<String, dynamic>>.from(result['predictions']);
      }
      if (result['status'] == 'ZERO_RESULTS') {
        print("PlaceService: Zero results found");
        return [];
      }
      print("PlaceService: API Error: ${result['error_message']}");
      throw Exception(result['error_message']);
    } else {
      print("PlaceService: HTTP Error: ${response.body}");
      throw Exception('Failed to load suggestions');
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(
    String placeId,
    String sessionToken,
  ) async {
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'fields': 'geometry,formatted_address,name',
          'key': apiKey,
          'sessiontoken': sessionToken,
        });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final location = result['result']['geometry']['location'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
          'address': result['result']['formatted_address'],
          'name': result['result']['name'],
        };
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to load place details');
    }
  }

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
