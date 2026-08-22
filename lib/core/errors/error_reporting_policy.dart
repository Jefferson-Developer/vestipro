import 'app_exception.dart';
import 'exception_mapper.dart';
import 'failure.dart';

/// Whether [error] represents a truly unexpected failure that should reach
/// crash reporting (TASK-016), as opposed to an expected/handled business
/// exception (validation, permission, not found, conflict, connectivity,
/// server) that the UI already surfaces to the user without it being a bug.
///
/// Any [AppException] is classified through [mapAppExceptionToFailure]: only
/// the ones that map to [UnexpectedFailure] (`CacheException`,
/// `SyncException`, `UnknownException`, `FirebaseInitializationException`)
/// are considered unexpected. Anything that is not an [AppException] at all
/// — a raw framework/async error nobody classified — is always unexpected,
/// since by definition it escaped the app's own error handling.
bool isUnexpectedError(Object error) {
  if (error is AppException) {
    return mapAppExceptionToFailure(error) is UnexpectedFailure;
  }
  return true;
}
