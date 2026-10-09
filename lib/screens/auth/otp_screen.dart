import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_mode.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import 'profile_setup_screen.dart';
import 'login_screen.dart';
import '../home/main_shell.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final AuthMode mode;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.mode,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  late String _verificationId;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;

  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorText = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      final credential = await ref
          .read(authServiceProvider)
          .verifyOtp(
            verificationId: _verificationId,
            smsCode: _otpController.text.trim(),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final uid = credential.user!.uid;
      final profile = await ref.read(userRepositoryProvider).getUser(uid);

      if (!mounted) return;

      if (widget.mode == AuthMode.login) {
        if (profile == null) {
          // Tried to log in with a number that has no account yet.
          setState(() => _isVerifying = false);
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Account Found'),
              content: const Text(
                'There is no account registered with this number. Would you like to create one?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen(mode: AuthMode.signup),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Create Account'),
                ),
              ],
            ),
          );
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        // Signup mode
        if (profile != null) {
          // Tried to sign up with a number that's already registered.
          setState(() => _isVerifying = false);
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Already Exists'),
              content: const Text(
                'An account with this number already exists. Please log in instead.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(mode: AuthMode.login),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifying = false;
        _errorText = e.code == 'invalid-verification-code'
            ? 'Incorrect OTP. Please try again.'
            : (e.message ?? 'Verification failed.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = 'Something went wrong: $e';
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorText = null;
    });

    await ref
        .read(authServiceProvider)
        .sendOtp(
          phoneNumber: widget.phoneNumber,
          onCodeSent: (verificationId) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _isResending = false;
            });
            _startTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP resent successfully')),
            );
          },
          onFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            setState(() {
              _isResending = false;
              _errorText = e.message ?? 'Failed to resend OTP.';
            });
          },
          onAutoVerified: (credential) {
            if (!mounted) return;
            setState(() => _isResending = false);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enter verification code',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sent to ${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                ),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend OTP in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Resend OTP'),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Verify & Continue',
                type: AppButtonType.gradient,
                isLoading: _isVerifying,
                onPressed: _verifyOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
