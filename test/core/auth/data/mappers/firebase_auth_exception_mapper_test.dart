import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/auth/data/mappers/firebase_auth_exception_mapper.dart';
import 'package:vestipro/core/errors/errors.dart';

void main() {
  group('mapFirebaseAuthExceptionToAppException', () {
    test('maps user-not-found to UnauthorizedException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'user-not-found'),
        StackTrace.empty,
      );

      expect(result, isA<UnauthorizedException>());
      expect(result.code, 'user-not-found');
    });

    test('maps wrong-password to UnauthorizedException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'wrong-password'),
        StackTrace.empty,
      );

      expect(result, isA<UnauthorizedException>());
      expect(result.code, 'wrong-password');
    });

    test('maps user-disabled to the deactivated access message', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'user-disabled'),
        StackTrace.empty,
      );

      expect(result, isA<UnauthorizedException>());
      expect(
        result.message,
        'Seu acesso foi desativado. Entre em contato com o administrador da sua organização.',
      );
    });

    test('maps network-request-failed to NetworkException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'network-request-failed'),
        StackTrace.empty,
      );

      expect(result, isA<NetworkException>());
    });

    test('maps too-many-requests to ServerException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'too-many-requests'),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    test('maps email-already-in-use to ConflictException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'email-already-in-use'),
        StackTrace.empty,
      );

      expect(result, isA<ConflictException>());
    });

    test('maps weak-password to ValidationException with field error', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'weak-password'),
        StackTrace.empty,
      );

      expect(result, isA<ValidationException>());
      expect(
        (result as ValidationException).fieldErrors['password'],
        'weak-password',
      );
    });

    test('maps operation-not-allowed to ForbiddenException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(code: 'operation-not-allowed'),
        StackTrace.empty,
      );

      expect(result, isA<ForbiddenException>());
    });

    test('maps an unknown code to UnknownException', () {
      final result = mapFirebaseAuthExceptionToAppException(
        FirebaseAuthException(
          code: 'some-unmapped-code',
          message: 'Something odd happened.',
        ),
        StackTrace.empty,
      );

      expect(result, isA<UnknownException>());
      expect(result.message, 'Something odd happened.');
    });

    test(
      'every mapped AppException converts to a Failure through mapAppExceptionToFailure',
      () {
        const codes = <String>[
          'user-not-found',
          'wrong-password',
          'invalid-credential',
          'invalid-email',
          'user-disabled',
          'network-request-failed',
          'too-many-requests',
          'email-already-in-use',
          'weak-password',
          'operation-not-allowed',
          'unmapped',
        ];

        for (final code in codes) {
          final exception = mapFirebaseAuthExceptionToAppException(
            FirebaseAuthException(code: code),
            StackTrace.empty,
          );

          expect(mapAppExceptionToFailure(exception), isA<Failure>());
        }
      },
    );
  });
}
