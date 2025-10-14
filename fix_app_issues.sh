#!/bin/bash

echo "🔧 Fixing CivicSense App Issues..."

echo "📱 Step 1: Cleaning project..."
flutter clean

echo "📦 Step 2: Getting dependencies..."
flutter pub get

echo "🔑 Step 3: Getting debug keystore SHA-1..."
echo "Run this command to get your SHA-1 fingerprint:"
echo "keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
echo ""
echo "Copy the SHA-1 fingerprint and add it to your Google Cloud Console OAuth client."
echo ""

echo "🚀 Step 4: Running app..."
flutter run

echo "✅ App should now be running with fixes applied!"
echo ""
echo "📋 Next steps:"
echo "1. Test email sign-up/sign-in"
echo "2. Fix Google Sign-In configuration in Google Cloud Console"
echo "3. Check debug logs for any remaining issues"
