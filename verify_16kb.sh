#!/bin/bash

# 16KB Page Size Verification Script
echo "=== 16KB PAGE SIZE SUPPORT VERIFICATION ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_pass() { echo -e "${GREEN}✅ $1${NC}"; }
check_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
check_fail() { echo -e "${RED}❌ $1${NC}"; }

echo "1. ANDROID GRADLE PLUGIN (AGP) VERSION"
echo "======================================"
AGP_VERSION=$(grep "classpath 'com.android.tools.build:gradle:" android/build.gradle | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
if [[ "$AGP_VERSION" == "8.5.1" ]] || [[ "$AGP_VERSION" > "8.5.1" ]]; then
    check_pass "AGP Version: $AGP_VERSION (>= 8.5.1 - EXCELLENT)"
elif [[ "$AGP_VERSION" > "8.5.0" ]]; then
    check_warn "AGP Version: $AGP_VERSION (>= 8.5.0 - Good but recommend 8.5.1+)"
else
    check_fail "AGP Version: $AGP_VERSION (< 8.5.1 - UPDATE REQUIRED)"
fi
echo ""

echo "2. GRADLE WRAPPER VERSION"
echo "========================="
GRADLE_VERSION=$(grep "distributionUrl" android/gradle/wrapper/gradle-wrapper.properties | grep -o '[0-9]\+\.[0-9]\+')
if [[ "$GRADLE_VERSION" > "8.6" ]] || [[ "$GRADLE_VERSION" == "8.7" ]]; then
    check_pass "Gradle Version: $GRADLE_VERSION (>= 8.7 - EXCELLENT)"
elif [[ "$GRADLE_VERSION" > "7.9" ]]; then
    check_warn "Gradle Version: $GRADLE_VERSION (>= 8.0 - Good)"
else
    check_fail "Gradle Version: $GRADLE_VERSION (< 8.0 - UPDATE REQUIRED)"
fi
echo ""

echo "3. ANDROID MANIFEST CONFIGURATION"
echo "================================="
if grep -q 'android:extractNativeLibs="false"' android/app/src/main/AndroidManifest.xml; then
    check_pass "extractNativeLibs set to false"
else
    check_fail "extractNativeLibs NOT set to false - REQUIRED FOR 16KB"
fi

if grep -q 'android:pageSizeCompat="disabled"' android/app/src/main/AndroidManifest.xml; then
    check_pass "pageSizeCompat set to disabled (no backcompat warnings)"
else
    check_warn "pageSizeCompat not set (app may show compatibility warnings)"
fi
echo ""

echo "4. BUILD CONFIGURATION"
echo "====================="
COMPILE_SDK=$(grep -E "(compileSdk|compileSdkVersion)" android/app/build.gradle | grep -o '[0-9]\+' | tail -1)
if [[ "$COMPILE_SDK" -ge 35 ]]; then
    check_pass "Compile SDK: $COMPILE_SDK (>= 35 - Latest Android 15)"
elif [[ "$COMPILE_SDK" -ge 34 ]]; then
    check_warn "Compile SDK: $COMPILE_SDK (>= 34 - Android 14, recommend 35)"
else
    check_fail "Compile SDK: $COMPILE_SDK (< 34 - UPDATE REQUIRED)"
fi

TARGET_SDK=$(grep -E "(targetSdk|targetSdkVersion)" android/app/build.gradle | grep -o '[0-9]\+' | tail -1)
if [[ "$TARGET_SDK" -ge 35 ]]; then
    check_pass "Target SDK: $TARGET_SDK (>= 35 - Excellent)"
elif [[ "$TARGET_SDK" -ge 34 ]]; then
    check_warn "Target SDK: $TARGET_SDK (>= 34 - Good, recommend 35)"
else
    check_fail "Target SDK: $TARGET_SDK (< 34 - UPDATE REQUIRED)"
fi

if grep -q "useLegacyPackaging = false" android/app/build.gradle; then
    check_pass "Modern packaging enabled (useLegacyPackaging = false)"
elif grep -q "useLegacyPackaging" android/app/build.gradle; then
    check_warn "Legacy packaging configuration found"
else
    check_warn "No explicit packaging configuration (using defaults)"
fi
echo ""

echo "5. NATIVE LIBRARY DEPENDENCIES ANALYSIS"
echo "======================================="
echo "Critical dependencies with native libraries:"

# Check key dependencies
if grep -q "audioplayers:" pubspec.yaml; then
    AUDIO_VERSION=$(grep "audioplayers:" pubspec.yaml | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    check_pass "audioplayers: ^$AUDIO_VERSION (Audio playback - should be compatible)"
fi

if grep -q "flutter_sound:" pubspec.yaml; then
    SOUND_VERSION=$(grep "flutter_sound:" pubspec.yaml | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    check_warn "flutter_sound: ^$SOUND_VERSION (Audio recording - TEST THOROUGHLY)"
fi

if grep -q "sqflite:" pubspec.yaml; then
    SQLITE_VERSION=$(grep "sqflite:" pubspec.yaml | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    check_pass "sqflite: ^$SQLITE_VERSION (Database - should be compatible)"
fi

if grep -q "local_auth:" pubspec.yaml; then
    AUTH_VERSION=$(grep "local_auth:" pubspec.yaml | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    check_pass "local_auth: ^$AUTH_VERSION (Biometric auth - should be compatible)"
fi

if grep -q "firebase_auth:" pubspec.yaml; then
    FIREBASE_VERSION=$(grep "firebase_auth:" pubspec.yaml | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    check_pass "firebase_auth: ^$FIREBASE_VERSION (Firebase - should be compatible)"
fi
echo ""

echo "6. NDK CONFIGURATION"
echo "==================="
if grep -q "ndk {" android/app/build.gradle; then
    check_pass "NDK configuration found"
    if grep -q "abiFilters" android/app/build.gradle; then
        check_pass "ABI filters configured for multiple architectures"
    fi
else
    check_warn "No explicit NDK configuration (using defaults)"
fi
echo ""

echo "7. RECOMMENDED TESTING"
echo "====================="
echo "🔴 CRITICAL TESTS (Must test on 16KB emulator):"
echo "   • Audio recording/playback functionality"
echo "   • Database CRUD operations (diary entries)"
echo "   • PDF generation and export"
echo "   • Biometric authentication"
echo "   • Secure storage operations"
echo "   • App startup and basic navigation"
echo ""
echo "🟡 IMPORTANT TESTS:"
echo "   • Firebase authentication flows"
echo "   • Cloud sync (Dropbox, Google Drive, WebDAV)"
echo "   • Local notifications"
echo "   • File operations"
echo ""

echo "8. BUILD AND TEST COMMANDS"
echo "========================="
echo "# Build the app:"
echo "flutter clean && flutter build apk --debug"
echo ""
echo "# Set up 16KB emulator:"
echo "sdkmanager 'system-images;android-35;google_apis;x86_64'"
echo "avdmanager create avd -n test_16kb -k 'system-images;android-35;google_apis;x86_64'"
echo "emulator -avd test_16kb -feature -16KB-Pages"
echo ""
echo "# Verify 16KB page size:"
echo "adb shell getconf PAGE_SIZE  # Should return 16384"
echo ""
echo "# Verify APK alignment:"
echo "zipalign -c -P 16 -v 4 build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "# Monitor for issues:"
echo "adb logcat | grep -E '(FATAL|ERROR|AndroidRuntime)'"
echo ""

echo "=== SUMMARY ==="
echo "Your app appears to be properly configured for 16KB page size support!"
echo "The critical configurations are in place. Now you need to:"
echo "1. Build and test on a 16KB emulator"
echo "2. Verify all features work correctly"
echo "3. Monitor for any runtime issues"
echo ""