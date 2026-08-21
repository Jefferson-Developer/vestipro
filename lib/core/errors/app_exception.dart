sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause, this.stackTrace});

  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer(runtimeType)
      ..write(': ')
      ..write(message);

    if (code != null) {
      buffer.write(' (code: $code)');
    }

    if (cause != null) {
      buffer.write(' caused by $cause');
    }

    return buffer.toString();
  }
}

final class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class TimeoutException extends AppException {
  const TimeoutException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class ForbiddenException extends AppException {
  const ForbiddenException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const <String, String>{},
    super.code,
    super.cause,
    super.stackTrace,
  });

  final Map<String, String> fieldErrors;
}

final class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

final class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class SyncException extends AppException {
  const SyncException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class FirebaseInitializationException extends AppException {
  const FirebaseInitializationException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}
