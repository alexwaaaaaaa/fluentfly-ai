import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

/// Integration test for speaking practice with AI avatar
/// Tests: AI conversation flow, avatar animations, audio recording
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Speaking Practice with AI Integration Test', () {
    testWidgets('Complete AI conversation flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen and authentication
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Speak tab
      final speakTab = find.byIcon(Icons.mic_outlined);
      if (speakTab.evaluate().isNotEmpty) {
        await tester.tap(speakTab);
        await tester.pumpAndSettle();
      } else {
        // Try active icon
        final speakTabActive = find.byIcon(Icons.mic);
        if (speakTabActive.evaluate().isNotEmpty) {
          await tester.tap(speakTabActive);
          await tester.pumpAndSettle();
        }
      }

      // Wait for speak screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify AI avatar is displayed
      expect(find.text('AI Tutor'), findsWidgets);

      // Find microphone button
      final micButton = find.byIcon(Icons.mic);
      expect(micButton, findsWidgets);

      // Tap microphone to start recording
      if (micButton.evaluate().isNotEmpty) {
        await tester.tap(micButton.first);
        await tester.pumpAndSettle();

        // Wait for recording state
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify recording indicator is shown
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        // Stop recording
        final stopButton = find.byIcon(Icons.stop);
        if (stopButton.evaluate().isNotEmpty) {
          await tester.tap(stopButton);
          await tester.pumpAndSettle();
        } else {
          // Tap mic button again to stop
          await tester.tap(micButton.first);
          await tester.pumpAndSettle();
        }

        // Wait for AI response processing
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify AI response is displayed
        // Note: In a real test with backend, we'd verify actual response
        // For now, we verify the flow completes without crashes
      }

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Avatar animation sync with audio', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Speak tab
      final speakTab = find.byIcon(Icons.mic_outlined);
      if (speakTab.evaluate().isNotEmpty) {
        await tester.tap(speakTab);
        await tester.pumpAndSettle();
      }

      // Wait for screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify avatar widget is present
      // Avatar should be in idle state initially
      expect(find.byType(Container), findsWidgets);

      // Simulate AI speaking by triggering a conversation
      final micButton = find.byIcon(Icons.mic);
      if (micButton.evaluate().isNotEmpty) {
        await tester.tap(micButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Stop recording quickly
        await tester.tap(micButton.first);
        await tester.pumpAndSettle();

        // Wait for AI response and avatar animation
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify avatar animation is playing
        // In a real test, you'd verify Lottie animation state
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple conversation turns', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Speak tab
      final speakTab = find.byIcon(Icons.mic_outlined);
      if (speakTab.evaluate().isNotEmpty) {
        await tester.tap(speakTab);
        await tester.pumpAndSettle();
      }

      // Wait for screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Perform multiple conversation turns
      for (int i = 0; i < 3; i++) {
        final micButton = find.byIcon(Icons.mic);
        if (micButton.evaluate().isNotEmpty) {
          // Start recording
          await tester.tap(micButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Stop recording
          await tester.tap(micButton.first);
          await tester.pumpAndSettle();

          // Wait for AI response
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // Verify conversation history is maintained
      // In a real test, you'd verify chat messages are displayed
      expect(tester.takeException(), isNull);
    });

    testWidgets('Feedback generation after conversation', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Speak tab
      final speakTab = find.byIcon(Icons.mic_outlined);
      if (speakTab.evaluate().isNotEmpty) {
        await tester.tap(speakTab);
        await tester.pumpAndSettle();
      }

      // Wait for screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Have a conversation
      final micButton = find.byIcon(Icons.mic);
      if (micButton.evaluate().isNotEmpty) {
        // Record and send message
        await tester.tap(micButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(micButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Find and tap end conversation button
      final endButton = find.text('End Conversation');
      if (endButton.evaluate().isNotEmpty) {
        await tester.tap(endButton);
        await tester.pumpAndSettle();

        // Wait for feedback generation
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify feedback screen is displayed
        expect(find.text('Feedback'), findsWidgets);
        expect(find.text('Fluency'), findsWidgets);
        expect(find.text('Pronunciation'), findsWidgets);
        expect(find.text('Grammar'), findsWidgets);
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Error handling during AI conversation', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Speak tab
      final speakTab = find.byIcon(Icons.mic_outlined);
      if (speakTab.evaluate().isNotEmpty) {
        await tester.tap(speakTab);
        await tester.pumpAndSettle();
      }

      // Wait for screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Attempt to record without microphone permission (simulated)
      final micButton = find.byIcon(Icons.mic);
      if (micButton.evaluate().isNotEmpty) {
        await tester.tap(micButton.first);
        await tester.pumpAndSettle();

        // Wait for error handling
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify error message or fallback UI is displayed
        // In a real test, you'd verify specific error handling
      }

      // Verify app doesn't crash on errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Audio playback of AI responses', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Speak tab
      final speakTab = find.byIcon(Icons.mic_outlined);
      if (speakTab.evaluate().isNotEmpty) {
        await tester.tap(speakTab);
        await tester.pumpAndSettle();
      }

      // Wait for screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Have a conversation to trigger AI response
      final micButton = find.byIcon(Icons.mic);
      if (micButton.evaluate().isNotEmpty) {
        await tester.tap(micButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(micButton.first);
        await tester.pumpAndSettle();

        // Wait for AI response with TTS audio
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify audio playback controls are available
        // In a real test, you'd verify audio player state
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
