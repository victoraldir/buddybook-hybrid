import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:buddybook_flutter/core/errors/failures.dart';
import 'package:buddybook_flutter/core/services/subscription_service.dart';
import 'package:buddybook_flutter/domain/entities/user.dart';
import 'package:buddybook_flutter/domain/repositories/auth_repository.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_state.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository, SubscriptionService])
void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockSubscriptionService mockSubscriptionService;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSubscriptionService = MockSubscriptionService();
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      subscriptionService: mockSubscriptionService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const tUser = User(
    uid: '123',
    email: 'test@test.com',
    username: 'testuser',
  );

  const tFailure = AuthFailure(message: 'Something went wrong');

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [Authenticated] when repository returns a user',
      build: () {
        when(mockAuthRepository.isUserLoggedIn()).thenAnswer((_) async => true);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const Authenticated(user: tUser),
      ],
      verify: (_) {
        verify(mockSubscriptionService.syncTierFromUser(any)).called(1);
        verify(mockSubscriptionService.initialize(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [Unauthenticated] when repository returns null user',
      build: () {
        when(mockAuthRepository.isUserLoggedIn()).thenAnswer((_) async => true);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [Unauthenticated] when user is not logged in',
      build: () {
        when(mockAuthRepository.isUserLoggedIn())
            .thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthError] when getCurrentUser returns a failure',
      build: () {
        when(mockAuthRepository.isUserLoggedIn()).thenAnswer((_) async => true);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Left(tFailure));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthError(message: 'Something went wrong'),
      ],
    );
  });

  group('AuthSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] on successful sign in',
      build: () {
        when(mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@test.com',
        password: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        const Authenticated(user: tUser),
      ],
      verify: (_) {
        verify(mockSubscriptionService.syncTierFromUser(any)).called(1);
        verify(mockSubscriptionService.initialize(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] on sign in failure',
      build: () {
        when(mockAuthRepository.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => const Left(tFailure));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@test.com',
        password: 'wrong',
      )),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'Something went wrong'),
      ],
    );
  });

  group('AuthSignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] on successful sign up',
      build: () {
        when(mockAuthRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          username: anyNamed('username'),
        )).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'test@test.com',
        password: 'password123',
        username: 'testuser',
      )),
      expect: () => [
        AuthLoading(),
        const Authenticated(user: tUser),
      ],
      verify: (_) {
        verify(mockSubscriptionService.syncTierFromUser(any)).called(1);
        verify(mockSubscriptionService.initialize(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] on sign up failure',
      build: () {
        when(mockAuthRepository.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          username: anyNamed('username'),
        )).thenAnswer(
            (_) async => const Left(AuthFailure(message: 'Email in use')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'taken@test.com',
        password: 'password123',
        username: 'testuser',
      )),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'Email in use'),
      ],
    );
  });

  group('AuthSignInWithGoogleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] on successful Google sign in',
      build: () {
        when(mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [
        AuthLoading(),
        const Authenticated(user: tUser),
      ],
      verify: (_) {
        verify(mockSubscriptionService.syncTierFromUser(any)).called(1);
        verify(mockSubscriptionService.initialize(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] on Google sign in failure',
      build: () {
        when(mockAuthRepository.signInWithGoogle()).thenAnswer((_) async =>
            const Left(AuthFailure(message: 'Google sign in cancelled')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'Google sign in cancelled'),
      ],
    );
  });

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Unauthenticated] on successful sign out',
      build: () {
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] on sign out failure',
      build: () {
        when(mockAuthRepository.signOut()).thenAnswer(
            (_) async => const Left(AuthFailure(message: 'Sign out failed')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'Sign out failed'),
      ],
    );
  });

  group('AuthPasswordResetRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Unauthenticated] on successful password reset',
      build: () {
        when(mockAuthRepository.resetPassword(email: anyNamed('email')))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordResetRequested(email: 'test@test.com')),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] on password reset failure',
      build: () {
        when(mockAuthRepository.resetPassword(email: anyNamed('email')))
            .thenAnswer((_) async =>
                const Left(AuthFailure(message: 'User not found')));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordResetRequested(email: 'unknown@test.com')),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'User not found'),
      ],
    );
  });
}
