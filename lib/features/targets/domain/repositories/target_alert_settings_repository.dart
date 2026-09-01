import '../../../../core/utils/utils.dart';
import '../value_objects/target_alert_settings.dart';

abstract interface class TargetAlertSettingsRepository {
  Future<AppResult<TargetAlertSettings>> getForOrganization({
    required String organizationId,
  });

  Future<AppResult<TargetAlertSettings>> saveForOrganization({
    required String organizationId,
    required TargetAlertSettings settings,
  });
}
