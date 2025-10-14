# Google Sign-In Setup Fix

## Current Issue
Google Sign-In is failing with error code 10 (DEVELOPER_ERROR) because the OAuth client configuration doesn't match the app's package name.

## Solution Steps

### Step 1: Get Your App's SHA-1 Fingerprint
Run this command in your project root:

```bash
# For debug keystore (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (if you have one)
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

Look for the SHA-1 fingerprint in the output.

### Step 2: Update Google Cloud Console

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project**: civicsense-cca11
3. **Navigate to APIs & Services → Credentials**
4. **Find your OAuth 2.0 Client ID** for Android
5. **Edit the OAuth client** and ensure:
   - **Package name**: `com.example.civicsense`
   - **SHA-1 certificate fingerprint**: Add the SHA-1 from Step 1
6. **Save the changes**

### Step 3: Download Updated google-services.json

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: civicsense-cca11
3. **Go to Project Settings** (gear icon)
4. **Under "Your apps"**, find your Android app
5. **Download the google-services.json** file
6. **Replace** `android/app/google-services.json` with the new file

### Step 4: Verify Configuration

Your `android/app/google-services.json` should have:
```json
{
  "client_info": {
    "package_name": "com.example.civicsense"
  }
}
```

### Step 5: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative Quick Fix

If you want to test quickly, you can temporarily disable Google Sign-In:

1. Comment out the Google Sign-In button in `lib/screens/auth/login_screen.dart`
2. Test email sign-up/sign-in first
3. Fix Google Sign-In configuration later

## Expected Result

After following these steps, Google Sign-In should work without error code 10.
