import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:project/controllers/VoiceAssistantController.dart';
import 'package:project/services/GeminiService.dart';
import 'package:project/controllers/DriverDashboardController.dart';

class MockSpeechToText extends Mock implements stt.SpeechToText {}
class MockFlutterTts extends Mock implements FlutterTts {}
class MockGeminiService extends Mock implements GeminiService {}
class MockDriverDashboardController extends Mock implements DriverDashboardController {}

void main() {
  late MockSpeechToText mockSpeech;
  late MockFlutterTts mockTts;
  late MockGeminiService mockGemini;
  late MockDriverDashboardController mockDashboard;
  late VoiceAssistantController controller;

  String? navigatedScreen;
  bool startJourneyCalled = false;

  setUp(() {
    mockSpeech = MockSpeechToText();
    mockTts = MockFlutterTts();
    mockGemini = MockGeminiService();
    mockDashboard = MockDriverDashboardController();
    
    when(() => mockTts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setVolume(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setPitch(any())).thenAnswer((_) async => 1);
    when(() => mockTts.speak(any())).thenAnswer((_) async => 1);
    when(() => mockTts.stop()).thenAnswer((_) async => 1);

    navigatedScreen = null;
    startJourneyCalled = false;

    controller = VoiceAssistantController(
      speech: mockSpeech,
      tts: mockTts,
      geminiService: mockGemini,
      dashboardController: mockDashboard,
      onNavigate: (screen) => navigatedScreen = screen,
      onStartJourney: () => startJourneyCalled = true,
    );
  });

  group('VoiceAssistantController Tests', () {
    test('speak method detects English text and uses en-US', () async {
      await controller.speak('Hello world');
      verify(() => mockTts.setLanguage('en-US')).called(1);
      verify(() => mockTts.speak('Hello world')).called(1);
    });

    test('speak method detects Sinhala text and uses si-LK', () async {
      await controller.speak('ආයුබෝවන්');
      verify(() => mockTts.setLanguage('si-LK')).called(2); // 1 from initTts, 1 from speak
      verify(() => mockTts.speak('ආයුබෝවන්')).called(1);
    });

    test('clearResponse resets internal state', () {
      controller.clearResponse();
      expect(controller.recognizedText, '');
      expect(controller.aiResponse, '');
      expect(controller.isProcessing, false);
    });
  });
}
