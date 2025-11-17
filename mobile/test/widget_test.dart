// FluentFly app smoke test
//
// This test verifies that the app initializes correctly with ProviderScope

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Wait for initialization
    await tester.pumpAndSettle();

    // Verify that the app loads (splash screen or login screen should appear)
    // The app should not crash on initialization
    expect(find.byType(MyApp), findsOneWidget);
  });
}
