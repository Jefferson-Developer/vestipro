import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/repositories/target_alert_settings_repository.dart';
import '../../domain/value_objects/target_alert_settings.dart';

@LazySingleton(as: TargetAlertSettingsRepository)
final class SharedPreferencesTargetAlertSettingsRepository
    implements TargetAlertSettingsRepository {
  const SharedPreferencesTargetAlertSettingsRepository();

  String _keyFor(String organizationId) =>
      'target_alert_settings_$organizationId';

  @override
  Future<AppResult<TargetAlertSettings>> getForOrganization({
    required String organizationId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(organizationId));
      if (raw == null) {
        return const AppSuccess<TargetAlertSettings>(TargetAlertSettings());
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const ValidationException(
          'Invalid local target alert settings payload.',
          code: 'invalid_target_alert_settings_payload',
        );
      }
      return AppSuccess<TargetAlertSettings>(_fromJson(decoded));
    } catch (exception) {
      return AppFailure<TargetAlertSettings>(
        UnexpectedFailure(
          'Unexpected error loading target alert settings locally.',
          code: 'target_alert_settings_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<TargetAlertSettings>> saveForOrganization({
    required String organizationId,
    required TargetAlertSettings settings,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFor(organizationId),
        jsonEncode(_toJson(settings)),
      );
      return AppSuccess<TargetAlertSettings>(settings);
    } catch (exception) {
      return AppFailure<TargetAlertSettings>(
        UnexpectedFailure(
          'Unexpected error saving target alert settings locally.',
          code: 'target_alert_settings_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  TargetAlertSettings _fromJson(Map<String, dynamic> json) {
    final highRisk = _doubleOrDefault(json['highRiskPaceRatioThreshold'], 0.75);
    final moderateRisk = _doubleOrDefault(
      json['moderateRiskPaceRatioThreshold'],
      0.95,
    );
    return TargetAlertSettings(
      highRiskPaceRatioThreshold: highRisk,
      moderateRiskPaceRatioThreshold: moderateRisk,
      opportunityAchievementThreshold: _doubleOrDefault(
        json['opportunityAchievementThreshold'],
        90,
      ),
      opportunityDaysRemainingThreshold: _intOrDefault(
        json['opportunityDaysRemainingThreshold'],
        5,
      ),
      notificationCooldown: Duration(
        hours: _intOrDefault(json['notificationCooldownHours'], 24),
      ),
    );
  }

  Map<String, Object> _toJson(TargetAlertSettings settings) {
    return <String, Object>{
      'highRiskPaceRatioThreshold': settings.highRiskPaceRatioThreshold,
      'moderateRiskPaceRatioThreshold': settings.moderateRiskPaceRatioThreshold,
      'opportunityAchievementThreshold':
          settings.opportunityAchievementThreshold,
      'opportunityDaysRemainingThreshold':
          settings.opportunityDaysRemainingThreshold,
      'notificationCooldownHours': settings.notificationCooldown.inHours,
    };
  }

  double _doubleOrDefault(Object? value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    throw const ValidationException(
      'Invalid local target alert settings payload.',
      code: 'invalid_target_alert_settings_payload',
    );
  }

  int _intOrDefault(Object? value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    throw const ValidationException(
      'Invalid local target alert settings payload.',
      code: 'invalid_target_alert_settings_payload',
    );
  }
}
