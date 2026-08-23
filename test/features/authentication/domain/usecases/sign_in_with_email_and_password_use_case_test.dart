import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/usecases/sign_in_with_email_and_password_use_case.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignInWithEmailAndPasswordUseCase', () {
    late _MockAuthRepository authRepository;
    late SignInWithEmailAndPasswordUseCase useCase;

    setUp(() {
      authRepository = _MockAuthRepository();
      useCase = SignInWithEmailAndPasswordUseCase(authRepository);
    });

    test('delegates to AuthRepository.signInWithEmailAndPassword', () async {
      const sessionUser = SessionUser(uid: 'user-1', emailVerified: true);
      when(
        () => authRepository.signInWithEmailAndPassword(
          email: 'vendedor@vestipro.com.br',
          password: 'super-secret',
        ),
      ).thenAnswer((_) async => const AppSuccess<SessionUser>(sessionUser));

      final result = await useCase(
        email: 'vendedor@vestipro.com.br',
        password: 'super-secret',
      );

      expect(result, isA<AppSuccess<SessionUser>>());
      expect((result as AppSuccess<SessionUser>).value, sessionUser);
      verify(
        () => authRepository.signInWithEmailAndPassword(
          email: 'vendedor@vestipro.com.br',
          password: 'super-secret',
        ),
      ).called(1);
    });

    test('propagates a Failure without altering it', () async {
      const failure = AuthenticationFailure('E-mail ou senha inválidos.');
      when(
        () => authRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AppFailure<SessionUser>(failure));

      final result = await useCase(email: 'x@y.com', password: 'wrong');

      expect(result, isA<AppFailure<SessionUser>>());
      expect((result as AppFailure<SessionUser>).failure, failure);
    });
  });
}
