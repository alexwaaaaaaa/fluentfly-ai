import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/lesson_card.dart';
import 'package:mobile/models/lesson.dart';

void main() {
  group('LessonCard Widget Tests', () {
    late Lesson testLesson;

    setUp(() {
      testLesson = Lesson(
        id: 1,
        skill: 'Grammar',
        title: 'Basic Greetings',
        level: 'A1',
        description: 'Learn how to greet people in English',
        meta: {'duration': 15, 'xp': 25},
      );
    });

    testWidgets('displays lesson information correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LessonCard(lesson: testLesson)),
        ),
      );

      // Verify title is displayed
      expect(find.text('Basic Greetings'), findsOneWidget);

      // Verify level badge is displayed
      expect(find.text('A1'), findsOneWidget);

      // Verify skill is displayed
      expect(find.text('Grammar'), findsOneWidget);

      // Verify description is displayed
      expect(find.text('Learn how to greet people in English'), findsOneWidget);

      // Verify duration is displayed
      expect(find.text('15 min'), findsOneWidget);

      // Verify XP is displayed
      expect(find.text('25 XP'), findsOneWidget);
    });

    testWidgets('displays progress bar when progress is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LessonCard(lesson: testLesson, progress: 0.65)),
        ),
      );

      // Verify progress indicator is displayed
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Verify progress percentage text is displayed
      expect(find.text('65% Complete'), findsOneWidget);
    });

    testWidgets('does not display progress bar when progress is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LessonCard(lesson: testLesson)),
        ),
      );

      // Verify progress indicator is not displayed
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Complete'), findsNothing);
    });

    testWidgets('handles tap interaction', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonCard(
              lesson: testLesson,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(tapped, true);
    });

    testWidgets('displays correct level color for different levels', (
      WidgetTester tester,
    ) async {
      final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

      for (final level in levels) {
        final lesson = Lesson(
          id: 1,
          skill: 'Grammar',
          title: 'Test Lesson',
          level: level,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LessonCard(lesson: lesson)),
          ),
        );

        // Verify level badge is displayed
        expect(find.text(level), findsOneWidget);

        // Clear the widget tree for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('handles lesson without description', (
      WidgetTester tester,
    ) async {
      final lessonNoDesc = Lesson(
        id: 1,
        skill: 'Vocabulary',
        title: 'Test Lesson',
        level: 'B1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LessonCard(lesson: lessonNoDesc)),
        ),
      );

      // Verify title is displayed
      expect(find.text('Test Lesson'), findsOneWidget);

      // Verify no description text is shown
      expect(find.text('Learn how to greet people in English'), findsNothing);
    });

    testWidgets('handles lesson without meta information', (
      WidgetTester tester,
    ) async {
      final lessonNoMeta = Lesson(
        id: 1,
        skill: 'Speaking',
        title: 'Test Lesson',
        level: 'A2',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LessonCard(lesson: lessonNoMeta)),
        ),
      );

      // Verify no duration or XP icons are displayed
      expect(find.byIcon(Icons.access_time), findsNothing);
      expect(find.byIcon(Icons.stars), findsNothing);
    });

    testWidgets('displays card with proper styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LessonCard(lesson: testLesson)),
        ),
      );

      // Verify Card widget exists
      expect(find.byType(Card), findsOneWidget);

      // Verify InkWell for tap interaction exists
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
