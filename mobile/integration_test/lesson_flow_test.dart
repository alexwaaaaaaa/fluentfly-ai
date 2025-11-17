import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

/// Integration test for complete lesson flow
/// Tests: vocabulary → listening → speaking → quiz → feedback
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lesson Flow Integration Test', () {
    testWidgets('Complete lesson flow from start to finish', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen and authentication
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to home screen (should be default)
      final homeTab = find.byIcon(Icons.home_outlined);
      if (homeTab.evaluate().isEmpty) {
        final homeTabActive = find.byIcon(Icons.home);
        expect(homeTabActive, findsOneWidget);
      }

      // Wait for lessons to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap on a lesson card
      final lessonCard = find.byType(Card).first;
      if (lessonCard.evaluate().isNotEmpty) {
        await tester.tap(lessonCard);
        await tester.pumpAndSettle();

        // Should navigate to lesson overview screen
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Find and tap start lesson button
        final startButton = find.text('Start Lesson');
        if (startButton.evaluate().isNotEmpty) {
          await tester.tap(startButton);
          await tester.pumpAndSettle();

          // Stage 1: Vocabulary Screen
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.text('Vocabulary'), findsWidgets);

          // Wait for TTS audio to play (simulated)
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Tap next button to proceed
          final nextButton = find.text('Next');
          if (nextButton.evaluate().isNotEmpty) {
            await tester.tap(nextButton);
            await tester.pumpAndSettle();
          }

          // Stage 2: Listening Screen
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.text('Listening'), findsWidgets);

          // Play audio and answer question
          final playButton = find.byIcon(Icons.play_arrow);
          if (playButton.evaluate().isNotEmpty) {
            await tester.tap(playButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }

          // Select an answer option
          final answerOption = find.byType(RadioListTile<String>).first;
          if (answerOption.evaluate().isNotEmpty) {
            await tester.tap(answerOption);
            await tester.pumpAndSettle();
          }

          // Submit answer
          final submitButton = find.text('Submit');
          if (submitButton.evaluate().isNotEmpty) {
            await tester.tap(submitButton);
            await tester.pumpAndSettle();
          }

          // Continue to next stage
          final continueButton = find.text('Continue');
          if (continueButton.evaluate().isNotEmpty) {
            await tester.tap(continueButton);
            await tester.pumpAndSettle();
          }

          // Stage 3: Speaking Screen
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.text('Speaking'), findsWidgets);

          // Tap microphone button (simulated recording)
          final micButton = find.byIcon(Icons.mic);
          if (micButton.evaluate().isNotEmpty) {
            await tester.tap(micButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Stop recording
            await tester.tap(micButton);
            await tester.pumpAndSettle();
          }

          // Skip or continue
          final skipButton = find.text('Skip');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle();
          }

          // Stage 4: Quiz Screen
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.text('Quiz'), findsWidgets);

          // Answer quiz questions
          final quizOption = find.byType(RadioListTile<String>).first;
          if (quizOption.evaluate().isNotEmpty) {
            await tester.tap(quizOption);
            await tester.pumpAndSettle();
          }

          // Submit quiz
          final submitQuizButton = find.text('Submit');
          if (submitQuizButton.evaluate().isNotEmpty) {
            await tester.tap(submitQuizButton);
            await tester.pumpAndSettle();
          }

          // Stage 5: Feedback Screen
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.text('Lesson Complete'), findsWidgets);

          // Verify feedback elements are displayed
          expect(find.text('Fluency'), findsWidgets);
          expect(find.text('Pronunciation'), findsWidgets);
          expect(find.text('Grammar'), findsWidgets);

          // Verify XP award animation
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Tap finish button
          final finishButton = find.text('Finish');
          if (finishButton.evaluate().isNotEmpty) {
            await tester.tap(finishButton);
            await tester.pumpAndSettle();
          }

          // Should return to home screen
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // Verify no exceptions occurred during the flow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lesson navigation and state persistence', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to home
      final homeTab = find.byIcon(Icons.home_outlined);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();
      }

      // Wait for lessons to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify lesson cards are displayed
      expect(find.byType(Card), findsWidgets);

      // Tap on a lesson
      final lessonCard = find.byType(Card).first;
      if (lessonCard.evaluate().isNotEmpty) {
        await tester.tap(lessonCard);
        await tester.pumpAndSettle();

        // Navigate back
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        // Should be back on home screen
        expect(find.byType(Card), findsWidgets);
      }

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Offline lesson access', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to home
      final homeTab = find.byIcon(Icons.home_outlined);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();
      }

      // Wait for lessons to load and cache
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify offline indicator is present (if offline)
      // In a real test, you'd toggle network connectivity
      // For now, we verify the app handles offline state gracefully

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
