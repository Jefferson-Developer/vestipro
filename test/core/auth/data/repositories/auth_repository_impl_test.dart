import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/data/datasources/auth_data_source.dart';
import 'package:vestipro/core/auth/data/dtos/auth_user_dto.dart';
import 'package:vestipro/core/auth/data/mappers/auth_user_mapper.dart';
import 'package:vestipro/core/auth/data/repositories/auth_repository_impl.dart';
import 'package:vestipro/core/auth/domain/entities/session_user.dart';
import 'package:vestipro/core/auth/domain/value_objects/auth_provider_type.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';

class _MockAuthDataSource extends Mock implements AuthDataSource {}

void main() {
  group('AuthRepositoryImpl', () {
    late _MockAuthDataSource dataSource;
    late AuthRepositoryImpl repository;

    const dto = AuthUserDto(
      uid: 'user-1',
      email: 'rep@vestipro.com.br',
      displayName: 'Vendedor VestiPro',
      emailVerified: true,
    );

    setUp(() {
      dataSource = _MockAuthDataSource();
      repository = AuthRepositoryImpl(
        dataSource: dataSource,
        mapper: const AuthUserMapper(),
      );
    });

    group('currentUser', () {
      test('maps the datasource DTO to a SessionUser', () {
        when(() => dataSource.currentUser).thenReturn(dto);

        final result = repository.currentUser;

        expect(result, isA<SessionUser>());
        expect(result!.uid, 'user-1');
        expect(result.email, 'rep@vestipro.com.br');
        expect(result.emailVerified, isTrue);
      });

      test('returns null when the datasource has no signed-in user', () {
        when(() => dataSource.currentUser).thenReturn(null);

        expect(repository.currentUser, isNull);
      });
    });

    group('authStateChanges', () {
      test('emits mapped SessionUser and null in the same order', () async {
        when(
          () => dataSource.authStateChanges,
        ).thenAnswer((_) => Stream.fromIterable(<AuthUserDto?>[dto, null]));

        final emissions = await repository.authStateChanges.toList();

        expect(emissions, hasLength(2));
        expect(emissions[0], isA<SessionUser>());
        expect(emissions[0]!.uid, 'user-1');
        expect(emissions[1], isNull);
      });
    });

    group('signInWithEmailAndPassword', () {
      test('returns a success mapping the DTO to a SessionUser', () async {
        when(
          () => dataSource.signInWithEmailAndPassword(
            email: 'rep@vestipro.com.br',
            password: 'super-secret',
          ),
        ).thenAnswer((_) async => dto);

        final result = await repository.signInWithEmailAndPassword(
          email: 'rep@vestipro.com.br',
          password: 'super-secret',
        );

        expect(result, isA<AppSuccess<SessionUser>>());
        expect((result as AppSuccess<SessionUser>).value.uid, 'user-1');
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.signInWithEmailAndPassword(
              email: 'rep@vestipro.com.br',
              password: 'wrong',
            ),
          ).thenThrow(
            const UnauthorizedException(
              'E-mail ou senha inválidos.',
              code: 'user-not-found',
            ),
          );

          final result = await repository.signInWithEmailAndPassword(
            email: 'rep@vestipro.com.br',
            password: 'wrong',
          );

          expect(result, isA<AppFailure<SessionUser>>());
          expect(
            (result as AppFailure<SessionUser>).failure,
            isA<AuthenticationFailure>(),
          );
        },
      );

      test(
        'maps a generic exception thrown by the datasource to an UnexpectedFailure',
        () async {
          when(
            () => dataSource.signInWithEmailAndPassword(
              email: 'rep@vestipro.com.br',
              password: 'super-secret',
            ),
          ).thenThrow(StateError('boom'));

          final result = await repository.signInWithEmailAndPassword(
            email: 'rep@vestipro.com.br',
            password: 'super-secret',
          );

          expect(result, isA<AppFailure<SessionUser>>());
          final failure = (result as AppFailure<SessionUser>).failure;
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.code, 'auth_sign_in_unexpected');
        },
      );
    });

    group('signInWithProvider', () {
      test(
        'returns a Failure for every provider, including emailAndPassword',
        () async {
          for (final provider in AuthProviderType.values) {
            final result = await repository.signInWithProvider(provider);

            expect(result, isA<AppFailure<SessionUser>>());
            expect(
              (result as AppFailure<SessionUser>).failure.code,
              'auth_provider_not_supported',
            );
          }

          verifyNever(
            () => dataSource.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        },
      );
    });

    group('signOut', () {
      test('returns a success when the datasource signs out', () async {
        when(() => dataSource.signOut()).thenAnswer((_) async {});

        final result = await repository.signOut();

        expect(result, isA<AppSuccess<void>>());
        verify(() => dataSource.signOut()).called(1);
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.signOut(),
          ).thenThrow(const NetworkException('No connectivity.'));

          final result = await repository.signOut();

          expect(result, isA<AppFailure<void>>());
          expect(
            (result as AppFailure<void>).failure,
            isA<ConnectivityFailure>(),
          );
        },
      );
    });

    group('sendPasswordResetEmail', () {
      test('returns a success when the datasource sends the e-mail', () async {
        when(
          () => dataSource.sendPasswordResetEmail(email: 'rep@vestipro.com.br'),
        ).thenAnswer((_) async {});

        final result = await repository.sendPasswordResetEmail(
          email: 'rep@vestipro.com.br',
        );

        expect(result, isA<AppSuccess<void>>());
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () =>
                dataSource.sendPasswordResetEmail(email: 'rep@vestipro.com.br'),
          ).thenThrow(
            const NotFoundException(
              'E-mail não encontrado.',
              code: 'user-not-found',
            ),
          );

          final result = await repository.sendPasswordResetEmail(
            email: 'rep@vestipro.com.br',
          );

          expect(result, isA<AppFailure<void>>());
          expect((result as AppFailure<void>).failure, isA<NotFoundFailure>());
        },
      );
    });
  });
}
