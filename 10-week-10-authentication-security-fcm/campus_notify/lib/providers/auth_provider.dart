
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  StreamSubscription<User?>? _authSubscription;

  @override
  Future<bool> build() async {
    final auth = FirebaseAuth.instance;

    // Ikuti perubahan login/logout dari Firebase.
    _authSubscription?.cancel();
    _authSubscription = auth.authStateChanges().listen((user) {
      state = AsyncData(user != null);
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return auth.currentUser != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );

      return FirebaseAuth.instance.currentUser != null;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return false;
    });
  }
}
