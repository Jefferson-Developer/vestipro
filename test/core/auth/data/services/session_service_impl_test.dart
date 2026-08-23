import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/data/datasources/secure_session_store.dart';
import 'package:vestipro/core/auth/data/services/session_service_impl.dart';
import 'package:vestipro/core/auth/domain/entities/session_user.dart';
import 'package:vestipro/core/auth/domain/repositories/auth_repository.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureSessionStore extends Mock implements SecureSessionStore {}

void main() {
  group('SessionServiceImpl', () {
    late _MockAuthRepository authRepository;
    late _MockSecureSessionStore secureSessionStore;
    late SessionServiceImpl service;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      authRepository = _MockAuthRepository();
      secureSessionStore = _MockSecureSessionStore();
      service = SessionServiceImpl(
        authRepository: authRepository,
        secureSessionStore: secureSessionStore,
      );

      when(
        () => secureSessionStore.persistSignedInUserId(any()),
      ).thenAnswer((_) async {});
      when(() => secureSessionStore.clear()).thenAnswer((_) async {});
    });

    test('merely constructing the service never touches SecureSessionStore '
        '(no background listener/eager I/O on DI resolution)', () {
      // Regression guard: an earlier design subscribed to
      // `authStateChanges` from the constructor and wrote to
      // `SecureSessionStore` on every emission — which meant simply
      // resolving `SessionService` through DI in a widget test that
      // boots the real app (nobody signed in) hung forever on the real
      // `flutter_secure_storage` platform channel. Every write must be
      // tied to an explicit call instead (`logout`, `ensureSessionIsActive`).
      verifyNever(() => secureSessionStore.persistSignedInUserId(any()));
      verifyNever(() => secureSessionStore.clear());
    });

    group('currentUser / sessionChanges', () {
      test('currentUser mirrors AuthRepository.currentUser', () {
        when(() => authRepository.currentUser).thenReturn(signedInUser);

        expect(service.currentUser, signedInUser);
      });

      test('sessionChanges mirrors AuthRepository.authStateChanges', () async {
        when(
          () => authRepository.authStateChanges,
        ).thenAnswer((_) => Stream.value(signedInUser));

        expect(await service.sessionChanges.first, signedInUser);
      });
    });

    group('logout', () {
      test(
        'signs out through AuthRepository and clears the secure store',
        () async {
          when(
            () => authRepository.signOut(),
          ).thenAnswer((_) async => const AppSuccess<void>(null));

          final result = await service.logout();

          expect(result, isA<AppSuccess<void>>());
          verify(() => authRepository.signOut()).called(1);
          verify(() => secureSessionStore.clear()).called(1);
        },
      );

      test(
        'still clears the secure store even when the remote sign-out fails',
        () async {
          when(() => authRepository.signOut()).thenAnswer(
            (_) async => const AppFailure<void>(ConnectivityFailure('offline')),
          );

          final result = await service.logout();

          expect(result, isA<AppFailure<void>>());
          verify(() => secureSessionStore.clear()).called(1);
        },
      );
    });

    group('ensureSessionIsActive', () {
      test(
        'succeeds without refreshing when there is no signed-in user',
        () async {
          when(() => authRepository.currentUser).thenReturn(null);

          final result = await service.ensureSessionIsActive();

          expect(result, isA<AppSuccess<void>>());
          verifyNever(() => authRepository.refreshSession());
          verifyNever(() => secureSessionStore.persistSignedInUserId(any()));
        },
      );

      test('persists the signed-in uid when the token refresh confirms the '
          'session', () async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(
          () => authRepository.refreshSession(),
        ).thenAnswer((_) async => const AppSuccess<void>(null));

        final result = await service.ensureSessionIsActive();

        expect(result, isA<AppSuccess<void>>());
        verify(
          () => secureSessionStore.persistSignedInUserId('user-1'),
        ).called(1);
        verifyNever(() => authRepository.signOut());
        verifyNever(() => secureSessionStore.clear());
      });

      test('does not end the session on a connectivity failure while '
          'refreshing (offline must never lose a valid session)', () async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(() => authRepository.refreshSession()).thenAnswer(
          (_) async => const AppFailure<void>(
            ConnectivityFailure('Sem conexão com a internet.'),
          ),
        );

        final result = await service.ensureSessionIsActive();

        expect(result, isA<AppSuccess<void>>());
        verifyNever(() => authRepository.signOut());
        verifyNever(() => secureSessionStore.clear());
        verifyNever(() => secureSessionStore.persistSignedInUserId(any()));
      });

      test('signs out and clears the store when the refresh reports the '
          'account was disabled remotely', () async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(() => authRepository.refreshSession()).thenAnswer(
          (_) async => const AppFailure<void>(
            AuthenticationFailure(
              'Sua sessão foi encerrada.',
              code: 'user-disabled',
            ),
          ),
        );
        when(
          () => authRepository.signOut(),
        ).thenAnswer((_) async => const AppSuccess<void>(null));

        final result = await service.ensureSessionIsActive();

        expect(result, isA<AppFailure<void>>());
        expect(
          (result as AppFailure<void>).failure,
          isA<AuthenticationFailure>(),
        );
        verify(() => authRepository.signOut()).called(1);
        verify(() => secureSessionStore.clear()).called(1);
      });

      test(
        'signs out when the refresh token itself was revoked/invalidated',
        () async {
          when(() => authRepository.currentUser).thenReturn(signedInUser);
          when(() => authRepository.refreshSession()).thenAnswer(
            (_) async => const AppFailure<void>(
              AuthenticationFailure(
                'Sua sessão foi encerrada.',
                code: 'user-token-expired',
              ),
            ),
          );
          when(
            () => authRepository.signOut(),
          ).thenAnswer((_) async => const AppSuccess<void>(null));

          final result = await service.ensureSessionIsActive();

          expect(result, isA<AppFailure<void>>());
          verify(() => authRepository.signOut()).called(1);
        },
      );

      test('does not end the session for an unrelated AuthenticationFailure '
          'code', () async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(() => authRepository.refreshSession()).thenAnswer(
          (_) async => const AppFailure<void>(
            AuthenticationFailure(
              'Falha desconhecida.',
              code: 'some-other-code',
            ),
          ),
        );

        final result = await service.ensureSessionIsActive();

        expect(result, isA<AppSuccess<void>>());
        verifyNever(() => authRepository.signOut());
      });
    });
  });
}
