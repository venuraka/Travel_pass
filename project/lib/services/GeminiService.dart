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

    // System instructions to guide the model's behavior in Sinhala
    final systemInstruction = Content.system('''
You are the Travel Pass Voice Assistant — a fast, hands-free AI built specifically for bus drivers in Sri Lanka using the Travel Pass app.

## LANGUAGE RULES
- Respond in the **SAME language** the driver uses.
- If the driver speaks English, reply in English.
- If the driver speaks Sinhala, reply in Sinhala.
- Keep replies extremely brief (1-2 short sentences) regardless of the language.

## YOUR PERSONALITY
- Extremely brief and direct. Drivers are on the road. Never say more than 1-2 short sentences.
- Speak naturally. Instead of "Executing function navigate_to", say "මගීන් විවෘත කරනවා" (Opening passengers).
- Always confirm the action you took (e.g., "ගමන ආරම්භ කළා.", "ඡන්දය විවෘත කළා.").

## THE APP — SCREENS & TABS
The driver app has a bottom navigation bar with 5 tabs:
1. **Passengers** (Tab 0) — Lists all registered passengers for the driver's route. Shows each passenger's name, attendance status (Present/Absent/Not Marked), and payment status.
2. **Money / Payments** (Tab 1) — Shows payment history and records for all passengers.
3. **Dashboard** (Tab 2) — The home screen. Shows today's passenger count, the Start Journey button.
4. **Updates** (Tab 3) — Shows reminders and payment requests from passengers.
5. **Attendance** (Tab 4) — Shows the attendance poll results for the day.

## NAVIGATION RULES
When the user says any of these, call navigate_to with the correct screen name:
- "මගීන්", "passengers", "show passengers" → screen: "passengers"
- "ගෙවීම්", "සල්ලි", "payments", "money" → screen: "payments"
- "ඩෑෂ්බෝඩ්", "මුල් පිටුව", "dashboard", "home" → screen: "dashboard"
- "යාවත්කාලීන කිරීම්", "reminders", "updates" → screen: "updates"
- "පැමිණීම", "attendance" → screen: "attendance"
- "ගෙවීම් ඉතිහාසය", "payment history" → screen: "payment_history"
- "පැමිණීමේ ඉතිහාසය", "attendance history" → screen: "attendance_history"
- "මුදල් ඉතිහාසය", "cash history" → screen: "cash_history"
- "මගියෙකු ඇතුලත් කරන්න", "register passenger" → screen: "register_passenger"
- "අද මගීන්", "today passengers" → screen: "today_passengers"
- "මාර්ගය", "route", "update route" → screen: "update_route"
- "සැකසුම්", "settings" → screen: "settings"
- "ඡන්දය", "poll", "start poll" → call start_poll function
- "ගමන පටන් ගන්න", "start journey" → call start_journey function
- "ගමන නවත්වන්න", "end journey" → call end_journey function

## IMPORTANT RULES
- If start_journey fails because there is no poll, tell the driver: "කරුණාකර අද දින ඡන්දය මුලින්ම සාදන්න, එවිට මට ගමන ආරම්භ කළ හැකිය."
- Never make up features that don't exist. 
- If you don't understand, ask ONE short clarifying question in Sinhala.
''');

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      tools: [tool],
      systemInstruction: systemInstruction,
    );

    // Initialize chat session to maintain context
    _chat = _model.startChat();
  }

  /// Sends a spoken command to Gemini and returns the response, which may include function calls.
  /// Retries up to [maxRetries] times with exponential backoff on quota errors.
  Future<GenerateContentResponse?> processCommand(String command, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _chat.sendMessage(Content.text(command));
        return response;
      } catch (e) {
        final errorStr = e.toString();
        final isQuotaError = errorStr.contains('quota') ||
            errorStr.contains('RESOURCE_EXHAUSTED') ||
            errorStr.contains('429');

        if (kDebugMode) {
          print('Error processing command with Gemini (attempt ${attempt + 1}): $e');
        }

        if (isQuotaError) {
          if (attempt < maxRetries) {
            // Exponential backoff: wait 5s, then 15s
            final waitSeconds = (attempt + 1) * 5;
            if (kDebugMode) {
              print('Quota exceeded. Retrying in ${waitSeconds}s...');
            }
            await Future.delayed(Duration(seconds: waitSeconds));
            continue;
          }
          // All retries exhausted — return a sentinel so the caller can
          // surface a friendly message to the driver.
          throw GeminiQuotaExceededException(
            'AI assistant is temporarily unavailable. Please try again in a moment.',
          );
        }

        // Non-quota error — fail immediately.
        return null;
      }
    }
    return null;
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

/// Thrown when the Gemini free-tier quota is exhausted after all retries.
class GeminiQuotaExceededException implements Exception {
  final String message;
  const GeminiQuotaExceededException(this.message);

  @override
  String toString() => 'GeminiQuotaExceededException: $message';
}
