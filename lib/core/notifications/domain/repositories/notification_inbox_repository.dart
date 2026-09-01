import '../../../utils/utils.dart';
import '../entities/app_notification.dart';

/// Source of truth for internal notifications shown by the app itself,
/// independent from push delivery availability.
abstract interface class NotificationInboxRepository {
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  });

  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  });
}
