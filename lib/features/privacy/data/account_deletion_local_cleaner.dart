import '../../../core/auth/auth.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/errors.dart';
import '../../../core/notifications/push/push_token_service.dart';
import '../../../core/utils/utils.dart';
import '../domain/repositories/account_deletion_repository.dart';

final class DeviceAccountDeletionLocalCleaner
    implements AccountDeletionLocalCleaner {
  const DeviceAccountDeletionLocalCleaner({
    required this.database,
    required this.pushTokenService,
    required this.sessionService,
  });

  final AppDatabase database;
  final PushTokenService pushTokenService;
  final SessionService sessionService;

  @override
  Future<AppResult<void>> clear() async {
    try {
      await pushTokenService.unregisterCurrentDevice();
      await database.clearAllLocalData();
      await sessionService.logout();
      return const AppSuccess<void>(null);
    } catch (error) {
      return AppFailure<void>(
        UnexpectedFailure(
          'A conta foi excluída, mas não foi possível limpar todos os dados locais.',
          code: 'account_deletion_local_cleanup_failed',
          cause: error,
        ),
      );
    }
  }
}
