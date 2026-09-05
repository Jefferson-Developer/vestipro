import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../repositories/notification_inbox_repository.dart';

@injectable
final class MarkNotificationAsReadUseCase {
  MarkNotificationAsReadUseCase(this._repository);

  final NotificationInboxRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
    required String notificationId,
    DateTime? readAt,
  }) {
    return _repository.markAsRead(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
      notificationId: notificationId.trim(),
      readAt: readAt,
    );
  }
}
