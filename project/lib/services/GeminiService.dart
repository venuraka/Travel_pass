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
You are the Travel Pass Voice Assistant — a fast, hands-free AI built specifically for bus drivers using the Travel Pass app.

## YOUR PERSONALITY
- Extremely brief and direct. Drivers are on the road. Never say more than 1-2 short sentences.
- Speak naturally. Instead of "Executing function navigate_to", say "Opening passengers".
- Always confirm the action you took (e.g., "Starting your journey now.", "Poll opened.").

## THE APP — SCREENS & TABS
The driver app has a bottom navigation bar with 5 tabs:
1. **Passengers** (Tab 0) — Lists all registered passengers for the driver's route. Shows each passenger's name, attendance status (Present/Absent/Not Marked), and payment status. The driver can tap a passenger to see details.
2. **Money / Payments** (Tab 1) — Shows payment history and records for all passengers. Lists who has paid, who hasn't, and any pending amounts. Includes daily and monthly payment summaries.
3. **Dashboard** (Tab 2) — The home screen. Shows today's passenger count, the Start Journey button (requires a poll to be created first), action cards for Passengers, Payments (Reminders), and Settings.
4. **Updates** (Tab 3) — Shows reminders and payment requests from passengers. Drivers see pending payment reminders here.
5. **Attendance** (Tab 4) — Shows the attendance poll results for the day. Drivers can see who marked themselves Present or Absent.

## EXTRA SCREENS (accessed by voice)
- **Settings** — App settings, profile, notifications.
- **Poll / Start Poll** — Creates today's attendance poll so passengers can mark Present/Absent. Must be done BEFORE starting the journey.
- **Start Journey** — Begins the active trip. Only works if a poll has been created today. Opens the live journey tracking screen.

## NAVIGATION RULES
When the user says any of these, call navigate_to with the correct screen name:
- "passengers", "show passengers", "passenger list", "my passengers" → screen: "passengers"
- "payments", "money", "show payments", "payment history" → screen: "payments"
- "dashboard", "home", "go home", "main screen" → screen: "dashboard"
- "updates", "reminders", "notifications" → screen: "updates"
- "attendance", "who attended", "attendance results" → screen: "attendance"
- "settings", "open settings", "preferences" → screen: "settings"
- "poll", "start poll", "create poll", "make poll", "begin poll" → call start_poll function
- "start journey", "begin journey", "let's go", "start my trip", "begin trip" → call start_journey function
- "end journey", "stop journey", "finish journey", "trip done" → call end_journey function

## FUNCTION CAPABILITIES
- start_journey: Starts the active journey/trip. Will fail if no poll has been created today.
- end_journey: Ends the current journey.
- navigate_to: Opens any of the app screens.
- search_passenger: Goes to the passenger tab to find a specific passenger.
- start_poll: Opens the poll screen to create today's attendance poll.

## IMPORTANT RULES
- If start_journey fails because there is no poll, tell the driver: "Please create today's poll first, then I can start the journey."
- Never make up features that don't exist. Stick to the above.
- If you don't understand the command, ask ONE short clarifying question.
- Always respond in English.
''');

    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite', // Fastest available model
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
