import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../repositories/notification_inbox_repository.dart';

@injectable
final class MarkAllNotificationsAsReadUseCase {
  MarkAllNotificationsAsReadUseCase(this._repository);

  final NotificationInboxRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
    DateTime? readAt,
  }) {
    return _repository.markAllAsRead(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
      readAt: readAt,
    );
  }
}
