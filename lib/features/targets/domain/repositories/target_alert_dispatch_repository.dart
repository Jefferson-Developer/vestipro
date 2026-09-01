import '../../../../core/utils/utils.dart';
import '../entities/target_alert_assessment.dart';

abstract interface class TargetAlertDispatchRepository {
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
  });

  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
    required DateTime dispatchedAt,
  });
}
