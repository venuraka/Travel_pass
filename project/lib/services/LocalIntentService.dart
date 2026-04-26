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
      'start the journey', 'begin the trip', 'start driving',
      'journey start', 'trip start', 'on the road', 'ready to go',
      'ගමන පටන් ගන්න', 'ගමන ආරම්භ කරන්න', 'යමු', 'පටන් ගන්න',
    ])) {
      return LocalIntent(action: IntentAction.startJourney);
    }

    // --- END JOURNEY ---
    if (_matches(text, [
      'end journey', 'stop journey', 'finish journey', 'end trip',
      'stop trip', 'finish trip', 'trip done', 'journey done',
      'end my journey', 'stop my trip', 'arrived', 'we arrived',
      'ගමන ඉවරයි', 'ගමන නවත්වන්න', 'ගමන අවසන් කරන්න', 'නැවතුනා',
    ])) {
      return LocalIntent(action: IntentAction.endJourney);
    }

    // --- NAVIGATE: ATTENDANCE ---
    if (_matches(text, [
      'attendance', 'who attended', 'attendance results', 'open attendance',
      'show attendance', 'who is present', 'present passengers',
      'attendance screen', 'go to attendance', 'attendance page',
      'show attendance page', 'attendance tab',
      'පැමිණීම', 'පැමිණීම බලන්න', 'පැමිණීම පෙන්වන්න',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'attendance');
    }

    // --- START POLL ---
    if (_matches(text, [
      'start poll', 'create poll', 'make poll', 'begin poll',
      'open poll', 'new poll', 'poll',
      'create attendance poll', 'make attendance poll', 'attendance poll',
      'start the poll', 'do a poll', 'make a poll', 'start attendance poll',
      'ඡන්දය', 'ඡන්දය ආරම්භ කරන්න', 'ඡන්දයක් දාන්න', 'පෝල් එකක් දාන්න', 'පෝල්',
    ])) {
      return LocalIntent(action: IntentAction.startPoll);
    }

    // --- NAVIGATE: PASSENGERS ---
    if (_matches(text, [
      'passengers', 'show passengers', 'open passengers',
      'passenger list', 'my passengers', 'show my passengers',
      'go to passengers', 'passenger screen', 'open passenger list',
      'who is on the bus', 'passenger page', 'passengers tab',
      'මගීන්', 'මගීන් බලන්න', 'මගී ලැයිස්තුව',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'passengers');
    }

    // --- NAVIGATE: PAYMENTS / MONEY ---
    if (_matches(text, [
      'payments', 'money', 'show payments', 'payment history',
      'open payments', 'go to payments', 'payment screen',
      'show money', 'financials', 'revenue', 'earnings',
      'payment details', 'open money', 'payment page', 'money tab',
      'සල්ලි', 'මුදල්', 'ගෙවීම්', 'ගෙවීම් බලන්න',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'payments');
    }

    // --- NAVIGATE: DASHBOARD / HOME ---
    if (_matches(text, [
      'dashboard', 'home', 'go home', 'main screen', 'go to dashboard',
      'open dashboard', 'home screen', 'main page', 'go to home',
      'dashboard page', 'home tab',
      'මුල් පිටුව', 'ඩෑෂ්බෝඩ්',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'dashboard');
    }

    // --- NAVIGATE: UPDATES / REMINDERS ---
    if (_matches(text, [
      'updates', 'reminders', 'notifications', 'open updates',
      'show updates', 'show reminders', 'pending reminders',
      'payment reminders', 'go to updates', 'updates page', 'updates tab',
      'යාවත්කාලීන කිරීම්', 'මතක් කිරීම්', 'නොටිෆිකේෂන්',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'updates');
    }

    // --- NAVIGATE: HISTORY ---
    if (_matches(text, [
      'attendance history', 'past attendance', 'old attendance',
      'පැරණි පැමිණීම', 'පැමිණීමේ ඉතිහාසය',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'attendance_history');
    }
    if (_matches(text, [
      'payment history', 'past payments', 'transaction history',
      'ගෙවීම් ඉතිහාසය', 'පැරණි ගෙවීම්',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'payment_history');
    }
    if (_matches(text, [
      'cash history', 'money history', 'cash records',
      'මුදල් ඉතිහාසය', 'කැෂ් ඉතිහාසය',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'cash_history');
    }

    // --- NAVIGATE: REGISTRATION ---
    if (_matches(text, [
      'register passenger', 'add passenger', 'new passenger',
      'මගියෙකු ඇතුලත් කරන්න', 'අලුත් මගියෙක්',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'register_passenger');
    }

    // --- NAVIGATE: TODAY'S PASSENGERS ---
    if (_matches(text, [
      'today passengers', 'who is coming today', 'todays list',
      'අද එන මගීන්', 'අද ලැයිස්තුව',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'today_passengers');
    }

    // --- NAVIGATE: ROUTE ---
    if (_matches(text, [
      'update route', 'change route', 'edit route', 'my route',
      'මාර්ගය වෙනස් කරන්න', 'රූට් එක',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'update_route');
    }

    // --- NAVIGATE: SETTINGS ---
    if (_matches(text, [
      'settings', 'open settings', 'preferences', 'profile',
      'go to settings', 'app settings', 'settings page',
      'සැකසුම්', 'සෙටින්ග්ස්',
    ])) {
      return LocalIntent(action: IntentAction.navigate, screen: 'settings');
    }

    // Not recognized locally — escalate to Gemini for complex understanding
    return null;
  }

  /// Checks if [text] contains any of the [keywords] using whole-phrase
  /// word-boundary matching via regex.
  ///
  /// This prevents partial collisions such as bare "go" matching inside
  /// "go to attendance page" — which previously fired startJourney.
  static bool _matches(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final pattern = RegExp(
        r'(?<![a-z])' + RegExp.escape(keyword) + r'(?![a-z])',
      );
      if (pattern.hasMatch(text)) return true;
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
