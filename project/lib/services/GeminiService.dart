import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/AppConfig.dart';

class GeminiService {
  // Use the API key from AppConfig if available, or a placeholder
  static const String _apiKey = 'AIzaSyBlEayKYD_BN3S3QoIsr3lVdnmmph5cITk';
  
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // Define the function declarations (Tools) for Gemini
  final _startJourneyTool = FunctionDeclaration(
    'start_journey',
    'Starts the driver\'s current trip or journey.',
    Schema.object(
      properties: {
        'confirm': Schema.boolean(description: 'Confirmation to start', nullable: true),
      },
    ),
  );

  final _endJourneyTool = FunctionDeclaration(
    'end_journey',
    'Ends the current trip or journey.',
    Schema.object(
      properties: {
        'confirm': Schema.boolean(description: 'Confirmation to end', nullable: true),
      },
    ),
  );

  final _navigateToTool = FunctionDeclaration(
    'navigate_to',
    'Navigates the app to a specific screen.',
    Schema.object(
      properties: {
        'screen': Schema.string(
            description: 'The screen to navigate to. Allowed values: passengers, payments, settings, dashboard, start_journey, poll',
            nullable: false),
      },
      requiredProperties: ['screen'],
    ),
  );

  final _searchPassengerTool = FunctionDeclaration(
    'search_passenger',
    'Searches for a specific passenger by their name to view their details or payment status.',
    Schema.object(
      properties: {
        'name': Schema.string(
            description: 'The name of the passenger to search for',
            nullable: false),
      },
      requiredProperties: ['name'],
    ),
  );

  final _markAttendanceTool = FunctionDeclaration(
    'start_poll',
    'Starts the attendance poll for the day.',
    Schema.object(
       properties: {
        'confirm': Schema.boolean(description: 'Confirmation to start poll', nullable: true),
      },
    ),
  );

  GeminiService() {
    _initializeModel();
  }

  void _initializeModel() {
    // Define the tools for the model
    final tool = Tool(functionDeclarations: [
      _startJourneyTool,
      _endJourneyTool,
      _navigateToTool,
      _searchPassengerTool,
      _markAttendanceTool,
    ]);

    // System instructions to guide the model's behavior
    final systemInstruction = Content.system('''
      You are the intelligent Voice Assistant for the Travel Pass driver application. 
      Your goal is to help the driver operate the app hands-free using natural language.
      Map the driver's spoken intent to the provided functions.
      If a command is unclear, ask for clarification.
      If the command is perfectly mapped to a function, call it.
      Keep your text responses very brief and conversational (e.g., "Starting journey", "Opening settings"), as they will be read aloud by Text-to-Speech while the driver is driving.
    ''');

    _model = GenerativeModel(
      model: 'gemini-flash-latest', // Use the stable alias
      apiKey: _apiKey,
      tools: [tool],
      systemInstruction: systemInstruction,
    );

    // Initialize chat session to maintain context
    _chat = _model.startChat();
  }

  /// Sends a spoken command to Gemini and returns the response, which may include function calls.
  Future<GenerateContentResponse?> processCommand(String command) async {
    try {
      final response = await _chat.sendMessage(Content.text(command));
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing command with Gemini: $e');
      }
      return null;
    }
  }

  /// Sends the result of a function execution back to Gemini.
  Future<GenerateContentResponse?> sendFunctionResponse(String functionName, Map<String, Object?> response) async {
    try {
      final res = await _chat.sendMessage(Content.functionResponse(functionName, response));
      return res;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending function response to Gemini: $e');
      }
      return null;
    }
  }
}
