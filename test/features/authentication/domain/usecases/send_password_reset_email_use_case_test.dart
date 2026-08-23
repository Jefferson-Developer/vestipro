import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/usecases/send_password_reset_email_use_case.dart';

void main() {
  group('SendPasswordResetEmailUseCase', () {
    const email = 'vendedor@vestipro.com.br';

    test('returns success as-is when the repository succeeds', () async {
      final useCase = SendPasswordResetEmailUseCase(
        _AuthRepositoryStub(result: const AppSuccess<void>(null)),
      );

      final result = await useCase(email: email);

      expect(result, isA<AppSuccess<void>>());
    });

    test('maps a user-not-found failure to a generic success, so the caller '
        'can never tell whether the account exists', () async {
      final useCase = SendPasswordResetEmailUseCase(
        _AuthRepositoryStub(
          result: const AppFailure<void>(
            AuthenticationFailure(
              'E-mail ou senha inválidos.',
              code: 'user-not-found',
            ),
          ),
        ),
      );

      final result = await useCase(email: email);

      expect(result, isA<AppSuccess<void>>());
    });

    test(
      'rewrites an invalid-email failure with a reset-specific message',
      () async {
        final useCase = SendPasswordResetEmailUseCase(
          _AuthRepositoryStub(
            result: const AppFailure<void>(
              AuthenticationFailure(
                'E-mail ou senha inválidos.',
                code: 'invalid-email',
              ),
            ),
          ),
        );

        final result = await useCase(email: 'not-an-email');

        expect(
          result,
          isA<AppFailure<void>>().having(
            (failure) => failure.failure,
            'failure',
            isA<ValidationFailure>()
                .having(
                  (failure) => failure.message,
                  'message',
                  'Informe um e-mail válido.',
                )
                .having((failure) => failure.code, 'code', 'invalid-email'),
          ),
        );
      },
    );

    test(
      'rewrites a too-many-requests failure with a reset-specific message',
      () async {
        final useCase = SendPasswordResetEmailUseCase(
          _AuthRepositoryStub(
            result: const AppFailure<void>(
              ServerFailure(
                'Muitas tentativas de login. Tente novamente mais tarde.',
                code: 'too-many-requests',
              ),
            ),
          ),
        );

        final result = await useCase(email: email);

        expect(
          result,
          isA<AppFailure<void>>().having(
            (failure) => failure.failure,
            'failure',
            isA<ServerFailure>()
                .having(
                  (failure) => failure.message,
                  'message',
                  'Muitas tentativas. Tente novamente mais tarde.',
                )
                .having((failure) => failure.code, 'code', 'too-many-requests'),
          ),
        );
      },
    );

    test('propagates a connectivity failure unchanged', () async {
      const failure = ConnectivityFailure('Sem conexão com a internet.');
      final useCase = SendPasswordResetEmailUseCase(
        _AuthRepositoryStub(result: const AppFailure<void>(failure)),
      );

      final result = await useCase(email: email);

      expect(
        result,
        isA<AppFailure<void>>().having(
          (result) => result.failure,
          'failure',
          same(failure),
        ),
      );
    });

    test('trims the e-mail before delegating to the repository', () async {
      String? capturedEmail;
      final useCase = SendPasswordResetEmailUseCase(
        _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
          onCall: (email) => capturedEmail = email,
        ),
      );

      await useCase(email: '  $email  ');

      expect(capturedEmail, email);
    });
  });
}

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub({required this.result, this.onCall});

  final AppResult<void> result;
  final void Function(String email)? onCall;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => null;

  @override
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    onCall?.call(email);
    return result;
  }

  @override
  Future<AppResult<void>> refreshSession() {
    throw UnimplementedError();
  }
}
