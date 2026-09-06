import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/account_deletion.dart';
import '../repositories/account_deletion_repository.dart';

final class RequestAccountDeletion {
  const RequestAccountDeletion(this._repository, this._localCleaner);

  static const confirmationPhrase = 'EXCLUIR MINHA CONTA';

  final AccountDeletionRepository _repository;
  final AccountDeletionLocalCleaner _localCleaner;

  Future<AppResult<AccountDeletionReceipt>> call({
    required String organizationId,
    required String confirmation,
  }) async {
    if (confirmation.trim() != confirmationPhrase) {
      return const AppFailure<AccountDeletionReceipt>(
        ValidationFailure(
          'Digite a frase de confirmação exatamente como exibida.',
          code: 'account_deletion_confirmation_invalid',
        ),
      );
    }
    final remote = await _repository.requestDeletion(
      organizationId: organizationId,
      confirmation: confirmation.trim(),
    );
    if (remote case AppFailure<AccountDeletionReceipt>()) return remote;

    final local = await _localCleaner.clear();
    if (local case AppFailure<void>(:final failure)) {
      return AppFailure<AccountDeletionReceipt>(failure);
    }
    return remote;
  }
}
