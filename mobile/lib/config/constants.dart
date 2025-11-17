/// Application-wide constants
class AppConstants {
  // API Configuration
  // Note: Use 10.0.2.2 for Android emulator, or your laptop's local IP for physical device
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.31.73:3000/api', // Physical device: laptop IP
    // defaultValue: 'http://10.0.2.2:3000/api', // Emulator
  );

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(seconds: 60);

  // Cache Configuration
  static const int maxCachedLessons = 5;
  static const Duration cacheTTL = Duration(days: 7);

  // Audio Configuration
  static const int audioSampleRate = 48000;
  static const String audioFormat = 'mp3';
  static const int audioBitrate = 48; // kbps

  // Animation Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Gamification
  static const int xpPerCorrectAnswer = 10;
  static const int xpPerCompletedLesson = 25;
  static const int xpBonusPerStreakDay = 5;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';

  // Lesson Levels
  static const List<String> lessonLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  // Exercise Types
  static const String exerciseTypeMCQ = 'mcq';
  static const String exerciseTypeFillBlank = 'fill_blank';
  static const String exerciseTypeSpeaking = 'speaking';
  static const String exerciseTypeListening = 'listening';

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String authErrorMessage =
      'Authentication failed. Please login again.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  // Success Messages
  static const String lessonCompletedMessage = 'Lesson completed! Great job!';
  static const String streakMaintainedMessage =
      'Streak maintained! Keep it up!';
  static const String badgeEarnedMessage = 'New badge earned!';
}
