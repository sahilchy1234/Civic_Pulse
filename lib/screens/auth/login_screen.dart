import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../utils/debug_logger.dart';
import '../../widgets/custom_button.dart';
import 'signup_screen.dart';
import '../debug/debug_screen.dart';
import '../citizen/citizen_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    DebugLogger.ui('Email sign in button pressed');
    
    if (!_formKey.currentState!.validate()) {
      DebugLogger.ui('Form validation failed', error: 'Invalid form data');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    DebugLogger.ui('Attempting sign in with email: $email');
    DebugLogger.ui('Password length: ${password.length}');

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      DebugLogger.ui('AuthService obtained, calling signInWithEmail');
      
      final result = await authService.signInWithEmail(email, password);
      
      if (!mounted) return; // Check if widget is still mounted
      
      if (result != null) {
        DebugLogger.ui('Sign in successful, user: ${result.name} (${result.email})');
        DebugLogger.ui('User role: ${result.role}');
        
        // Navigate to main screen after successful login
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CitizenMainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        DebugLogger.ui('Sign in returned null result', error: 'No user returned');
      }
    } catch (e) {
      DebugLogger.ui('Sign in failed in UI', error: e);
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Sign in failed: ${e.toString()}');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    DebugLogger.ui('Google sign in button pressed');
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      DebugLogger.ui('AuthService obtained, calling signInWithGoogle');
      
      final result = await authService.signInWithGoogle();
      
      if (!mounted) return; // Check if widget is still mounted
      
      DebugLogger.ui('Google sign in result: ${result?.name ?? 'null'} (${result?.email ?? 'null'})');
      
      if (result != null) {
        DebugLogger.ui('Google sign in successful, user: ${result.name} (${result.email})');
        DebugLogger.ui('User role: ${result.role}');
        
        // Navigate to main screen after successful Google sign in
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CitizenMainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        DebugLogger.ui('Google sign in returned null result', error: 'No user returned or cancelled');
      }
    } catch (e) {
      DebugLogger.ui('Google sign in failed in UI', error: e);
      if (mounted) {
        AppHelpers.showErrorSnackBar(context, 'Google sign in failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom - 48,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Logo and title
                const Icon(
                  Icons.location_city,
                  size: 80,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Civic Pulse',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Report civic issues in your community',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.darkGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!AppHelpers.isValidEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sign in button
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    DebugLogger.ui('Building sign in button - isLoading: ${authService.isLoading}, user: ${authService.user?.email ?? 'null'}');
                    return CustomButton(
                      text: 'Sign In',
                      onPressed: authService.isLoading ? null : _signInWithEmail,
                      isLoading: authService.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: AppTheme.darkGrey),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Google sign in button
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    DebugLogger.ui('Building Google sign in button - isLoading: ${authService.isLoading}');
                    return OutlinedButton.icon(
                      onPressed: authService.isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Sign in with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                
                // Debug button (only in debug mode)
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                        ),
                      );
                    },
                    child: const Text('🐛 Debug Info'),
                  ),
                ],
              ],
            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
