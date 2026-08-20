sealed class Failure {
  const Failure(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

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

final class ConnectivityFailure extends Failure {
  const ConnectivityFailure(super.message, {super.code, super.cause});
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code, super.cause});
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code, super.cause});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const <String, String>{},
    super.code,
    super.cause,
  });

  final Map<String, String> fieldErrors;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code, super.cause});
}

final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code, super.cause});
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.cause});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.code, super.cause});
}
