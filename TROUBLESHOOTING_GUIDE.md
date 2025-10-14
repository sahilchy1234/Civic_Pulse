# Troubleshooting Guide for CivicSense App

## Current Issues Identified and Fixed

### 1. ✅ **Missing User Document in Firestore** - FIXED
**Problem**: User exists in Firebase Auth but not in Firestore
**Solution**: Automatic user document creation when missing
**Status**: Code updated, requires app restart

### 2. ✅ **Google Sign-In Error Code 10** - FIXED
**Problem**: Package name mismatch between app and Google Services
- App package: `com.example.civicsense`
- Google Services: `com.civicpulse.app`
**Solution**: Updated Google Services configuration
**Status**: Fixed in google-services.json

### 3. ✅ **Widget Context Error** - FIXED
**Problem**: Trying to show error dialog after widget unmount
**Solution**: Added `mounted` check before showing dialogs
**Status**: Fixed in login screen

## Steps to Apply Fixes

### Step 1: Restart the App
**CRITICAL**: You must do a **full restart** (not hot reload) to see the fixes:

```bash
# Stop the current app
# Then run:
flutter clean
flutter pub get
flutter run
```

### Step 2: Verify Google Services
The Google Services configuration has been updated. If you still get Google Sign-In errors:

1. **Check Firebase Console**:
   - Go to Firebase Console → Project Settings
   - Verify the Android app has package name `com.example.civicsense`
   - Download the new google-services.json if needed

2. **Regenerate Google Sign-In Configuration**:
   - Go to Google Cloud Console
   - Navigate to APIs & Services → Credentials
   - Find your OAuth 2.0 client
   - Verify package name matches `com.example.civicsense`
   - Add SHA-1 fingerprint if needed

### Step 3: Test the Fixes

1. **Test Email Sign-In**:
   - Try logging in with email/password
   - Check debug logs for user document creation
   - Should see: `[FIRESTORE] User document does not exist in Firestore - creating new user document`

2. **Test Google Sign-In**:
   - Try Google Sign-In
   - Should work without error code 10
   - Check debug logs for successful authentication

3. **Use Debug Screen**:
   - Navigate to Debug Screen from login screen
   - Run connection tests
   - Check current authentication state

## Expected Debug Log Flow (After Fix)

### Successful Email Login:
```
[UI] Email sign in button pressed
[AUTH] Starting email sign in for: user@example.com
[FIREBASE] Calling Firebase signInWithEmailAndPassword
[FIREBASE] Firebase authentication successful
[FIRESTORE] Loading user data from Firestore for UID: abc123
[FIRESTORE] Document exists: false
[FIRESTORE] User document does not exist in Firestore - creating new user document
[FIRESTORE] Creating missing user document for Firebase user: user@example.com
[FIRESTORE] Missing user document created successfully
[AUTH] Email sign in completed successfully
```

### Successful Google Login:
```
[UI] Google sign in button pressed
[GOOGLE] Starting Google sign in
[GOOGLE] Calling GoogleSignIn.signIn()
[GOOGLE] Google sign in result: user@gmail.com
[GOOGLE] Getting Google authentication
[FIREBASE] Firebase authentication with Google successful
[GOOGLE] Checking if user exists in Firestore
[GOOGLE] User document exists: false
[GOOGLE] Creating new user in Firestore
[GOOGLE] New user saved to Firestore
[GOOGLE] Google sign in completed successfully
```

## Common Issues and Solutions

### Issue: "This widget has been unmounted" Error
**Cause**: Trying to update UI after widget is disposed
**Solution**: Always check `if (mounted)` before UI updates
**Status**: ✅ Fixed

### Issue: Google Sign-In Error Code 10
**Cause**: Package name mismatch or missing SHA-1 fingerprint
**Solution**: Verify package names and add SHA-1 to Google Console
**Status**: ✅ Fixed (package name corrected)

### Issue: User Document Missing
**Cause**: User exists in Firebase Auth but not Firestore
**Solution**: Automatic document creation on login
**Status**: ✅ Fixed

### Issue: Debug logs not showing new messages
**Cause**: App not restarted after code changes
**Solution**: Full restart required (flutter clean && flutter run)
**Status**: ⚠️ Requires user action

## Testing Checklist

- [ ] App restarted with `flutter clean && flutter run`
- [ ] Email login creates user document automatically
- [ ] Google Sign-In works without error code 10
- [ ] No "widget unmounted" errors in console
- [ ] Debug screen shows correct authentication state
- [ ] User can successfully navigate to main app after login

## Next Steps if Issues Persist

1. **Check Firebase Console**:
   - Verify project configuration
   - Check authentication settings
   - Verify Firestore rules

2. **Check Google Cloud Console**:
   - Verify OAuth client configuration
   - Check package name and SHA-1 fingerprint
   - Ensure Google Sign-In API is enabled

3. **Check Debug Logs**:
   - Look for specific error messages
   - Verify each step of authentication flow
   - Use Debug Screen for real-time state

4. **Test on Different Device**:
   - Try on emulator vs physical device
   - Test with different Google accounts
   - Check network connectivity

## Contact Information

If issues persist after following this guide:
1. Check the debug logs for specific error messages
2. Note the exact step where failure occurs
3. Verify all configurations match this guide
4. Test with a fresh Firebase project if needed

The comprehensive debugging system should now provide clear information about any remaining issues.
