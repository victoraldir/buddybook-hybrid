// lib/presentation/providers/auth_state_provider.dart

import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/subscription_service.dart';
import '../../core/constants/firebase_constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthStateProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStateProvider({
    required this.authRepository,
  }) {
    _initializeAuth();
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // Tier - read from SubscriptionService
  bool get isPremium => getIt.isRegistered<SubscriptionService>()
      ? getIt<SubscriptionService>().isPremium
      : false;
  int get maxBooks => getIt.isRegistered<SubscriptionService>()
      ? getIt<SubscriptionService>().maxBooks
      : FirebaseConstants.defaultMaxBooks;
  String get tierLabel => getIt.isRegistered<SubscriptionService>()
      ? getIt<SubscriptionService>().tierLabel
      : 'Free';

  /// Initialize auth by checking if user is already logged in
  Future<void> _initializeAuth() async {
    try {
      debugPrint('[AUTH] _initializeAuth started');
      _status = AuthStatus.initial;
      notifyListeners();

      final isLoggedIn = await authRepository.isUserLoggedIn();
      debugPrint('[AUTH] isUserLoggedIn: $isLoggedIn');
      if (isLoggedIn) {
        final result = await authRepository.getCurrentUser();
        debugPrint('[AUTH] getCurrentUser result: $result');
        result.fold(
          (failure) {
            debugPrint('[AUTH] getCurrentUser FAILURE: ${failure.message}');
            _status = AuthStatus.error;
            _errorMessage = failure.message;
          },
          (user) {
            if (user != null) {
              debugPrint(
                  '[AUTH] getCurrentUser SUCCESS: uid=${user.uid}, email=${user.email}');
              _user = user;
              _status = AuthStatus.authenticated;
              _errorMessage = null;
              _initSubscription(user.uid, user.tier);
            } else {
              debugPrint('[AUTH] getCurrentUser returned null user');
              _status = AuthStatus.unauthenticated;
              _errorMessage = null;
            }
          },
        );
      } else {
        debugPrint('[AUTH] User not logged in, setting unauthenticated');
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      }
    } catch (e, stackTrace) {
      debugPrint('[AUTH] _initializeAuth ERROR: $e');
      debugPrint('[AUTH] Stack trace: $stackTrace');
      _status = AuthStatus.error;
      _errorMessage = 'Initialization error: $e';
    }
    debugPrint('[AUTH] _initializeAuth complete, status=$_status');
    notifyListeners();
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authRepository.signUp(
        email: email,
        password: password,
        username: username,
      );

      return result.fold(
        (failure) {
          _status = AuthStatus.error;
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (user) {
          _user = user;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
          _initSubscription(user.uid, user.tier);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign up error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authRepository.signIn(
        email: email,
        password: password,
      );

      return result.fold(
        (failure) {
          _status = AuthStatus.error;
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (user) {
          _user = user;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
          _initSubscription(user.uid, user.tier);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign in error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authRepository.signInWithGoogle();

      return result.fold(
        (failure) {
          _status = AuthStatus.error;
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (user) {
          _user = user;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
          _initSubscription(user.uid, user.tier);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Google sign in error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Initialize subscription service after successful login
  void _initSubscription(String userId, String tier) {
    if (getIt.isRegistered<SubscriptionService>()) {
      final subService = getIt<SubscriptionService>();
      subService.syncTierFromUser(tier);
      subService.initialize(userId);
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authRepository.signOut();

      return result.fold(
        (failure) {
          _status = AuthStatus.error;
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (_) {
          _user = null;
          _status = AuthStatus.unauthenticated;
          _errorMessage = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign out error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword({required String email}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authRepository.resetPassword(email: email);

      return result.fold(
        (failure) {
          _status = AuthStatus.error;
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (_) {
          _status = AuthStatus.unauthenticated;
          _errorMessage = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Password reset error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
