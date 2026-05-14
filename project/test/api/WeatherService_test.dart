import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project/services/WeatherService.dart';

// 1. Define mock classes using Mocktail
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  group('WeatherService API Integration Mock Tests', () {
    late MockFirebaseFunctions mockFunctions;
    late MockHttpsCallable mockCallable;
    late MockHttpsCallableResult mockResult;
    late WeatherService weatherService;

    setUp(() {
      mockFunctions = MockFirebaseFunctions();
      mockCallable = MockHttpsCallable();
      mockResult = MockHttpsCallableResult();
      weatherService = WeatherService(functions: mockFunctions);
    });

    test('API recommendation: returns "Bring an Umbrella" when backend returns Rain', () async {
      // 1. Arrange: Mock the Firebase Function call chain
      when(() => mockFunctions.httpsCallable('getWeatherData')).thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);
      
      // Stub the backend returning a mocked API response format
      when(() => mockResult.data).thenReturn({
        'weather': [{'main': 'Rain'}],
        'main': {'temp': 22.5}
      });

      // 2. Act: Call our app API service
      final recommendation = await weatherService.getWeatherRecommendation(6.9271, 79.8612);

      // 3. Assert: Verify the frontend logic correctly parsed the backend API response
      expect(recommendation['type'], 'rain');
      expect(recommendation['title'], contains('Bring an Umbrella'));
    });

    test('API recommendation: returns "Stay Hydrated" when backend returns hot temperature', () async {
      when(() => mockFunctions.httpsCallable('getWeatherData')).thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);
      
      // Stub backend returning clear weather but scorching 32°C heat
      when(() => mockResult.data).thenReturn({
        'weather': [{'main': 'Clouds'}],
        'main': {'temp': 32.0}
      });

      final recommendation = await weatherService.getWeatherRecommendation(6.9271, 79.8612);

      expect(recommendation['type'], 'hot');
      expect(recommendation['title'], contains('Stay Hydrated'));
    });
  });
}
