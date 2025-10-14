# Debugging Guide for CivicSense Login Issues

## Overview
This guide explains how to debug login issues in the CivicSense app. Comprehensive debugging has been added to track the authentication flow and identify where problems occur.

## Debug Features Added

### 1. Centralized Debug Logger (`lib/utils/debug_logger.dart`)
- **Purpose**: Centralized logging system for the entire app
- **Categories**: Auth, Firestore, UI, Firebase, Google, Network, Location, Notification, User Action, Lifecycle, Performance
- **Usage**: Only logs in debug mode (`kDebugMode`)

### 2. Enhanced Authentication Service (`lib/services/auth_service.dart`)
- **Email Sign In**: Detailed logging of each step
- **Email Sign Up**: Complete flow tracking
- **Google Sign In**: Step-by-step Google authentication logging
- **User Data Loading**: Firestore document access tracking
- **Auth State Changes**: Firebase auth state monitoring

### 3. Enhanced Login Screen (`lib/screens/auth/login_screen.dart`)
- **User Actions**: Button press tracking
- **Form Validation**: Input validation logging
- **Error Handling**: Detailed error reporting
- **Auth Service Integration**: Service call tracking

### 4. Debug Screen (`lib/screens/debug/debug_screen.dart`)
- **Real-time Debug Info**: Current auth state display
- **Connection Tests**: Firebase and Firestore connectivity tests
- **Manual Testing**: Test sign in/out functionality
- **Log Collection**: View all debug information in one place

### 5. Enhanced Main App (`lib/main.dart`)
- **App Initialization**: Startup process tracking
- **Firebase Setup**: Initialization monitoring
- **Auth Wrapper**: Authentication state routing logging

## How to Use Debug Features

### 1. Access Debug Screen
- **In Debug Mode**: Login screen has a "🐛 Debug Info" button
- **Manual Navigation**: Navigate to `DebugScreen` from anywhere in the app

### 2. View Debug Logs
- **Console Output**: All debug messages appear in the console/debug output
- **Debug Screen**: Real-time state information and test results
- **Timestamped**: All logs include precise timestamps

### 3. Debug Categories
- `[AUTH]`: Authentication service operations
- `[FIRESTORE]`: Database operations
- `[UI]`: User interface interactions
- `[FIREBASE]`: Firebase service calls
- `[GOOGLE]`: Google Sign-In operations
- `[LIFECYCLE]`: App lifecycle events

## Common Login Issues and Debug Points

### 1. Email/Password Sign In Fails
**Debug Points:**
- Check `[AUTH]` logs for "Starting email sign in"
- Verify `[FIREBASE]` logs for Firebase authentication
- Look for `[FIRESTORE]` logs for user data loading
- Check `[UI]` logs for form validation

**Common Issues:**
- Invalid email format
- Password too short
- Firebase authentication error
- User document missing in Firestore

### 2. Google Sign In Fails
**Debug Points:**
- Check `[GOOGLE]` logs for Google Sign-In flow
- Verify `[FIREBASE]` logs for credential exchange
- Look for `[FIRESTORE]` logs for user creation/loading

**Common Issues:**
- Google Sign-In configuration
- Network connectivity
- Firebase project configuration

### 3. User Data Loading Issues
**Debug Points:**
- Check `[FIRESTORE]` logs for document access
- Verify user document exists
- Check document data structure

**Common Issues:**
- User document missing
- Incorrect document structure
- Firestore security rules
- Network connectivity to Firestore

### 4. Authentication State Issues
**Debug Points:**
- Check `[AUTH]` logs for auth state changes
- Verify `[UI]` logs for AuthWrapper decisions
- Look for `[LIFECYCLE]` logs for app initialization

**Common Issues:**
- Firebase initialization failure
- Auth state persistence
- Provider state management

## Debug Screen Features

### 1. Current State Display
- Firebase Auth current user
- User email verification status
- AuthService user state
- Authentication status

### 2. Connection Tests
- **Firestore Test**: Write/delete test document
- **Firebase Test**: Authentication service test
- **Network Test**: Basic connectivity verification

### 3. Manual Testing
- **Test Sign In**: Attempt sign in with test credentials
- **Test Sign Out**: Verify sign out functionality
- **Refresh State**: Update current state information

## Troubleshooting Steps

### Step 1: Check Debug Logs
1. Open the app in debug mode
2. Attempt login
3. Check console output for debug messages
4. Look for error messages in logs

### Step 2: Use Debug Screen
1. Navigate to Debug Screen from login screen
2. Review current authentication state
3. Run connection tests
4. Try manual sign in/out tests

### Step 3: Verify Configuration
1. Check Firebase configuration
2. Verify Firestore security rules
3. Confirm Google Sign-In setup
4. Validate network connectivity

### Step 4: Test Individual Components
1. Test Firebase initialization
2. Test Firestore connectivity
3. Test Google Sign-In flow
4. Test user data operations

## Debug Log Examples

### Successful Login Flow
```
[LIFECYCLE] Starting app initialization
[FIREBASE] Initializing Firebase
[FIREBASE] Firebase initialized successfully
[UI] AuthWrapper rebuilding
[UI] AuthService state - isLoading: false, user: null
[UI] No user found, showing LoginScreen
[UI] Email sign in button pressed
[AUTH] Starting email sign in for: user@example.com
[FIREBASE] Calling Firebase signInWithEmailAndPassword
[FIREBASE] Firebase authentication successful
[FIRESTORE] Loading user data from Firestore for UID: abc123
[FIRESTORE] User loaded successfully: John Doe (user@example.com)
[AUTH] Email sign in completed successfully
[UI] Sign in successful, user: John Doe (user@example.com)
```

### Failed Login Flow
```
[UI] Email sign in button pressed
[AUTH] Starting email sign in for: user@example.com
[FIREBASE] Calling Firebase signInWithEmailAndPassword
[AUTH] Email sign in failed
[FIREBASE] Firebase Auth Exception - Code: user-not-found, Message: No user record
[UI] Sign in failed in UI
```

## Production Considerations

- **Debug Logs**: Only active in debug mode (`kDebugMode`)
- **Performance**: Minimal impact on production builds
- **Security**: No sensitive data logged
- **Privacy**: User data is anonymized in logs

## Next Steps

If debugging reveals specific issues:
1. Document the exact error messages
2. Note the step where failure occurs
3. Check Firebase console for additional errors
4. Verify network connectivity
5. Test with different user accounts
6. Check Firestore security rules

The comprehensive debugging system should help identify exactly where the login process is failing and provide the information needed to resolve the issue.
