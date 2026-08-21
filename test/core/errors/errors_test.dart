import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart' as errors;

void main() {
  group('core errors', () {
    test('exports and instantiates AppException hierarchy', () {
      final exceptions = <errors.AppException>[
        const errors.NetworkException('network'),
        const errors.TimeoutException('timeout'),
        const errors.UnauthorizedException('unauthorized'),
        const errors.ForbiddenException('forbidden'),
        const errors.NotFoundException('not found'),
        const errors.ValidationException('validation'),
        const errors.ConflictException('conflict'),
        const errors.ServerException('server'),
        const errors.CacheException('cache'),
        const errors.SyncException('sync'),
        const errors.UnknownException('unknown'),
        const errors.FirebaseInitializationException('firebase init'),
      ];

      expect(exceptions, hasLength(12));
      expect(
        exceptions.every((exception) => exception.message.isNotEmpty),
        true,
      );
    });

    test('exports and instantiates Failure hierarchy', () {
      final failures = <errors.Failure>[
        const errors.ConnectivityFailure('connectivity'),
        const errors.AuthenticationFailure('authentication'),
        const errors.PermissionFailure('permission'),
        const errors.ValidationFailure('validation'),
        const errors.NotFoundFailure('not found'),
        const errors.ConflictFailure('conflict'),
        const errors.ServerFailure('server'),
        const errors.UnexpectedFailure('unexpected'),
      ];

      expect(failures, hasLength(8));
      expect(failures.every((failure) => failure.message.isNotEmpty), true);
    });

    test('maps AppException to domain Failure', () {
      expect(
        errors.mapAppExceptionToFailure(
          const errors.NetworkException('offline'),
        ),
        isA<errors.ConnectivityFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(
          const errors.UnauthorizedException('login required'),
        ),
        isA<errors.AuthenticationFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(
          const errors.ForbiddenException('denied'),
        ),
        isA<errors.PermissionFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(
          const errors.ValidationException('invalid'),
        ),
        isA<errors.ValidationFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(const errors.NotFoundException('miss')),
        isA<errors.NotFoundFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(
          const errors.ConflictException('conflict'),
        ),
        isA<errors.ConflictFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(const errors.ServerException('server')),
        isA<errors.ServerFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(const errors.SyncException('sync')),
        isA<errors.UnexpectedFailure>(),
      );
      expect(
        errors.mapAppExceptionToFailure(
          const errors.FirebaseInitializationException('firebase init'),
        ),
        isA<errors.UnexpectedFailure>(),
      );
    });
  });
}
