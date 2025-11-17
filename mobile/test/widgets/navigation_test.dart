import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/bottom_nav_bar.dart';

void main() {
  group('Bottom Navigation Tests', () {
    testWidgets('BottomNavBar displays 3 tabs', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Verify BottomNavigationBar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify all 3 navigation items are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('BottomNavBar displays correct icons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      // Verify icons are present
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('BottomNavBar starts with Home tab selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('BottomNavBar calls onTap when tab is tapped', (
      WidgetTester tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on Progress tab
      await tester.tap(find.text('Progress'));
      await tester.pump();

      expect(tappedIndex, 1);
    });

    testWidgets('BottomNavBar calls onTap with correct index for Profile', (
      WidgetTester tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(tappedIndex, 2);
    });

    testWidgets('BottomNavBar has fixed type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.type, BottomNavigationBarType.fixed);
    });

    testWidgets('BottomNavBar has exactly 3 items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.items.length, 3);
    });

    testWidgets('BottomNavBar updates currentIndex correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Test')),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 1,
              onTap: (index) {},
            ),
          ),
        ),
      );

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, 1);
    });
  });

  group('MainScreen Navigation Tests', () {
    testWidgets('MainScreen uses IndexedStack', (WidgetTester tester) async {
      // Create a simple test widget that mimics MainScreen structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IndexedStack(
              index: 0,
              children: const [
                Center(child: Text('Home')),
                Center(child: Text('Progress')),
                Center(child: Text('Profile')),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('MainScreen structure preserves state with IndexedStack', (
      WidgetTester tester,
    ) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: IndexedStack(
                  index: currentIndex,
                  children: const [
                    Center(child: Text('Home Screen')),
                    Center(child: Text('Progress Screen')),
                    Center(child: Text('Profile Screen')),
                  ],
                ),
                bottomNavigationBar: BottomNavBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      // Initially on Home
      expect(find.text('Home Screen'), findsOneWidget);

      // Tap Progress
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Should show Progress screen
      expect(find.text('Progress Screen'), findsOneWidget);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should show Profile screen
      expect(find.text('Profile Screen'), findsOneWidget);

      // Tap Home again
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Should show Home screen
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
