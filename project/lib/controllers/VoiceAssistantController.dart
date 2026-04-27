import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/GeminiService.dart';
import '../services/LocalIntentService.dart';
import 'DriverDashboardController.dart';

class VoiceAssistantController extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GeminiService _geminiService = GeminiService();
  final DriverDashboardController _dashboardController =
      DriverDashboardController();

  bool _isListening = false;
  String _recognizedText = '';
  String _aiResponse = '';
  bool _isProcessing = false;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  String get aiResponse => _aiResponse;
  bool get isProcessing => _isProcessing;
  bool get isSinhalaInput => RegExp(r'[\u0D80-\u0DFF]').hasMatch(_recognizedText);

  // Callbacks for UI actions
  final Function(String screenName)? onNavigate;
  final VoidCallback? onStartJourney;

  VoiceAssistantController({this.onNavigate, this.onStartJourney}) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("si-LK"); // Set TTS to Sinhala
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    // Detect if text contains Sinhala characters
    bool isSinhala = RegExp(r'[\u0D80-\u0DFF]').hasMatch(text);
    await _tts.setLanguage(isSinhala ? "si-LK" : "en-US");
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> startListening() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _aiResponse = "Microphone permission is required.";
      notifyListeners();
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
          if (_recognizedText.isNotEmpty && !_isProcessing) {
            _processVoiceCommand(_recognizedText);
          }
        }
      },
      onError: (errorNotification) {
        _isListening = false;
        // Check the error message for specific types
        if (errorNotification.errorMsg.contains('error_no_match')) {
          _aiResponse = "I didn't hear anything. Please try again.";
        } else if (errorNotification.errorMsg.contains(
          'error_speech_timeout',
        )) {
          _aiResponse =
              "Listening timed out. Please tap the mic and try again.";
        } else {
          _aiResponse = "Listening error: ${errorNotification.errorMsg}";
        }
        notifyListeners();
      },
    );

    if (available) {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = 'Listening...';
      notifyListeners();

      await _speech.listen(
        localeId: "si-LK", // Listen for Sinhala speech
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          notifyListeners();
        },
      );
    } else {
      _isListening = false;
      _aiResponse = "Speech recognition not available.";
      notifyListeners();
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Clears the current voice assistant display
  void clearResponse() {
    _recognizedText = '';
    _aiResponse = '';
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> _processVoiceCommand(String command) async {
    _isProcessing = true;
    _aiResponse = 'Processing...';
    notifyListeners();

    // Step 1: Try to handle locally first — instant, no API needed
    final localIntent = LocalIntentService.detect(command);
    if (localIntent != null) {
      await _executeLocalIntent(localIntent);
      _isProcessing = false;
      notifyListeners();
      return;
    }

    // Step 2: Escalate to Gemini for complex/ambiguous commands
    _aiResponse = 'Thinking...';
    notifyListeners();

    GenerateContentResponse? response;
    try {
      response = await _geminiService.processCommand(command);
    } catch (e) {
      // Bilingual fallback
      bool isSinhalaInput = RegExp(r'[\u0D80-\u0DFF]').hasMatch(command);
      _aiResponse = isSinhalaInput 
          ? "සම්බන්ධ වීමට අපහසුයි. කරුණාකර නැවත උත්සාහ කරන්න."
          : "I'm having trouble connecting. Please try again.";
      await speak(_aiResponse);
      _isProcessing = false;
      notifyListeners();
      return;
    }

    if (response == null) {
      bool isSinhalaInput = RegExp(r'[\u0D80-\u0DFF]').hasMatch(command);
      _aiResponse = isSinhalaInput
          ? "මට එය තේරුණේ නැත. කරුණාකර නැවත උත්සාහ කරන්න."
          : "I didn't quite catch that. Try saying it differently.";
      await speak(_aiResponse);
      _isProcessing = false;
      notifyListeners();
      return;
    }

    await _handleGeminiResponse(response);
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> _executeLocalIntent(LocalIntent intent) async {
    switch (intent.action) {
      case IntentAction.startJourney:
        bool hasPoll = await _dashboardController.hasActivePollToday();
        if (!hasPoll) {
          _aiResponse =
              'Please create today\'s poll first, then I can start the journey.';
          await speak(_aiResponse);
          return;
        }
        if (onStartJourney != null) onStartJourney!();
        _aiResponse = 'Starting your journey now!';
        await speak(_aiResponse);
        break;

      case IntentAction.endJourney:
        await _dashboardController.endJourney();
        _aiResponse = 'Journey ended. Great work today!';
        await speak(_aiResponse);
        break;

      case IntentAction.navigate:
        if (intent.screen != null && onNavigate != null) {
          onNavigate!(intent.screen!);
          final screenNames = {
            'passengers': isSinhalaInput ? 'මගීන්' : 'passengers',
            'payments': isSinhalaInput ? 'ගෙවීම්' : 'payments',
            'dashboard': isSinhalaInput ? 'මුල් පිටුව' : 'home',
            'updates': isSinhalaInput ? 'යාවත්කාලීන කිරීම්' : 'updates',
            'attendance': isSinhalaInput ? 'පැමිණීම' : 'attendance',
            'settings': isSinhalaInput ? 'සැකසුම්' : 'settings',
            'poll': isSinhalaInput ? 'ඡන්දය' : 'poll',
            'attendance_history': isSinhalaInput ? 'පැමිණීමේ ඉතිහාසය' : 'attendance history',
            'payment_history': isSinhalaInput ? 'ගෙවීම් ඉතිහාසය' : 'payment history',
            'cash_history': isSinhalaInput ? 'මුදල් ඉතිහාසය' : 'cash history',
            'register_passenger': isSinhalaInput ? 'මගීන් ඇතුලත් කිරීම' : 'passenger registration',
            'today_passengers': isSinhalaInput ? 'අද මගීන්' : 'today\'s passengers',
            'update_route': isSinhalaInput ? 'මාර්ගය වෙනස් කිරීම' : 'route updates',
          };
          _aiResponse = isSinhalaInput
              ? '${screenNames[intent.screen] ?? intent.screen} විවෘත කරනවා.'
              : 'Opening ${screenNames[intent.screen] ?? intent.screen}.';
          await speak(_aiResponse);
        }
        break;

      case IntentAction.startPoll:
        if (onNavigate != null) onNavigate!('poll');
        _aiResponse = 'Opening the poll screen.';
        await speak(_aiResponse);
        break;
    }
  }

  Future<void> _handleGeminiResponse(GenerateContentResponse response) async {
    // Check if Gemini wants to call any functions
    if (response.functionCalls.isNotEmpty) {
      for (final functionCall in response.functionCalls) {
        final result = await _executeFunctionCall(functionCall);

        // Send the result back to Gemini so it knows the action was taken
        // and can provide a final conversational response
        final nextResponse = await _geminiService.sendFunctionResponse(
          functionCall.name,
          result,
        );

        if (nextResponse != null) {
          await _handleGeminiResponse(
            nextResponse,
          ); // Recursively handle if it has more to say/do
        }
      }
    } else if (response.text != null && response.text!.isNotEmpty) {
      // If it's just a text response, speak it and display it
      _aiResponse = response.text!;
      await speak(_aiResponse);
    }
  }

  Future<Map<String, Object?>> _executeFunctionCall(
    FunctionCall functionCall,
  ) async {
    try {
      switch (functionCall.name) {
        case 'start_journey':
          bool hasPoll = await _dashboardController.hasActivePollToday();
          if (!hasPoll) {
            return {
              'status': 'failed',
              'reason': 'No active poll today. Driver must start a poll first.',
            };
          }
          if (onStartJourney != null) {
            onStartJourney!();
          }
          return {'status': 'success', 'message': 'Journey started.'};

        case 'end_journey':
          await _dashboardController.endJourney();
          return {'status': 'success', 'message': 'Journey ended.'};

        case 'navigate_to':
          final screen = functionCall.args['screen'] as String?;
          if (screen != null && onNavigate != null) {
            onNavigate!(screen);
            return {'status': 'success', 'message': "Navigated to $screen."};
          }
          return {
            'status': 'failed',
            'reason': 'Missing screen argument or navigator not provided.',
          };

        case 'search_passenger':
          final name = functionCall.args['name'] as String?;
          if (name != null) {
            // For now, we'll just navigate to the passenger list and let Gemini say it's filtering
            if (onNavigate != null) {
              onNavigate!('passengers');
            }
            return {
              'status': 'success',
              'message': 'Navigated to passenger screen to search for $name.',
            };
          }
          return {'status': 'failed', 'reason': 'Missing name argument.'};

        case 'start_poll':
          if (onNavigate != null) {
            onNavigate!('poll');
          }
          return {'status': 'success', 'message': 'Opened poll screen.'};

        default:
          return {'status': 'failed', 'reason': 'Unknown function name.'};
      }
    } catch (e) {
      return {'status': 'failed', 'reason': 'Error executing function: $e'};
    }
  }
}
