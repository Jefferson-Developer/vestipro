import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/errors/errors.dart';

void main() {
  group('mapFirestoreExceptionToAppException', () {
    test('maps permission-denied to ForbiddenException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        StackTrace.empty,
      );

      expect(result, isA<ForbiddenException>());
      expect(result.code, 'permission-denied');
    });

    test('maps unauthenticated to UnauthorizedException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'unauthenticated'),
        StackTrace.empty,
      );

      expect(result, isA<UnauthorizedException>());
    });

    test('maps not-found to NotFoundException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        StackTrace.empty,
      );

      expect(result, isA<NotFoundException>());
    });

    test('maps already-exists to ConflictException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'already-exists'),
        StackTrace.empty,
      );

      expect(result, isA<ConflictException>());
    });

    test('maps aborted to ConflictException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'aborted'),
        StackTrace.empty,
      );

      expect(result, isA<ConflictException>());
    });

    test('maps failed-precondition to ConflictException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ConflictException>());
    });

    test('maps unavailable to NetworkException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        StackTrace.empty,
      );

      expect(result, isA<NetworkException>());
    });

    test('maps deadline-exceeded to NetworkException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded'),
        StackTrace.empty,
      );

      expect(result, isA<NetworkException>());
    });

    test('maps resource-exhausted to ServerException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'resource-exhausted',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    test('maps invalid-argument to ValidationException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'Bad field value.',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ValidationException>());
      expect(result.message, 'Bad field value.');
    });

    test('maps an unknown code to UnknownException', () {
      final result = mapFirestoreExceptionToAppException(
        FirebaseException(
          plugin: 'cloud_firestore',
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
          'unmapped',
        ];

        for (final code in codes) {
          final exception = mapFirestoreExceptionToAppException(
            FirebaseException(plugin: 'cloud_firestore', code: code),
            StackTrace.empty,
          );

          expect(mapAppExceptionToFailure(exception), isA<Failure>());
        }
      },
    );
  });
}
