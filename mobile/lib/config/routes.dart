import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/main_screen.dart';
import '../screens/home_screen.dart';
import '../screens/speak_screen.dart';
import '../screens/review_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/lesson/lesson_overview_screen.dart';
import '../screens/lesson/lesson_flow_screen.dart';
import '../screens/video_call_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String home = '/home';
  static const String speak = '/speak';
  static const String review = '/review';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String lessonOverview = '/lesson-overview';
  static const String lessonFlow = '/lesson-flow';
  static const String videoCall = '/video-call';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      main: (context) => const MainScreen(),
      home: (context) => const HomeScreen(),
      speak: (context) => const SpeakScreen(),
      review: (context) => const ReviewScreen(),
      progress: (context) => const ProgressScreen(),
      profile: (context) => const ProfileScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case otp:
        final phone = settings.arguments as String?;
        if (phone == null) return null;
        return MaterialPageRoute(builder: (context) => OtpScreen(phone: phone));
      case onboarding:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return null;
        final phone = args['phone'] as String?;
        final otp = args['otp'] as String?;
        if (phone == null || otp == null) return null;
        return MaterialPageRoute(
          builder: (context) => OnboardingScreen(phone: phone, otp: otp),
        );
      case lessonOverview:
        final lessonId = settings.arguments as int?;
        if (lessonId == null) return null;
        return MaterialPageRoute(
          builder: (context) => LessonOverviewScreen(lessonId: lessonId),
        );
      case lessonFlow:
        final lessonId = settings.arguments as int?;
        if (lessonId == null) return null;
        return MaterialPageRoute(
          builder: (context) => LessonFlowScreen(lessonId: lessonId),
        );
      case videoCall:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return null;
        final lessonId = args['lessonId'] as int?;
        final topic = args['topic'] as String?;
        if (lessonId == null || topic == null) return null;
        return MaterialPageRoute(
          builder: (context) =>
              VideoCallScreen(lessonId: lessonId, topic: topic),
        );
      default:
        return null;
    }
  }
}
