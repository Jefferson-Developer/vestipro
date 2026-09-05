import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_inbox_repository.dart';

/// Thin pass-through over [NotificationInboxRepository.listForUser] — kept
/// as its own use case (rather than the bloc calling the repository
/// directly) for the same Clean Architecture convention every other feature
/// follows (TASK-004).
@injectable
final class ListNotificationsForUserUseCase {
  ListNotificationsForUserUseCase(this._repository);

  final NotificationInboxRepository _repository;

  Future<AppResult<List<AppNotification>>> call({
    required String organizationId,
    required String userId,
  }) {
    return _repository.listForUser(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
    );
  }
}
