import 'package:firebase_core/firebase_core.dart';

import '../errors/errors.dart';

/// Maps a [FirebaseException] raised by the `firebase_storage` SDK to the
/// app's own [AppException] hierarchy, so the SDK exception never leaves
/// `lib/core/storage/` (same boundary rule as
/// `mapFirestoreExceptionToAppException` in `lib/core/database/`).
AppException mapStorageExceptionToAppException(
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
    case 'unauthorized':
      return ForbiddenException(
        'Você não tem permissão para acessar este arquivo.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'object-not-found':
      return NotFoundException(
        'Arquivo não encontrado.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    // A caller-initiated cancellation (`StorageUploadCancelToken.cancel()`),
    // not a security or infrastructure failure — the caller already knows it
    // asked for this outcome. There is no dedicated "cancelled" member in the
    // existing `AppException` hierarchy and this task must not add one, so
    // this reuses `ConflictException`: semantically the closest existing
    // category ("the operation could not finish as originally requested
    // because of a change in its own state"), and its `ConflictFailure`
    // mapping is the least misleading of the existing options for UI code
    // that did not itself trigger the cancellation (unlike `NetworkException`,
    // which would incorrectly imply a connectivity problem).
    case 'canceled':
      return ConflictException(
        'Upload cancelado.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'retry-limit-exceeded':
      return NetworkException(
        'Falha de conexão ao enviar o arquivo. Tente novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'quota-exceeded':
      return ServerException(
        'Limite de armazenamento atingido. Tente novamente mais tarde.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'invalid-checksum':
      return ValidationException(
        'O arquivo enviado ficou corrompido no envio. Tente novamente.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    case 'bucket-not-found':
    case 'project-not-found':
    case 'no-bucket':
      return ServerException(
        'Configuração de armazenamento indisponível. Tente novamente mais tarde.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
    default:
      return UnknownException(
        exception.message ?? 'Falha desconhecida do Storage.',
        code: exception.code,
        cause: exception,
        stackTrace: stackTrace,
      );
  }
}
