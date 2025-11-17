import 'package:flutter/material.dart';
import '../widgets/modern_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'speak_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

/// Main Screen Wrapper
/// Manages bottom navigation and preserves state across tabs
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Screens for each tab (5 tabs with center button)
  final List<Widget> _screens = const [
    HomeScreen(), // 0: Home
    HomeScreen(), // 1: Lessons (can be separate LessonsScreen later)
    SpeakScreen(), // 2: Video Call (center button)
    ProgressScreen(), // 3: Progress
    ProfileScreen(), // 4: Profile
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind navbar
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
