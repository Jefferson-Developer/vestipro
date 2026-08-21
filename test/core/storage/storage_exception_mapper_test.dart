import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/storage/storage.dart';

void main() {
  group('mapStorageExceptionToAppException', () {
    test('maps unauthenticated to UnauthorizedException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'unauthenticated'),
        StackTrace.empty,
      );

      expect(result, isA<UnauthorizedException>());
      expect(result.code, 'unauthenticated');
    });

    test('maps unauthorized to ForbiddenException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'unauthorized'),
        StackTrace.empty,
      );

      expect(result, isA<ForbiddenException>());
    });

    test('maps object-not-found to NotFoundException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
        StackTrace.empty,
      );

      expect(result, isA<NotFoundException>());
    });

    test('maps canceled to ConflictException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'canceled'),
        StackTrace.empty,
      );

      expect(result, isA<ConflictException>());
    });

    test('maps retry-limit-exceeded to NetworkException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'retry-limit-exceeded',
        ),
        StackTrace.empty,
      );

      expect(result, isA<NetworkException>());
    });

    test('maps quota-exceeded to ServerException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'quota-exceeded'),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    test('maps invalid-checksum to ValidationException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'invalid-checksum'),
        StackTrace.empty,
      );

      expect(result, isA<ValidationException>());
    });

    test('maps bucket-not-found to ServerException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'bucket-not-found'),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    test('maps project-not-found to ServerException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'project-not-found',
        ),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    test('maps no-bucket to ServerException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(plugin: 'firebase_storage', code: 'no-bucket'),
        StackTrace.empty,
      );

      expect(result, isA<ServerException>());
    });

    test('maps an unknown code to UnknownException', () {
      final result = mapStorageExceptionToAppException(
        FirebaseException(
          plugin: 'firebase_storage',
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
          'unauthorized',
          'object-not-found',
          'canceled',
          'retry-limit-exceeded',
          'quota-exceeded',
          'invalid-checksum',
          'bucket-not-found',
          'project-not-found',
          'no-bucket',
          'unmapped',
        ];

        for (final code in codes) {
          final exception = mapStorageExceptionToAppException(
            FirebaseException(plugin: 'firebase_storage', code: code),
            StackTrace.empty,
          );

          expect(mapAppExceptionToFailure(exception), isA<Failure>());
        }
      },
    );
  });
}
