import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';

void main() {
  group('isUnexpectedError', () {
    test('is true for exceptions that map to UnexpectedFailure', () {
      expect(isUnexpectedError(const CacheException('cache')), isTrue);
      expect(isUnexpectedError(const SyncException('sync')), isTrue);
      expect(isUnexpectedError(const UnknownException('unknown')), isTrue);
      expect(
        isUnexpectedError(const FirebaseInitializationException('firebase')),
        isTrue,
      );
    });

    test('is false for expected/handled business exceptions', () {
      expect(isUnexpectedError(const ValidationException('invalid')), isFalse);
      expect(isUnexpectedError(const ForbiddenException('denied')), isFalse);
      expect(
        isUnexpectedError(const UnauthorizedException('login required')),
        isFalse,
      );
      expect(isUnexpectedError(const NotFoundException('missing')), isFalse);
      expect(isUnexpectedError(const ConflictException('conflict')), isFalse);
      expect(isUnexpectedError(const NetworkException('offline')), isFalse);
      expect(isUnexpectedError(const ServerException('server')), isFalse);
    });

    test('is true for any raw, unclassified error', () {
      expect(isUnexpectedError(StateError('boom')), isTrue);
      expect(isUnexpectedError(Exception('boom')), isTrue);
    });
  });
}
