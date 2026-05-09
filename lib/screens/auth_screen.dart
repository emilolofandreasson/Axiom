import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _isLogin      = true;
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
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) return 'Password is too weak.';
    return 'Something went wrong. Please try again.';
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
