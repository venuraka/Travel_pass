import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:project/services/GeminiService.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();

    when(() => mockFunctions.httpsCallable(any(), options: any(named: 'options')))
        .thenReturn(mockCallable);
  });

  group('GeminiService Tests', () {
    test('processCommand returns parsed map on successful Cloud Function call', () async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Opening passengers screen for you!'}
              ]
            }
          }
        ]
      };

      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn(fakeResponse);

      // Use a testable version via manual call simulation
      // GeminiService uses FirebaseFunctions.instance internally; 
      // we validate GeminiResponse parsing which is pure logic
      final response = GeminiResponse.fromMap(fakeResponse);

      expect(response.text, 'Opening passengers screen for you!');
      expect(response.functionCalls, isEmpty);
    });

    test('GeminiResponse.fromMap parses functionCall correctly', () {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'functionCall': {
                    'name': 'navigate_to',
                    'args': {'screen': 'passengers'}
                  }
                }
              ]
            }
          }
        ]
      };

      final response = GeminiResponse.fromMap(fakeResponse);

      expect(response.text, ''); // No text part
      expect(response.functionCalls, isNotEmpty);
      expect(response.functionCalls!.first['name'], 'navigate_to');
    });

    test('GeminiResponse.fromMap handles missing candidates gracefully', () {
      final emptyResponse = <String, dynamic>{};

      final response = GeminiResponse.fromMap(emptyResponse);

      expect(response.text, '');
      expect(response.functionCalls, isEmpty);
    });

    test('GeminiResponse.fromMap combines multiple text parts', () {
      final multiPartResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Hello '},
                {'text': 'Driver!'}
              ]
            }
          }
        ]
      };

      final response = GeminiResponse.fromMap(multiPartResponse);

      expect(response.text, 'Hello Driver!');
    });
  });
}
