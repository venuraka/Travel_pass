/// Local, zero-API-cost intent detection for common voice commands.
/// Handles 95% of driver commands instantly without any network call.
class LocalIntentService {
  /// Returns a [LocalIntent] if the command is recognized locally, or null if
  /// it should be escalated to Gemini for complex understanding.
  static LocalIntent? detect(String command) {
    final text = command.toLowerCase().trim();

    // --- START JOURNEY ---
    if (_matches(text, [
      'start journey', 'begin journey', 'start trip', 'begin trip',
      "let's go", 'lets go', 'start my journey', 'start my trip',
      'start the journey', 'begin the trip', 'go', 'start driving',
    ])) {
      return LocalIntent(action: IntentAction.startJourney);
    }

    // --- END JOURNEY ---
    if (_matches(text, [
      'end journey', 'stop journey', 'finish journey', 'end trip',
      'stop trip', 'finish trip', 'trip done', 'journey done',
      'end my journey', 'stop my trip', 'arrived', 'we arrived',
    ])) {
      return LocalIntent(action: IntentAction.endJourney);
    }

    // --- START POLL ---
    if (_matches(text, [
      'start poll', 'create poll', 'make poll', 'begin poll',
      'open poll', 'poll', 'new poll', 'start attendance',
      'create attendance poll', 'make attendance',
    ])) {
      return LocalIntent(action: IntentAction.startPoll);
    }

    // --- NAVIGATE: PASSENGERS ---
    if (_matches(text, [
      'passengers', 'show passengers', 'open passengers',
      'passenger list', 'my passengers', 'show my passengers',
      'go to passengers', 'passenger screen', 'open passenger list',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'passengers');
    }

    // --- NAVIGATE: PAYMENTS / MONEY ---
    if (_matches(text, [
      'payments', 'money', 'show payments', 'payment history',
      'open payments', 'go to payments', 'payment screen',
      'show money', 'financials', 'revenue', 'earnings',
      'payment details', 'open money',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'payments');
    }

    // --- NAVIGATE: DASHBOARD / HOME ---
    if (_matches(text, [
      'dashboard', 'home', 'go home', 'main screen', 'go to dashboard',
      'open dashboard', 'home screen', 'main page', 'go to home',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'dashboard');
    }

    // --- NAVIGATE: UPDATES / REMINDERS ---
    if (_matches(text, [
      'updates', 'reminders', 'notifications', 'open updates',
      'show updates', 'show reminders', 'pending reminders',
      'payment reminders', 'go to updates',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'updates');
    }

    // --- NAVIGATE: ATTENDANCE ---
    if (_matches(text, [
      'attendance', 'who attended', 'attendance results', 'open attendance',
      'show attendance', 'who is present', 'present passengers',
      'attendance screen', 'go to attendance',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'attendance');
    }

    // --- NAVIGATE: SETTINGS ---
    if (_matches(text, [
      'settings', 'open settings', 'preferences', 'profile',
      'go to settings', 'app settings',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'settings');
    }

    // Not recognized locally — let Gemini handle it
    return null;
  }

  static bool _matches(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}

enum IntentAction { startJourney, endJourney, navigate, startPoll }

class LocalIntent {
  final IntentAction action;
  final String? screen;

  const LocalIntent({required this.action, this.screen});
}
