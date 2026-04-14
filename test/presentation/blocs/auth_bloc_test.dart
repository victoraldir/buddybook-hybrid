import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
      'should emit [Unauthenticated] when repository returns null',
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
  });
}
