import 'app_exception.dart';
import 'failure.dart';

Failure mapAppExceptionToFailure(AppException exception) {
  return switch (exception) {
    NetworkException() || TimeoutException() => ConnectivityFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
    UnauthorizedException() => AuthenticationFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
    ForbiddenException() => PermissionFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
    ValidationException(fieldErrors: final fieldErrors) => ValidationFailure(
      exception.message,
      fieldErrors: fieldErrors,
      code: exception.code,
      cause: exception,
    ),
    NotFoundException() => NotFoundFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
    ConflictException() => ConflictFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
    ServerException() => ServerFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
    CacheException() ||
    SyncException() ||
    UnknownException() => UnexpectedFailure(
      exception.message,
      code: exception.code,
      cause: exception,
    ),
  };
}
