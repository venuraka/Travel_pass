import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/services/PlaceService.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late PlaceService service;

  setUpAll(() {
    // Register standard fallback for Mocktail matching Uri parameters
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = PlaceService('test-api-key-123', client: mockClient);
  });

  group('PlaceService Tests', () {
    const tSessionToken = 'token-xyz-456';

    test('getPlaceSuggestions returns parsed maps upon successful 200 response', () async {
      const mockResponseJson = {
        "suggestions": [
          {
            "placePrediction": {
              "placeId": "ChIJQ6qVl8",
              "text": {"text": "Colombo Fort Railway Station, Colombo, Sri Lanka"}
            }
          }
        ]
      };

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockResponseJson), 200));

      final results = await service.getPlaceSuggestions('Colombo', tSessionToken);

      expect(results.length, 1);
      expect(results.first['place_id'], 'ChIJQ6qVl8');
      expect(results.first['description'], contains('Colombo Fort'));
    });

    test('getPlaceSuggestions returns empty list if query is empty', () async {
      final results = await service.getPlaceSuggestions('', tSessionToken);
      expect(results, isEmpty);
      verifyNever(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('getPlaceDetails parses lat, lng and displayName correctly', () async {
      const mockDetailsJson = {
        "location": {
          "latitude": 6.9344,
          "longitude": 79.85
        },
        "formattedAddress": "Colombo Fort, Sri Lanka",
        "displayName": {
          "text": "Fort Station"
        }
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockDetailsJson), 200));

      final details = await service.getPlaceDetails('ChIJQ6qVl8', tSessionToken);

      expect(details['lat'], 6.9344);
      expect(details['lng'], 79.85);
      expect(details['address'], 'Colombo Fort, Sri Lanka');
      expect(details['name'], 'Fort Station');
    });

    test('getAddressFromLatLng extracts formatted_address from legacy geocoding response', () async {
      const mockGeocodeJson = {
        "status": "OK",
        "results": [
          {
            "formatted_address": "123 Galle Road, Colombo 03, Sri Lanka"
          }
        ]
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockGeocodeJson), 200));

      final address = await service.getAddressFromLatLng(const LatLng(6.9, 79.8));

      expect(address, '123 Galle Road, Colombo 03, Sri Lanka');
    });

    test('getAddressFromLatLng returns "Unknown Location" if geocoding fails', () async {
      const mockGeocodeJson = {
        "status": "ZERO_RESULTS",
        "results": []
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(mockGeocodeJson), 200));

      final address = await service.getAddressFromLatLng(const LatLng(6.9, 79.8));

      expect(address, 'Unknown Location');
    });
  });
}
