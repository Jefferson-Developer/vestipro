import '../../../core/errors/errors.dart';
import '../../../core/functions/functions.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/account_deletion.dart';
import '../domain/repositories/account_deletion_repository.dart';

final class FirebaseAccountDeletionRepository
    implements AccountDeletionRepository {
  const FirebaseAccountDeletionRepository(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<AppResult<AccountDeletionReceipt>> requestDeletion({
    required String organizationId,
    required String confirmation,
  }) async {
    try {
      final response = await _functions.call<Map<String, dynamic>>(
        'requestAccountDeletion',
        data: <String, dynamic>{
          'organizationId': organizationId,
          'confirmation': confirmation,
        },
        requireAuth: true,
      );
      final anonymized = response['anonymizedRecords'];
      final deleted = response['deletedRecords'];
      if (anonymized is! int || deleted is! int) {
        throw const ValidationException(
          'Resposta inválida ao excluir a conta.',
          code: 'account_deletion_response_invalid',
        );
      }
      return AppSuccess<AccountDeletionReceipt>(
        AccountDeletionReceipt(
          anonymizedRecords: anonymized,
          deletedRecords: deleted,
        ),
      );
    } on AppException catch (error) {
      return AppFailure<AccountDeletionReceipt>(
        mapAppExceptionToFailure(error),
      );
    } catch (error) {
      return AppFailure<AccountDeletionReceipt>(
        UnexpectedFailure(
          'Não foi possível excluir a conta.',
          code: 'account_deletion_unexpected',
          cause: error,
        ),
      );
    }
  }
}
