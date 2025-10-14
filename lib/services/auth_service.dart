import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/debug_logger.dart';
import 'leaderboard_service.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LeaderboardService _leaderboardService = LeaderboardService();

  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get hasFirebaseUser => _auth?.currentUser != null;

  AuthService() {
    _init();
  }

  void _init() {
    // Initialize Firebase services safely
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      
      print('AuthService: Initializing Firebase services');
      
      _auth!.authStateChanges().listen((User? firebaseUser) async {
        print('AuthService: Auth state changed - user: ${firebaseUser?.email ?? 'null'}');
        if (firebaseUser != null) {
          print('AuthService: Loading user data for: ${firebaseUser.email}');
          await _loadUserData(firebaseUser.uid);
          print('AuthService: User data loaded - user: ${_user?.email ?? 'null'}');
        } else {
          print('AuthService: No Firebase user, setting _user to null');
          _user = null;
          notifyListeners();
        }
      });
    } catch (e) {
      print('AuthService initialization failed: $e');
      // Firebase not available, app will work in offline mode
    }
  }

  Future<void> _loadUserData(String uid) async {
    if (_firestore == null) {
      print('Firestore not available, cannot load user data');
      return;
    }
    
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    while (retryCount < maxRetries) {
      try {
        final doc = await _firestore!.collection(AppConstants.usersCollection).doc(uid).get();
        
        if (doc.exists) {
          _user = UserModel.fromMap(doc.data()!);
          notifyListeners();
        } else {
          DebugLogger.firestore('User document does not exist, creating missing user document');
          await _createMissingUserDocument(uid);
        }
        return; // Success, exit retry loop
      } catch (e) {
        DebugLogger.firestore('Error loading user data: $e');
        
        // Handle PigeonUserDetails error specifically
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('List<Object?>') ||
            e.toString().contains('is not a subtype of type') ||
            e.toString().contains('type cast')) {
          DebugLogger.firestore('PigeonUserDetails error in _loadUserData - attempting recovery');
          
          // Wait for Firebase to complete operations
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Try to create user document manually
          try {
            await _createMissingUserDocument(uid);
            if (_user != null) {
              DebugLogger.firestore('Successfully recovered user data after PigeonUserDetails error');
              return;
            }
          } catch (recoveryError) {
            DebugLogger.firestore('Failed to recover user data: $recoveryError');
          }
        }
        
        retryCount++;
        
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  Future<void> _createMissingUserDocument(String uid) async {
    if (_auth == null || _firestore == null) {
      print('Firebase services not available, cannot create user document');
      return;
    }
    
    try {
      // Get Firebase user data
      final firebaseUser = _auth!.currentUser;
      if (firebaseUser == null) {
        DebugLogger.firestore('Cannot create user document - no Firebase user found', error: 'Firebase user is null');
        return;
      }

      DebugLogger.firestore('Creating missing user document for Firebase user: ${firebaseUser.email}');
      
      // Get a better name from Firebase user data
      String userName = 'User';
      if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
        userName = firebaseUser.displayName!;
      } else if (firebaseUser.email != null) {
        // Extract name from email if displayName is not available
        final emailParts = firebaseUser.email!.split('@');
        if (emailParts.isNotEmpty) {
          userName = emailParts[0].replaceAll('.', ' ').replaceAll('_', ' ');
          // Capitalize first letter of each word
          userName = userName.split(' ').map((word) => 
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
          ).join(' ');
        }
      }

      // Create user model with Firebase user data
      final userModel = UserModel(
        id: uid,
        name: userName,
        email: firebaseUser.email ?? '',
        role: AppConstants.citizenRole, // Default to citizen role
        points: 0,
        profileImageUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );

      DebugLogger.firestore('Created UserModel for missing user: ${userModel.toMap()}');

      // Save to Firestore
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toMap());

      DebugLogger.firestore('Missing user document created successfully');

      // Initialize user stats for leaderboard
      await _leaderboardService.initializeUserStats(uid);
      DebugLogger.firestore('User stats initialized successfully');
      
      // Set the user and notify listeners
      _user = userModel;
      notifyListeners();
      DebugLogger.firestore('User set in AuthService: ${_user?.name} (${_user?.email})');
      
    } catch (e) {
      DebugLogger.firestore('Error creating missing user document', error: e);
    }
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    if (_auth == null) {
      print('Firebase Auth not available');
      return null;
    }
    
    DebugLogger.auth('Starting email sign in for: $email');
    try {
      _isLoading = true;
      notifyListeners();
      DebugLogger.auth('Set loading to true');

      DebugLogger.firebase('Calling Firebase signInWithEmailAndPassword');
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      DebugLogger.firebase('Firebase authentication successful');
      DebugLogger.firebase('Credential user UID: ${credential.user?.uid}');
      DebugLogger.firebase('Credential user email: ${credential.user?.email}');

      if (credential.user != null) {
        DebugLogger.auth('Loading user data after successful authentication');
        try {
          await _loadUserData(credential.user!.uid);
          DebugLogger.auth('Email sign in completed successfully');
          return _user;
        } catch (loadError) {
          DebugLogger.auth('Error loading user data after authentication: $loadError');
          
          // Handle PigeonUserDetails error in user loading
          if (loadError.toString().contains('PigeonUserDetails') || 
              loadError.toString().contains('List<Object?>') ||
              loadError.toString().contains('is not a subtype of type') ||
              loadError.toString().contains('type cast')) {
            DebugLogger.auth('PigeonUserDetails error in user loading - attempting recovery');
            
            // Wait for Firebase to complete operations
            await Future.delayed(const Duration(milliseconds: 1000));
            
            // Try to create user document manually
            try {
              await _createMissingUserDocument(credential.user!.uid);
              if (_user != null) {
                DebugLogger.auth('Successfully recovered user data after PigeonUserDetails error');
                return _user;
              }
            } catch (recoveryError) {
              DebugLogger.auth('Failed to recover user data: $recoveryError');
            }
          }
          
          // If we still don't have user data, return null
          return null;
        }
      }
      DebugLogger.auth('Credential user is null', error: 'No user returned from Firebase');
      return null;
    } catch (e) {
      DebugLogger.auth('Email sign in failed', error: e);
      if (e is FirebaseAuthException) {
        DebugLogger.firebase('Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
      }
      
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('is not a subtype of type') ||
          e.toString().contains('type cast')) {
        DebugLogger.auth('PigeonUserDetails/Type casting error detected - this is a known Firebase plugin issue');
        DebugLogger.auth('The user was likely created successfully despite this error');
        
        // Wait a moment for Firebase to complete the user creation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to get the user data from Firebase Auth directly
        if (_auth?.currentUser != null) {
          DebugLogger.auth('Attempting to recover user data after PigeonUserDetails error');
          await _loadUserData(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.auth('Successfully recovered user data after PigeonUserDetails error');
            return _user;
          }
        }
        
        // If we still don't have user data, try to create it manually
        if (_auth?.currentUser != null && _user == null) {
          DebugLogger.auth('Creating user document manually after PigeonUserDetails error');
          await _createMissingUserDocument(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.auth('Successfully created user document after PigeonUserDetails error');
            return _user;
          }
        }
        
        // Don't rethrow this specific error, as the user creation might have succeeded
        return null;
      }
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      DebugLogger.auth('Set loading to false');
    }
  }

  Future<UserModel?> signUpWithEmail(
    String email, 
    String password, 
    String name, 
    String role
  ) async {
    DebugLogger.auth('Starting email sign up for: $email with role: $role');
    try {
      _isLoading = true;
      notifyListeners();
      DebugLogger.auth('Set loading to true');

      DebugLogger.firebase('Calling Firebase createUserWithEmailAndPassword');
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      DebugLogger.firebase('Firebase user creation successful');
      DebugLogger.firebase('Credential user UID: ${credential.user?.uid}');

      if (credential.user != null) {
        final userModel = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          role: role,
          points: 0,
          createdAt: DateTime.now(),
        );
        DebugLogger.auth('Created UserModel: ${userModel.toMap()}');

        DebugLogger.firestore('Saving user to Firestore');
        await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toMap());
        DebugLogger.firestore('User saved to Firestore successfully');

        // Initialize user stats for leaderboard
        await _leaderboardService.initializeUserStats(credential.user!.uid);
        DebugLogger.firestore('User stats initialized successfully');

        _user = userModel;
        notifyListeners();
        DebugLogger.auth('Email sign up completed successfully');
        return _user;
      }
      DebugLogger.auth('Credential user is null', error: 'No user returned from Firebase');
      return null;
    } catch (e) {
      DebugLogger.auth('Email sign up failed', error: e);
      if (e is FirebaseAuthException) {
        DebugLogger.firebase('Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
      }
      
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('is not a subtype of type') ||
          e.toString().contains('type cast')) {
        DebugLogger.auth('PigeonUserDetails/Type casting error detected - this is a known Firebase plugin issue');
        DebugLogger.auth('The user was likely created successfully despite this error');
        
        // Wait a moment for Firebase to complete the user creation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to get the user data from Firebase Auth directly
        if (_auth?.currentUser != null) {
          DebugLogger.auth('Attempting to recover user data after PigeonUserDetails error');
          await _loadUserData(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.auth('Successfully recovered user data after PigeonUserDetails error');
            return _user;
          }
        }
        
        // If we still don't have user data, try to create it manually
        if (_auth?.currentUser != null && _user == null) {
          DebugLogger.auth('Creating user document manually after PigeonUserDetails error');
          await _createMissingUserDocument(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.auth('Successfully created user document after PigeonUserDetails error');
            return _user;
          }
        }
        
        // Don't rethrow this specific error, as the user creation might have succeeded
        return null;
      }
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      DebugLogger.auth('Set loading to false');
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    DebugLogger.google('Starting Google sign in');
    try {
      _isLoading = true;
      notifyListeners();
      DebugLogger.google('Set loading to true');

      DebugLogger.google('Calling GoogleSignIn.signIn()');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      DebugLogger.google('Google sign in result: ${googleUser?.email ?? 'null'}');
      if (googleUser == null) {
        DebugLogger.google('Google sign in cancelled by user');
        return null;
      }

      DebugLogger.google('Getting Google authentication');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      DebugLogger.google('Access token available: ${googleAuth.accessToken != null}');
      DebugLogger.google('ID token available: ${googleAuth.idToken != null}');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      DebugLogger.google('Created Google credential');

      DebugLogger.google('Signing in with Google credential to Firebase');
      final userCredential = await _auth!.signInWithCredential(credential);
      DebugLogger.firebase('Firebase authentication with Google successful');
      DebugLogger.firebase('User UID: ${userCredential.user?.uid}');
      DebugLogger.firebase('User email: ${userCredential.user?.email}');
      
      if (userCredential.user != null) {
        DebugLogger.google('Checking if user exists in Firestore');
        final doc = await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .get();
        DebugLogger.google('User document exists: ${doc.exists}');

        if (!doc.exists) {
          DebugLogger.google('Creating new user in Firestore');
          // Get a better name from Google user data
          String userName = 'User';
          if (userCredential.user!.displayName != null && userCredential.user!.displayName!.isNotEmpty) {
            userName = userCredential.user!.displayName!;
          } else if (userCredential.user!.email != null) {
            // Extract name from email if displayName is not available
            final emailParts = userCredential.user!.email!.split('@');
            if (emailParts.isNotEmpty) {
              userName = emailParts[0].replaceAll('.', ' ').replaceAll('_', ' ');
              // Capitalize first letter of each word
              userName = userName.split(' ').map((word) => 
                word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
              ).join(' ');
            }
          }

          final userModel = UserModel(
            id: userCredential.user!.uid,
            name: userName,
            email: userCredential.user!.email ?? '',
            role: AppConstants.citizenRole, // Default to citizen
            points: 0,
            profileImageUrl: userCredential.user!.photoURL,
            createdAt: DateTime.now(),
          );
          DebugLogger.google('Created UserModel for Google user: ${userModel.toMap()}');

          await _firestore!
              .collection(AppConstants.usersCollection)
              .doc(userCredential.user!.uid)
              .set(userModel.toMap());
          DebugLogger.google('New user saved to Firestore');

          _user = userModel;
        } else {
          DebugLogger.google('Loading existing user data');
          try {
            await _loadUserData(userCredential.user!.uid);
            DebugLogger.google('User data loaded successfully: ${_user?.name} (${_user?.email})');
          } catch (loadError) {
            DebugLogger.google('Error loading user data after Google authentication: $loadError');
            
            // Handle PigeonUserDetails error in user loading
            if (loadError.toString().contains('PigeonUserDetails') || 
                loadError.toString().contains('List<Object?>') ||
                loadError.toString().contains('is not a subtype of type') ||
                loadError.toString().contains('type cast')) {
              DebugLogger.google('PigeonUserDetails error in Google user loading - attempting recovery');
              
              // Wait for Firebase to complete operations
              await Future.delayed(const Duration(milliseconds: 1000));
              
              // Try to create user document manually
              try {
                await _createMissingUserDocument(userCredential.user!.uid);
                if (_user != null) {
                  DebugLogger.google('Successfully recovered user data after PigeonUserDetails error');
                }
              } catch (recoveryError) {
                DebugLogger.google('Failed to recover user data: $recoveryError');
              }
            }
          }
        }
        
        notifyListeners();
        DebugLogger.google('Google sign in completed successfully');
        DebugLogger.google('Returning user from Google sign in: ${_user?.name} (${_user?.email})');
        return _user;
      }
      DebugLogger.google('User credential user is null', error: 'No user returned from Firebase');
      return null;
    } catch (e) {
      DebugLogger.google('Google sign in failed', error: e);
      if (e is FirebaseAuthException) {
        DebugLogger.firebase('Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
      }
      
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('is not a subtype of type') ||
          e.toString().contains('type cast')) {
        DebugLogger.google('PigeonUserDetails/Type casting error detected - this is a known Firebase plugin issue');
        DebugLogger.google('The user was likely created successfully despite this error');
        
        // Wait a moment for Firebase to complete the user creation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to get the user data from Firebase Auth directly
        if (_auth?.currentUser != null) {
          DebugLogger.google('Attempting to recover user data after PigeonUserDetails error');
          await _loadUserData(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.google('Successfully recovered user data after PigeonUserDetails error');
            DebugLogger.google('Returning user: ${_user!.name} (${_user!.email})');
            return _user;
          } else {
            DebugLogger.google('User data is still null after recovery attempt');
          }
        }
        
        // If we still don't have user data, try to create it manually
        if (_auth?.currentUser != null && _user == null) {
          DebugLogger.google('Creating user document manually after PigeonUserDetails error');
          await _createMissingUserDocument(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.google('Successfully created user document after PigeonUserDetails error');
            return _user;
          }
        }
        
        // Final attempt to get user data
        if (_auth?.currentUser != null) {
          DebugLogger.google('Final attempt to get user data from Firebase Auth');
          await _loadUserData(_auth!.currentUser!.uid);
          if (_user != null) {
            DebugLogger.google('Successfully got user data in final attempt');
            DebugLogger.google('Final attempt returning user: ${_user!.name} (${_user!.email})');
            return _user;
          } else {
            DebugLogger.google('User is still null after final attempt');
          }
        }
        
        // Don't rethrow this specific error, as the user creation might have succeeded
        return null;
      }
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      DebugLogger.google('Set loading to false');
    }
  }

  Future<void> signOut() async {
    DebugLogger.auth('Starting sign out');
    try {
      DebugLogger.auth('Signing out from Firebase and Google');
      await Future.wait([
        _auth!.signOut(),
        _googleSignIn.signOut(),
      ]);
      DebugLogger.auth('Sign out successful');
      _user = null;
      notifyListeners();
    } catch (e) {
      DebugLogger.auth('Sign out error', error: e);
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
  }) async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = _user!.copyWith(
        name: name,
        profileImageUrl: profileImageUrl,
      );

      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(_user!.id)
          .update(updatedUser.toMap());

      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserPoints(int points) async {
    if (_user == null) return;

    try {
      final updatedUser = _user!.copyWith(points: _user!.points + points);
      
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(_user!.id)
          .update({'points': updatedUser.points});

      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Update points error: $e');
    }
  }
}
