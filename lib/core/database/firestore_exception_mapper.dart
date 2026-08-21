import 'package:firebase_core/firebase_core.dart';

import '../errors/errors.dart';

/// Maps a [FirebaseException] raised by the `cloud_firestore` SDK to the
/// app's own [AppException] hierarchy, so the SDK exception never leaves
/// `lib/core/database/`.
AppException mapFirestoreExceptionToAppException(
  FirebaseException exception,
  StackTrace stackTrace,
) {
  switch (exception.code) {
    case 'unauthenticated':
      return UnauthorizedException(
        'Sessão expirada. Faça login novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'permission-denied':
      return ForbiddenException(
        'Você não tem permissão para acessar este recurso.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'not-found':
      return NotFoundException(
        'Documento não encontrado.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'already-exists':
    case 'aborted':
    case 'failed-precondition':
      return ConflictException(
        'Conflito ao salvar os dados. Tente novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'unavailable':
    case 'deadline-exceeded':
    case 'cancelled':
      return NetworkException(
        'Sem conexão com o Firestore.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'resource-exhausted':
      return ServerException(
        'Limite de uso do Firestore atingido. Tente novamente mais tarde.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'invalid-argument':
    case 'out-of-range':
      return ValidationException(
        exception.message ?? 'Dados inválidos para o Firestore.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    default:
      return UnknownException(
        exception.message ?? 'Falha desconhecida do Firestore.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
  }
}
