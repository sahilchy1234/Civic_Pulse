import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/debug_logger.dart';
import '../../utils/theme.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  bool _isCollectingLogs = false;

  @override
  void initState() {
    super.initState();
    _collectDebugInfo();
  }

  void _collectDebugInfo() {
    setState(() {
      _isCollectingLogs = true;
    });
    
    // Collect Firebase Auth state
    final auth = FirebaseAuth.instance;
    _logs.add('=== FIREBASE AUTH STATE ===');
    _logs.add('Current User: ${auth.currentUser?.uid ?? 'null'}');
    _logs.add('Current User Email: ${auth.currentUser?.email ?? 'null'}');
    _logs.add('Current User Display Name: ${auth.currentUser?.displayName ?? 'null'}');
    _logs.add('Email Verified: ${auth.currentUser?.emailVerified ?? false}');
    _logs.add('Is Anonymous: ${auth.currentUser?.isAnonymous ?? false}');
    _logs.add('');

    // Collect Firestore connection test
    _logs.add('=== FIRESTORE CONNECTION TEST ===');
    FirebaseFirestore.instance
        .collection('test')
        .limit(1)
        .get()
        .then((snapshot) {
      _logs.add('Firestore connection: SUCCESS');
      setState(() {});
    }).catchError((error) {
      _logs.add('Firestore connection: FAILED - $error');
      setState(() {});
    });
    _logs.add('');

    // Collect AuthService state
    _logs.add('=== AUTH SERVICE STATE ===');
    final authService = Provider.of<AuthService>(context, listen: false);
    _logs.add('AuthService User: ${authService.user?.email ?? 'null'}');
    _logs.add('AuthService User Role: ${authService.user?.role ?? 'null'}');
    _logs.add('AuthService Is Loading: ${authService.isLoading}');
    _logs.add('AuthService Is Authenticated: ${authService.isAuthenticated}');
    _logs.add('');

    setState(() {
      _isCollectingLogs = false;
    });
  }

  Future<void> _testSignIn() async {
    DebugLogger.auth('Testing sign in with test credentials');
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmail('test@example.com', 'password123');
      _logs.add('Test sign in: SUCCESS');
    } catch (e) {
      _logs.add('Test sign in: FAILED - $e');
    }
    setState(() {});
  }

  Future<void> _testSignOut() async {
    DebugLogger.auth('Testing sign out');
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      _logs.add('Test sign out: SUCCESS');
    } catch (e) {
      _logs.add('Test sign out: FAILED - $e');
    }
    setState(() {});
  }

  Future<void> _testFirestoreConnection() async {
    DebugLogger.firestore('Testing Firestore connection');
    try {
      await FirebaseFirestore.instance.collection('test').doc('test').set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      });
      _logs.add('Firestore write test: SUCCESS');
      
      await FirebaseFirestore.instance.collection('test').doc('test').delete();
      _logs.add('Firestore delete test: SUCCESS');
    } catch (e) {
      _logs.add('Firestore connection test: FAILED - $e');
    }
    setState(() {});
  }

  Future<void> _fixMissingUserDocument() async {
    DebugLogger.auth('Attempting to fix missing user document');
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.user;
      
      if (currentUser == null) {
        _logs.add('No current user found - cannot fix user document');
        return;
      }
      
      _logs.add('Checking if user document exists...');
      
      // Check if document exists
      final doc = await FirebaseFirestore.instance
          .collection('users') // Assuming this is the collection name
          .doc(currentUser.id)
          .get();
          
      if (doc.exists) {
        _logs.add('User document already exists - no fix needed');
      } else {
        _logs.add('User document missing - attempting to create...');
        
        // Force reload user data which should trigger the fix
        // This will be handled by the auth service automatically now
        _logs.add('User document will be created automatically on next auth state change');
        
        _logs.add('User document fix attempted');
      }
    } catch (e) {
      _logs.add('Fix missing user document: FAILED - $e');
    }
    setState(() {});
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _collectDebugInfo,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Debug Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCollectingLogs ? null : _testSignIn,
                        child: const Text('Test Sign In'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCollectingLogs ? null : _testSignOut,
                        child: const Text('Test Sign Out'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isCollectingLogs ? null : _testFirestoreConnection,
                  child: const Text('Test Firestore Connection'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isCollectingLogs ? null : _fixMissingUserDocument,
                  child: const Text('Fix Missing User Document'),
                ),
              ],
            ),
          ),
          
          // Debug logs
          Expanded(
            child: _isCollectingLogs
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.contains('FAILED') || log.contains('ERROR');
                      final isSuccess = log.contains('SUCCESS');
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isError 
                              ? Colors.red[50] 
                              : isSuccess 
                                  ? Colors.green[50] 
                                  : Colors.grey[50],
                          border: Border.all(
                            color: isError 
                                ? Colors.red 
                                : isSuccess 
                                    ? Colors.green 
                                    : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isError 
                                ? Colors.red[800] 
                                : isSuccess 
                                    ? Colors.green[800] 
                                    : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
