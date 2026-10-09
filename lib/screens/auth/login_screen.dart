import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_mode.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import 'otp_screen.dart';
import '../home/main_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final AuthMode mode;

  const LoginScreen({super.key, required this.mode});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorText;

  bool get _isSignup => widget.mode == AuthMode.signup;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your phone number';
    if (value.trim().length != 10) return 'Enter a valid 10-digit number';
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final fullNumber = '+91${_phoneController.text.trim()}';
    final authService = ref.read(authServiceProvider);

    await authService.sendOtp(
      phoneNumber: fullNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: fullNumber,
              mode: widget.mode,
            ),
          ),
        );
      },
      onFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorText = e.message ?? 'Failed to send OTP. Please try again.';
        });
      },
      onAutoVerified: (credential) {
        // Auto-verification skips the OTP screen entirely (Android
        // instant verification), so we must do the same mode-aware
        // profile check here that OtpScreen does.
        if (!mounted) return;
        setState(() => _isLoading = false);
        _handleVerifiedUser(credential.user!.uid);
      },
    );
  }

  Future<void> _handleVerifiedUser(String uid) async {
    final profile = await ref.read(userRepositoryProvider).getUser(uid);
    if (!mounted) return;

    if (widget.mode == AuthMode.login) {
      if (profile == null) {
        // No account exists for this number — send them to sign up.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(mode: AuthMode.signup),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No account found for this number. Please create one.',
            ),
          ),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    }
    // Signup-mode auto-verify handling is covered inside OtpScreen's
    // equivalent path — auto-verify during signup is rare in practice
    // since new numbers almost always require manual SMS code entry.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSignup
                                ? Icons.person_add_alt_outlined
                                : Icons.login,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _isSignup ? 'Create Your Account' : 'Welcome Back',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isSignup
                                      ? 'Enter your mobile number'
                                      : 'Enter your registered number',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  "We'll send you a One-Time Password (OTP) to verify.",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: _validatePhone,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    hintText: '98765 43210',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '🇮🇳 +91',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 0,
                                    ),
                                  ),
                                ),
                                if (_errorText != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _errorText!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                AppButton(
                                  label: 'Send OTP',
                                  type: AppButtonType.gradient,
                                  isLoading: _isLoading,
                                  onPressed: _sendOtp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
