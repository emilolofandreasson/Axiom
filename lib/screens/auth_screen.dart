import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authService,
    this.isLogin = true,
  });
  final AuthService authService;
  final bool        isLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late bool _isLogin  = widget.isLogin;
  bool  _loading      = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Enter a valid email and password (min 6 chars).');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      if (_isLogin) {
        await widget.authService.signInWithEmail(email, password);
      } else {
        await widget.authService.createAccount(email, password);
      }
      // Pop back to AuthGate which handles navigation to MainScreen.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[AuthScreen] error: $e');
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('weak password') || lower.contains('password should')) {
      return 'Password is too weak (min 6 characters).';
    }
    if (lower.contains('email') && lower.contains('valid')) {
      return 'Please enter a valid email address.';
    }
    return 'Error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlickSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Text(
                _isLogin ? 'Welcome back.' : 'Create account.',
                style: Theme.of(context).textTheme.displaySmall,
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: FlickSpacing.sm),

              Text(
                _isLogin
                    ? 'Sign in to continue your progress.'
                    : 'Start your language journey.',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: FlickColors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 80.ms),

              const SizedBox(height: FlickSpacing.xl),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ).animate().fadeIn(delay: 160.ms),

              const SizedBox(height: FlickSpacing.md),

              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
                onSubmitted: (_) => _submit(),
              ).animate().fadeIn(delay: 200.ms),

              if (_error != null) ...[
                const SizedBox(height: FlickSpacing.md),
                Container(
                  padding: const EdgeInsets.all(FlickSpacing.md),
                  decoration: BoxDecoration(
                    color: FlickColors.errorDim,
                    borderRadius: const BorderRadius.all(FlickRadius.md),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: FlickColors.error, fontSize: 14),
                  ),
                ),
              ],

              const SizedBox(height: FlickSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Sign in' : 'Create account'),
                ),
              ).animate().fadeIn(delay: 240.ms),

              const SizedBox(height: FlickSpacing.md),

              Center(
                child: TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                    style: const TextStyle(color: FlickColors.textSecondary),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
