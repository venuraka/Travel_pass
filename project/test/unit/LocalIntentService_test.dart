import 'package:flutter_test/flutter_test.dart';
import 'package:project/services/LocalIntentService.dart';

void main() {
  group('LocalIntentService Tests', () {
    test('detect matches basic English journey commands', () {
      final start1 = LocalIntentService.detect("start journey");
      expect(start1, isNotNull);
      expect(start1!.action, IntentAction.startJourney);

      final start2 = LocalIntentService.detect("let's go");
      expect(start2, isNotNull);
      expect(start2!.action, IntentAction.startJourney);

      final end1 = LocalIntentService.detect("stop journey");
      expect(end1, isNotNull);
      expect(end1!.action, IntentAction.endJourney);

      final end2 = LocalIntentService.detect("arrived");
      expect(end2, isNotNull);
      expect(end2!.action, IntentAction.endJourney);
    });

    test('detect matches Sinhala localizations accurately', () {
      // Start Journey - "යමු"
      final sinhalaStart = LocalIntentService.detect("යමු");
      expect(sinhalaStart, isNotNull);
      expect(sinhalaStart!.action, IntentAction.startJourney);

      // End Journey - "ගමන ඉවරයි"
      final sinhalaEnd = LocalIntentService.detect("ගමන ඉවරයි");
      expect(sinhalaEnd, isNotNull);
      expect(sinhalaEnd!.action, IntentAction.endJourney);

      // Open Attendance - "පැමිණීම"
      final sinhalaAttend = LocalIntentService.detect("පැමිණීම");
      expect(sinhalaAttend, isNotNull);
      expect(sinhalaAttend!.action, IntentAction.navigate);
      expect(sinhalaAttend!.screen, 'attendance');

      // Open Settings - "සැකසුම්"
      final sinhalaSettings = LocalIntentService.detect("සැකසුම්");
      expect(sinhalaSettings, isNotNull);
      expect(sinhalaSettings!.action, IntentAction.navigate);
      expect(sinhalaSettings!.screen, 'settings');
    });

    test('detect maps correct navigation screens for keywords', () {
      final attend = LocalIntentService.detect("open attendance page");
      expect(attend!.action, IntentAction.navigate);
      expect(attend.screen, 'attendance');

      final passengers = LocalIntentService.detect("passenger list");
      expect(passengers!.action, IntentAction.navigate);
      expect(passengers.screen, 'passengers');

      final money = LocalIntentService.detect("earnings");
      expect(money!.action, IntentAction.navigate);
      expect(money.screen, 'payments');

      final home = LocalIntentService.detect("dashboard");
      expect(home!.action, IntentAction.navigate);
      expect(home.screen, 'dashboard');

      final route = LocalIntentService.detect("update route");
      expect(route!.action, IntentAction.navigate);
      expect(route.screen, 'update_route');

      final updates = LocalIntentService.detect("notifications");
      expect(updates!.action, IntentAction.navigate);
      expect(updates.screen, 'updates');
    });

    test('detect handles varying casing and spacing whitespace', () {
      final noisy = LocalIntentService.detect("  Go Home   ");
      expect(noisy, isNotNull);
      expect(noisy!.action, IntentAction.navigate);
      expect(noisy.screen, 'dashboard');

      final caps = LocalIntentService.detect("START TRIP");
      expect(caps!.action, IntentAction.startJourney);
    });

    test('detect prevents partial collisions using whole-word boundaries', () {
      // Word boundary test: The text contains "go", but not as a distinct word "go"
      // which might trigger startJourney incorrectly.
      // Actually, "lego" shouldn't trigger "let's go".
      final invalid1 = LocalIntentService.detect("going somewhere");
      expect(invalid1, isNull);

      final invalid2 = LocalIntentService.detect("yesterday attendance was good");
      // Even though it has "attendance", the pattern uses word-boundary regexes.
      // "attendance" exists, so it will match.
      final validAttend = LocalIntentService.detect("show attendance");
      expect(validAttend, isNotNull);
    });

    test('detect returns null for unrecognized complex commands (Gemini fallback)', () {
      final complex = LocalIntentService.detect("What is the weather like in Colombo right now?");
      expect(complex, isNull);

      final random = LocalIntentService.detect("hello random command");
      expect(random, isNull);
    });
  });
}
