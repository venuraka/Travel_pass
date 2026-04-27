import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  /// The system instructions to guide the model's behavior.
  static const String _systemInstruction = '''
You are the Travel Pass Voice Assistant — a fast, hands-free AI built specifically for bus drivers in Sri Lanka using the Travel Pass app.

## LANGUAGE RULES
- Respond in the **SAME language** the driver uses.
- If the driver speaks English, reply in English.
- If the driver speaks Sinhala, reply in Sinhala.
- Keep replies extremely brief (1-2 short sentences) regardless of the language.

## YOUR PERSONALITY
- Extremely brief and direct. Drivers are on the road. Never say more than 1-2 short sentences.
- Speak naturally. Instead of "Executing function navigate_to", say "මගීන් විවෘත කරනවා" (Opening passengers).

## NAVIGATION RULES
When the user says any of these, call navigate_to with the correct screen name:
- "මගීන්", "passengers" → screen: "passengers"
- "ගෙවීම්", "payments" → screen: "payments"
- "ඩෑෂ්බෝඩ්", "dashboard" → screen: "dashboard"
- "යාවත්කාලීන කිරීම්", "updates" → screen: "updates"
- "පැමිණීම", "attendance" → screen: "attendance"
- "සැකසුම්", "settings" → screen: "settings"
- "ඡන්දය", "poll", "start poll" → call start_poll function
- "ගමන පටන් ගන්න", "start journey" → call start_journey function
- "ගමන නවත්වන්න", "end journey" → call end_journey function
''';

  GeminiService() {
    debugPrint('GeminiService initialized using Secure Cloud Functions');
  }

  /// Sends a spoken command to the backend Gemini Proxy and returns the response.
  /// This keeps the API Key securely on the server.
  Future<Map<String, dynamic>?> processCommand(String command, {List<Map<String, dynamic>>? history}) async {
    try {
      // If your functions are NOT in us-central1, change the region here:
      // Example: FirebaseFunctions.instanceFor(region: 'asia-southeast1').httpsCallable(...)
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'getGeminiResponse',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      
      final result = await callable.call({
        'prompt': command,
        'history': history,
        'systemInstruction': _systemInstruction,
      });

      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Function error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error calling Gemini Cloud Function: $e');
      return null;
    }
  }
}

/// Helper to parse Gemini response data
class GeminiResponse {
  final String text;
  final List<dynamic>? functionCalls;

  GeminiResponse({required this.text, this.functionCalls});

  factory GeminiResponse.fromMap(Map<String, dynamic> map) {
    final candidate = map['candidates']?[0];
    final content = candidate?['content'];
    final parts = content?['parts'] as List<dynamic>?;
    
    String text = "";
    List<dynamic> functionCalls = [];

    if (parts != null) {
      for (var part in parts) {
        if (part['text'] != null) text += part['text'];
        if (part['functionCall'] != null) functionCalls.add(part['functionCall']);
      }
    }

    return GeminiResponse(text: text, functionCalls: functionCalls);
  }
}
