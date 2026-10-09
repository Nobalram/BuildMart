import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

/// Emits the raw Firebase User whenever sign-in state changes.
/// This is what makes login "persistent" — Firebase caches the
/// session on-device, so on app restart this stream immediately
/// emits the already-signed-in user without asking for OTP again.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Emits the buyer's Firestore profile document, live, for the
/// currently signed-in user. Null while logged out or before the
/// profile document has been created.
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});
