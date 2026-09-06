import '../../../../core/utils/utils.dart';
import '../entities/account_deletion.dart';

abstract interface class AccountDeletionRepository {
  Future<AppResult<AccountDeletionReceipt>> requestDeletion({
    required String organizationId,
    required String confirmation,
  });
}

abstract interface class AccountDeletionLocalCleaner {
  Future<AppResult<void>> clear();
}
