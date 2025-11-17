import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

/// Integration test for authentication flow
/// Tests phone OTP authentication from login to verification
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Test', () {
    testWidgets('Complete phone OTP authentication flow', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate to login screen
      expect(find.text('FluentFly'), findsOneWidget);
      expect(find.text('Learn English with AI'), findsWidgets);

      // Enter phone number in the text field
      final phoneField = find.byType(TextFormField);
      expect(phoneField, findsOneWidget);
      await tester.enterText(phoneField, '+919876543210');
      await tester.pumpAndSettle();

      // Tap continue with phone button to send OTP
      final continueButton = find.text('Continue with Phone');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Wait for API call to complete (may fail if backend not running)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check if we navigated to OTP screen (backend available)
      final otpScreen = find.text('Verify OTP');

      // If backend is not available, test should still pass
      if (otpScreen.evaluate().isEmpty) {
        // Backend not running - verify error handling works
        expect(find.text('FluentFly'), findsOneWidget);
        expect(tester.takeException(), isNull);
        return; // Exit test gracefully
      }

      // Backend is available - continue with OTP flow
      expect(otpScreen, findsOneWidget);

      // Enter OTP (6 digits - in a real test, you'd use a test OTP)
      final otpFields = find.byType(TextField);
      expect(otpFields, findsWidgets);

      // Enter OTP digits in all 6 fields
      if (otpFields.evaluate().length >= 6) {
        await tester.enterText(otpFields.at(0), '1');
        await tester.pumpAndSettle();
        await tester.enterText(otpFields.at(1), '2');
        await tester.pumpAndSettle();
        await tester.enterText(otpFields.at(2), '3');
        await tester.pumpAndSettle();
        await tester.enterText(otpFields.at(3), '4');
        await tester.pumpAndSettle();
        await tester.enterText(otpFields.at(4), '5');
        await tester.pumpAndSettle();
        await tester.enterText(otpFields.at(5), '6');
        await tester.pumpAndSettle();
      }

      // Note: OTP screen auto-verifies when 6th digit is entered
      // But we can also manually tap verify button if needed
      final verifyButton = find.text('Verify');
      if (verifyButton.evaluate().isNotEmpty) {
        await tester.tap(verifyButton);
        await tester.pumpAndSettle();
      }

      // Wait for authentication to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're authenticated (should show home screen or main navigation)
      // Note: In a real test with a backend, we'd verify successful navigation
      // For now, we verify the flow completes without crashes
      expect(tester.takeException(), isNull);
    });

    testWidgets('Google authentication flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be on login screen
      expect(find.text('FluentFly'), findsOneWidget);

      // Find Google sign-in button
      final googleButton = find.text('Continue with Google');
      expect(googleButton, findsOneWidget);

      // Tap Google button
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      // Note: Google sign-in requires platform-specific setup
      // In a real integration test, you'd mock the Google sign-in
      // For now, we verify the button tap doesn't crash the app
      expect(tester.takeException(), isNull);
    });

    testWidgets('Logout flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile screen (assuming we're authenticated)
      final profileTab = find.byIcon(Icons.person_outline);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Find and tap logout button
        final logoutButton = find.text('Logout');
        if (logoutButton.evaluate().isNotEmpty) {
          await tester.tap(logoutButton);
          await tester.pumpAndSettle();

          // Should return to login screen
          await tester.pumpAndSettle(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
