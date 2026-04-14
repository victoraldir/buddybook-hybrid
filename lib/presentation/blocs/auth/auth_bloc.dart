// lib/presentation/blocs/auth/auth_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/services/subscription_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SubscriptionService subscriptionService;

  AuthBloc({
    required this.authRepository,
    required this.subscriptionService,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignInWithGoogleRequested>(_onAuthSignInWithGoogleRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await authRepository.isUserLoggedIn();
    if (isLoggedIn) {
      final result = await authRepository.getCurrentUser();
      result.fold(
        (failure) => emit(AuthError(message: failure.message)),
        (user) {
          if (user != null) {
            _initSubscription(user.uid, user.tier);
            emit(Authenticated(user: user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.signUp(
      email: event.email,
      password: event.password,
      username: event.username,
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        _initSubscription(user.uid, user.tier);
        emit(Authenticated(user: user));
      },
    );
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.signIn(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        _initSubscription(user.uid, user.tier);
        emit(Authenticated(user: user));
      },
    );
  }

  Future<void> _onAuthSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        _initSubscription(user.uid, user.tier);
        emit(Authenticated(user: user));
      },
    );
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.signOut();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.resetPassword(email: event.email);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(Unauthenticated()), // Redirect to login after reset usually
    );
  }

  void _initSubscription(String userId, String tier) {
    subscriptionService.syncTierFromUser(tier);
    subscriptionService.initialize(userId);
  }
}
