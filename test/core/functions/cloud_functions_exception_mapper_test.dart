import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/functions/functions.dart';

void main() {
  group('mapCloudFunctionsExceptionToAppException', () {
    test('maps unauthenticated to UnauthorizedException', () {
      final result = mapCloudFunctionsExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_functions',
          code: 'unauthenticated',
        ),
        StackTrace.empty,
      );

      expect(result, isA<UnauthorizedException>());
      expect(result.code, 'unauthenticated');
    });

    test('maps permission-denied to ForbiddenException', () {
      final result = mapCloudFunctionsExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_functions',
          code: 'permission-denied',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ForbiddenException>());
    });

    test('maps not-found to NotFoundException', () {
      final result = mapCloudFunctionsExceptionToAppException(
        FirebaseException(plugin: 'firebase_functions', code: 'not-found'),
        StackTrace.empty,
      );

      expect(result, isA<NotFoundException>());
    });

    for (final code in ['already-exists', 'aborted', 'failed-precondition']) {
      test('maps $code to ConflictException', () {
        final result = mapCloudFunctionsExceptionToAppException(
          FirebaseException(plugin: 'firebase_functions', code: code),
          StackTrace.empty,
        );

        expect(result, isA<ConflictException>());
      });
    }

    test('preserves failed-precondition messages for clear UX blocks', () {
      final result = mapCloudFunctionsExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_functions',
          code: 'failed-precondition',
          message: 'Último OWNER ativo.',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ConflictException>());
      expect(result.message, 'Último OWNER ativo.');
    });

    for (final code in ['unavailable', 'deadline-exceeded', 'cancelled']) {
      test('maps $code to NetworkException', () {
        final result = mapCloudFunctionsExceptionToAppException(
          FirebaseException(plugin: 'firebase_functions', code: code),
          StackTrace.empty,
        );

        expect(result, isA<NetworkException>());
      });
    }

    test('maps resource-exhausted to ServerException', () {
      final result = mapCloudFunctionsExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_functions',
          code: 'resource-exhausted',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    for (final code in ['invalid-argument', 'out-of-range']) {
      test('maps $code to ValidationException', () {
        final result = mapCloudFunctionsExceptionToAppException(
          FirebaseException(
            plugin: 'firebase_functions',
            code: code,
            message: 'Dados inválidos.',
          ),
          StackTrace.empty,
        );

        expect(result, isA<ValidationException>());
        expect(result.message, 'Dados inválidos.');
      });
    }

    for (final code in ['internal', 'unimplemented', 'data-loss']) {
      test('maps $code to ServerException', () {
        final result = mapCloudFunctionsExceptionToAppException(
          FirebaseException(plugin: 'firebase_functions', code: code),
          StackTrace.empty,
        );

        expect(result, isA<ServerException>());
      });
    }

    test('maps an unknown code to UnknownException', () {
      final result = mapCloudFunctionsExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_functions',
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
          'unauthenticated',
          'permission-denied',
          'not-found',
          'already-exists',
          'aborted',
          'failed-precondition',
          'unavailable',
          'deadline-exceeded',
          'cancelled',
          'resource-exhausted',
          'invalid-argument',
          'out-of-range',
          'internal',
          'unimplemented',
          'data-loss',
          'unknown',
        ];

        for (final code in codes) {
          final exception = mapCloudFunctionsExceptionToAppException(
            FirebaseException(plugin: 'firebase_functions', code: code),
            StackTrace.empty,
          );

          expect(mapAppExceptionToFailure(exception), isA<Failure>());
        }
      },
    );
  });

  group('transientCloudFunctionsErrorCodes', () {
    test('contains exactly the codes safe to retry automatically', () {
      expect(transientCloudFunctionsErrorCodes, {
        'unavailable',
        'deadline-exceeded',
        'internal',
        'aborted',
        'cancelled',
      });
    });

    test('never includes a validation or permission error code', () {
      const nonRetryableCodes = <String>[
        'invalid-argument',
        'out-of-range',
        'permission-denied',
        'unauthenticated',
        'failed-precondition',
        'already-exists',
        'not-found',
      ];

      for (final code in nonRetryableCodes) {
        expect(
          transientCloudFunctionsErrorCodes.contains(code),
          isFalse,
          reason: '$code must never be retried automatically',
        );
      }
    });
  });
}
