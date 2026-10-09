import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth's phone-number sign-in flow.
/// Keeping all Firebase Auth calls in ONE place makes it easy to
/// swap providers later or add error-logging in one spot.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Starts phone verification. Firebase will either:
  /// - auto-detect the OTP (android instant verification) -> [onAutoVerified]
  /// - send the OTP and call [onCodeSent] with a verificationId
  /// - fail immediately -> [onFailed]
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        onAutoVerified(result);
      },
      verificationFailed: onFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
