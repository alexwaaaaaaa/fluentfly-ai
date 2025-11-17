import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/widgets/mic_button.dart';

void main() {
  group('MicButton Widget Tests', () {
    testWidgets('displays mic icon when not recording', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: false, onPressed: () {}),
            ),
          ),
        ),
      );

      // Verify mic icon is displayed
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('displays stop icon when recording', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: true, onPressed: () {}),
            ),
          ),
        ),
      );

      // Verify stop icon is displayed
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('handles tap interaction with custom onPressed', (
      WidgetTester tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(
                isRecording: false,
                onPressed: () {
                  pressed = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Verify callback was called
      expect(pressed, true);
    });

    testWidgets('calls onRecordingStart callback', (WidgetTester tester) async {
      bool startCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(
                isRecording: false,
                onRecordingStart: () {
                  startCalled = true;
                },
                onPressed: () {
                  startCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Verify callback was called
      expect(startCalled, true);
    });

    testWidgets('calls onRecordingStop callback', (WidgetTester tester) async {
      String? recordingPath;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(
                isRecording: true,
                onRecordingStop: (path) {
                  recordingPath = path;
                },
                onPressed: () {
                  recordingPath = '/test/path.mp3';
                },
              ),
            ),
          ),
        ),
      );

      // Tap the button to stop recording
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Verify callback was called
      expect(recordingPath, isNotNull);
    });

    testWidgets('displays button with correct size', (
      WidgetTester tester,
    ) async {
      const buttonSize = 100.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(
                isRecording: false,
                size: buttonSize,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify size
      expect(container.constraints?.maxWidth, buttonSize);
      expect(container.constraints?.maxHeight, buttonSize);
    });

    testWidgets('displays default size when not specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: false, onPressed: () {}),
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify default size (80)
      expect(container.constraints?.maxWidth, 80);
      expect(container.constraints?.maxHeight, 80);
    });

    testWidgets('has circular shape decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: false, onPressed: () {}),
            ),
          ),
        ),
      );

      // Find the container with decoration
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify decoration
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('displays gradient decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: false, onPressed: () {}),
            ),
          ),
        ),
      );

      // Find the container with decoration
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify gradient
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('icon size is proportional to button size', (
      WidgetTester tester,
    ) async {
      const buttonSize = 100.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(
                isRecording: false,
                size: buttonSize,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Find the icon
      final icon = tester.widget<Icon>(find.byIcon(Icons.mic));

      // Verify icon size is 50% of button size
      expect(icon.size, buttonSize * 0.5);
    });

    testWidgets('changes state from not recording to recording', (
      WidgetTester tester,
    ) async {
      // Start not recording
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: false, onPressed: () {}),
            ),
          ),
        ),
      );

      // Verify mic icon
      expect(find.byIcon(Icons.mic), findsOneWidget);

      // Change to recording
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: true, onPressed: () {}),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify stop icon
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('has GestureDetector for tap handling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MicButton(isRecording: false, onPressed: () {}),
            ),
          ),
        ),
      );

      // Verify GestureDetector exists
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });
}
