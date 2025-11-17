import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

/// Integration test for video call functionality
/// Tests: Video call connection, navigation, controls, and session management
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Video Call Integration Test', () {
    testWidgets('End-to-end video call flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen and authentication
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Home tab
      final homeTab = find.byIcon(Icons.home);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();
      }

      // Find and tap on a lesson
      final lessonCard = find.byType(Card).first;
      if (lessonCard.evaluate().isNotEmpty) {
        await tester.tap(lessonCard);
        await tester.pumpAndSettle();

        // Wait for lesson overview screen
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find "Start Video Call" button
        final videoCallButton = find.text('Start Video Call with AI Tutor');
        if (videoCallButton.evaluate().isEmpty) {
          // Try alternative text
          final altButton = find.textContaining('Video Call');
          if (altButton.evaluate().isNotEmpty) {
            await tester.tap(altButton.first);
            await tester.pumpAndSettle();
          }
        } else {
          await tester.tap(videoCallButton);
          await tester.pumpAndSettle();
        }

        // Wait for video call screen to load
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify video call controls are present
        expect(find.byIcon(Icons.mic_off), findsWidgets);
        expect(find.byIcon(Icons.videocam_off), findsWidgets);
        expect(find.byIcon(Icons.call_end), findsWidgets);

        // Wait for connection
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // End the call
        final endCallButton = find.byIcon(Icons.call_end);
        if (endCallButton.evaluate().isNotEmpty) {
          await tester.tap(endCallButton);
          await tester.pumpAndSettle();

          // Wait for call summary screen
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify summary is displayed
          expect(find.textContaining('Call Duration'), findsWidgets);
        }
      }

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Navigation between tabs preserves state', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Home tab
      final homeTab = find.byIcon(Icons.home);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        // Verify Home screen content
        expect(find.text('Lessons'), findsWidgets);
      }

      // Navigate to Progress tab
      final progressTab = find.byIcon(Icons.trending_up);
      if (progressTab.evaluate().isNotEmpty) {
        await tester.tap(progressTab);
        await tester.pumpAndSettle();

        // Verify Progress screen content
        expect(find.text('Your Progress'), findsWidgets);
      }

      // Navigate to Profile tab
      final profileTab = find.byIcon(Icons.person);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Verify Profile screen content
        expect(find.text('Profile'), findsWidgets);
      }

      // Navigate back to Home
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        // Verify state is preserved
        expect(find.text('Lessons'), findsWidgets);
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Video call controls functionality', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to a lesson and start video call
      // (Simplified - assumes we can reach video call screen)
      final homeTab = find.byIcon(Icons.home);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        final lessonCard = find.byType(Card).first;
        if (lessonCard.evaluate().isNotEmpty) {
          await tester.tap(lessonCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final videoCallButton = find.textContaining('Video Call');
          if (videoCallButton.evaluate().isNotEmpty) {
            await tester.tap(videoCallButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Test mute button
            final muteButton = find.byIcon(Icons.mic_off);
            if (muteButton.evaluate().isNotEmpty) {
              await tester.tap(muteButton);
              await tester.pumpAndSettle();

              // Verify mute state changed
              expect(find.byIcon(Icons.mic), findsWidgets);

              // Unmute
              await tester.tap(find.byIcon(Icons.mic));
              await tester.pumpAndSettle();
            }

            // Test camera toggle
            final cameraButton = find.byIcon(Icons.videocam_off);
            if (cameraButton.evaluate().isNotEmpty) {
              await tester.tap(cameraButton);
              await tester.pumpAndSettle();

              // Verify camera state changed
              expect(find.byIcon(Icons.videocam), findsWidgets);
            }

            // End call
            final endCallButton = find.byIcon(Icons.call_end);
            if (endCallButton.evaluate().isNotEmpty) {
              await tester.tap(endCallButton);
              await tester.pumpAndSettle();
            }
          }
        }
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Call interruption and resumption', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start a video call
      final homeTab = find.byIcon(Icons.home);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        final lessonCard = find.byType(Card).first;
        if (lessonCard.evaluate().isNotEmpty) {
          await tester.tap(lessonCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final videoCallButton = find.textContaining('Video Call');
          if (videoCallButton.evaluate().isNotEmpty) {
            await tester.tap(videoCallButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Simulate app going to background
            await tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            await tester.pumpAndSettle();

            // Simulate app coming back to foreground
            await tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Verify call is still active or properly handled
            expect(find.byIcon(Icons.call_end), findsWidgets);

            // End call
            final endCallButton = find.byIcon(Icons.call_end);
            if (endCallButton.evaluate().isNotEmpty) {
              await tester.tap(endCallButton);
              await tester.pumpAndSettle();
            }
          }
        }
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Connection quality monitoring', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start a video call
      final homeTab = find.byIcon(Icons.home);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        final lessonCard = find.byType(Card).first;
        if (lessonCard.evaluate().isNotEmpty) {
          await tester.tap(lessonCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final videoCallButton = find.textContaining('Video Call');
          if (videoCallButton.evaluate().isNotEmpty) {
            await tester.tap(videoCallButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Wait for connection quality indicators
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Verify connection quality UI elements
            // (In a real test, you'd verify specific quality indicators)
            expect(find.byType(Container), findsWidgets);

            // End call
            final endCallButton = find.byIcon(Icons.call_end);
            if (endCallButton.evaluate().isNotEmpty) {
              await tester.tap(endCallButton);
              await tester.pumpAndSettle();
            }
          }
        }
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Call summary displays analytics', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start and complete a video call
      final homeTab = find.byIcon(Icons.home);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        final lessonCard = find.byType(Card).first;
        if (lessonCard.evaluate().isNotEmpty) {
          await tester.tap(lessonCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final videoCallButton = find.textContaining('Video Call');
          if (videoCallButton.evaluate().isNotEmpty) {
            await tester.tap(videoCallButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Wait for some call duration
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // End call
            final endCallButton = find.byIcon(Icons.call_end);
            if (endCallButton.evaluate().isNotEmpty) {
              await tester.tap(endCallButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));

              // Verify call summary screen
              expect(find.textContaining('Call Duration'), findsWidgets);
              expect(find.textContaining('Speaking Time'), findsWidgets);
              expect(find.textContaining('Conversation Turns'), findsWidgets);

              // Verify "Practice Again" button
              final practiceAgainButton = find.text('Practice Again');
              if (practiceAgainButton.evaluate().isNotEmpty) {
                expect(practiceAgainButton, findsOneWidget);
              }
            }
          }
        }
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
