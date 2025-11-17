#!/bin/bash

# FluentFly Integration Test Runner
# This script runs all integration tests for the mobile app

set -e

echo "🚀 FluentFly Integration Test Runner"
echo "======================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Navigate to mobile directory
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Check for connected devices
echo "📱 Checking for connected devices..."
DEVICES=$(flutter devices --machine | grep -c "\"id\"" || true)

if [ "$DEVICES" -eq 0 ]; then
    echo "⚠️  No devices found. Please connect a device or start an emulator."
    echo ""
    echo "To start an emulator:"
    echo "  flutter emulators"
    echo "  flutter emulators --launch <emulator_id>"
    exit 1
fi

echo "✅ Found $DEVICES device(s)"
flutter devices
echo ""

# Run integration tests
echo "🧪 Running integration tests..."
echo ""

# Test 1: Authentication Flow
echo "1️⃣  Testing Authentication Flow..."
if flutter test integration_test/auth_flow_test.dart --ignore-timeouts; then
    echo "✅ Authentication flow tests passed"
else
    echo "❌ Authentication flow tests failed"
    exit 1
fi
echo ""

# Test 2: Lesson Flow
echo "2️⃣  Testing Lesson Flow..."
if flutter test integration_test/lesson_flow_test.dart --ignore-timeouts; then
    echo "✅ Lesson flow tests passed"
else
    echo "❌ Lesson flow tests failed"
    exit 1
fi
echo ""

# Test 3: Speaking Practice
echo "3️⃣  Testing Speaking Practice with AI..."
if flutter test integration_test/speaking_practice_test.dart --ignore-timeouts; then
    echo "✅ Speaking practice tests passed"
else
    echo "❌ Speaking practice tests failed"
    exit 1
fi
echo ""

# Summary
echo "======================================"
echo "✅ All integration tests passed!"
echo "======================================"
echo ""
echo "Test Coverage:"
echo "  ✓ Authentication flow (Google OAuth, Phone OTP, Logout)"
echo "  ✓ Complete lesson flow (Vocabulary → Listening → Speaking → Quiz → Feedback)"
echo "  ✓ AI speaking practice (Avatar, Audio, Conversation turns)"
echo ""
echo "Requirements satisfied: 21.3, 21.5"
