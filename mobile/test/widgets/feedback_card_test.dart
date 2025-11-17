import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/feedback_card.dart';

void main() {
  group('FeedbackCard Widget Tests', () {
    testWidgets('displays feedback card with all information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Fluency',
              score: 85,
              color: Colors.blue,
              icon: Icons.speed,
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Fluency'), findsOneWidget);

      // Verify score is displayed
      expect(find.text('85'), findsOneWidget);

      // Verify icon is displayed
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('displays correct score for pronunciation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Pronunciation',
              score: 92,
              color: Colors.green,
              icon: Icons.record_voice_over,
            ),
          ),
        ),
      );

      // Verify title and score
      expect(find.text('Pronunciation'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
    });

    testWidgets('displays correct score for grammar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Grammar',
              score: 78,
              color: Colors.orange,
              icon: Icons.menu_book,
            ),
          ),
        ),
      );

      // Verify title and score
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('78'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('handles low score correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Fluency',
              score: 25,
              color: Colors.red,
              icon: Icons.speed,
            ),
          ),
        ),
      );

      // Verify score is displayed
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('handles perfect score correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Pronunciation',
              score: 100,
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
        ),
      );

      // Verify perfect score is displayed
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('handles zero score correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Grammar',
              score: 0,
              color: Colors.grey,
              icon: Icons.error,
            ),
          ),
        ),
      );

      // Verify zero score is displayed
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('displays score bar with correct proportions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Fluency',
              score: 50,
              color: Colors.blue,
              icon: Icons.speed,
            ),
          ),
        ),
      );

      // Verify FractionallySizedBox exists (score bar)
      expect(find.byType(FractionallySizedBox), findsOneWidget);

      // Get the FractionallySizedBox widget
      final fractionallySizedBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );

      // Verify width factor is correct (50/100 = 0.5)
      expect(fractionallySizedBox.widthFactor, 0.5);
    });

    testWidgets('displays container with gradient decoration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Pronunciation',
              score: 88,
              color: Colors.purple,
              icon: Icons.mic,
            ),
          ),
        ),
      );

      // Find the main container
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Verify at least one container has BoxDecoration
      bool hasBoxDecoration = false;
      for (final containerFinder in containers.evaluate()) {
        final container = containerFinder.widget as Container;
        if (container.decoration is BoxDecoration) {
          hasBoxDecoration = true;
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.gradient, isA<LinearGradient>());
          break;
        }
      }
      expect(hasBoxDecoration, true);
    });

    testWidgets('icon has correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Fluency',
              score: 75,
              color: Colors.blue,
              icon: Icons.speed,
            ),
          ),
        ),
      );

      // Find the icon widget
      final icon = tester.widget<Icon>(find.byIcon(Icons.speed));

      // Verify icon size
      expect(icon.size, 40);
    });

    testWidgets('score text has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackCard(
              title: 'Grammar',
              score: 90,
              color: Colors.green,
              icon: Icons.check,
            ),
          ),
        ),
      );

      // Find the score text widget
      final scoreText = tester.widget<Text>(find.text('90'));

      // Verify text style
      expect(scoreText.style?.fontSize, 32);
      expect(scoreText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('displays multiple feedback cards correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                FeedbackCard(
                  title: 'Fluency',
                  score: 85,
                  color: Colors.blue,
                  icon: Icons.speed,
                ),
                FeedbackCard(
                  title: 'Pronunciation',
                  score: 92,
                  color: Colors.green,
                  icon: Icons.mic,
                ),
                FeedbackCard(
                  title: 'Grammar',
                  score: 78,
                  color: Colors.orange,
                  icon: Icons.book,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all three cards are displayed
      expect(find.byType(FeedbackCard), findsNWidgets(3));
      expect(find.text('Fluency'), findsOneWidget);
      expect(find.text('Pronunciation'), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
    });
  });
}
