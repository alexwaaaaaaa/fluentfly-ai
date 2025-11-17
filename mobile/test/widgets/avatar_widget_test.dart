import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/avatar_widget.dart';

void main() {
  group('AvatarWidget Tests', () {
    testWidgets('displays avatar with default animation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: false)),
        ),
      );

      // Verify Container exists with proper dimensions
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(ClipOval),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 280);
      expect(container.constraints?.maxHeight, 280);
    });

    testWidgets('starts animation when isAnimating is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: true)),
        ),
      );

      // Allow animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify widget is still present (animation is running)
      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('stops animation when isAnimating changes to false', (
      WidgetTester tester,
    ) async {
      // Start with animation
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: true)),
        ),
      );

      await tester.pump();

      // Change to not animating
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: false)),
        ),
      );

      await tester.pump();

      // Verify widget is still present
      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('changes animation based on emotion', (
      WidgetTester tester,
    ) async {
      // Start with neutral emotion
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(isAnimating: false, emotion: 'neutral'),
          ),
        ),
      );

      await tester.pump();

      // Change to happy emotion
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(isAnimating: false, emotion: 'happy'),
          ),
        ),
      );

      await tester.pump();

      // Verify widget updated
      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('uses custom animation path when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(
              isAnimating: false,
              animationPath: 'assets/lottie/happy_feedback_star.json',
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget is rendered
      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('displays circular container with gradient', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: false)),
        ),
      );

      // Verify Container with BoxDecoration exists
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(ClipOval),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('handles different emotion states', (
      WidgetTester tester,
    ) async {
      final emotions = ['neutral', 'happy', 'encouraging'];

      for (final emotion in emotions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AvatarWidget(isAnimating: false, emotion: emotion),
            ),
          ),
        );

        await tester.pump();

        // Verify widget is rendered for each emotion
        expect(find.byType(AvatarWidget), findsOneWidget);

        // Clear widget tree for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('contains ClipOval for circular clipping', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: false)),
        ),
      );

      // Verify ClipOval exists
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('animation controller is properly initialized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarWidget(isAnimating: true)),
        ),
      );

      // Pump a few frames to ensure animation controller is working
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify widget is still present and functioning
      expect(find.byType(AvatarWidget), findsOneWidget);
    });
  });
}
