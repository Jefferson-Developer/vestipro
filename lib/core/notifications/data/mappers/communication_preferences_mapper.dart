import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/communication_preferences.dart';
import '../../domain/entities/quiet_hours.dart';
import '../dtos/communication_preferences_dto.dart';

/// Converts between [CommunicationPreferences] (domain) and
/// [CommunicationPreferencesDto] (Firestore document shape) — same thin,
/// stateless mapper convention as `NotificationMapper`/`PushDeviceMapper`.
@lazySingleton
final class CommunicationPreferencesMapper {
  const CommunicationPreferencesMapper();

  CommunicationPreferences toEntity(CommunicationPreferencesDto dto) {
    return CommunicationPreferences(
      organizationId: dto.organizationId,
      userId: dto.userId,
      updatedAt: dto.updatedAt,
      quietHours: _quietHoursFromJson(dto.quietHours),
      categoryPreferences:
          <AppNotificationCategory, CategoryCommunicationPreference>{
            for (final category in AppNotificationCategory.values)
              category: _categoryPreferenceFromJson(
                dto.categories[category.name],
              ),
          },
    );
  }

  CommunicationPreferencesDto toDto(CommunicationPreferences entity) {
    return CommunicationPreferencesDto(
      organizationId: entity.organizationId,
      userId: entity.userId,
      updatedAt: entity.updatedAt,
      quietHours: _quietHoursToJson(entity.quietHours),
      categories: <String, Map<String, String>>{
        for (final category in AppNotificationCategory.values)
          category.name: <String, String>{
            for (final channel in CommunicationChannel.values)
              channel.name: entity
                  .preferenceFor(category)
                  .frequencyFor(channel)
                  .name,
          },
      },
    );
  }

  /// `null` means the document never recorded quiet hours at all (e.g.
  /// every document written before TASK-155) — degrades to
  /// `const QuietHours()` (disabled), same "missing preference has a safe
  /// default" convention [_categoryPreferenceFromJson] already follows.
  QuietHours _quietHoursFromJson(Map<String, Object?>? json) {
    if (json == null) return const QuietHours();

    final enabled = json['enabled'];
    final startMinuteOfDay = json['startMinuteOfDay'];
    final endMinuteOfDay = json['endMinuteOfDay'];
    final activeWeekdays = json['activeWeekdays'];
    final timezoneOffsetMinutes = json['timezoneOffsetMinutes'];
    final timezoneUpdatedAt = json['timezoneUpdatedAt'];

    return QuietHours(
      enabled: enabled is bool ? enabled : false,
      startMinuteOfDay: startMinuteOfDay is int
          ? startMinuteOfDay
          : const QuietHours().startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay is int
          ? endMinuteOfDay
          : const QuietHours().endMinuteOfDay,
      activeWeekdays: activeWeekdays is List
          ? activeWeekdays.whereType<int>().toSet()
          : QuietHours.kAllWeekdays,
      timezoneOffsetMinutes: timezoneOffsetMinutes is int
          ? timezoneOffsetMinutes
          : null,
      timezoneUpdatedAt: timezoneUpdatedAt is Timestamp
          ? timezoneUpdatedAt.toDate()
          : null,
    );
  }

  Map<String, Object?> _quietHoursToJson(QuietHours quietHours) {
    return <String, Object?>{
      'enabled': quietHours.enabled,
      'startMinuteOfDay': quietHours.startMinuteOfDay,
      'endMinuteOfDay': quietHours.endMinuteOfDay,
      'activeWeekdays': quietHours.activeWeekdays.toList(growable: false),
      'timezoneOffsetMinutes': quietHours.timezoneOffsetMinutes,
      'timezoneUpdatedAt': quietHours.timezoneUpdatedAt == null
          ? null
          : Timestamp.fromDate(quietHours.timezoneUpdatedAt!),
    };
  }

  /// `null` means the document never recorded this category at all (e.g. a
  /// category shipped after the user's last save) — degrades to
  /// [kDefaultCategoryCommunicationPreference] whole, rather than per
  /// channel, so a never-configured category always reads back exactly the
  /// documented default.
  CategoryCommunicationPreference _categoryPreferenceFromJson(
    Map<String, String>? json,
  ) {
    if (json == null) return kDefaultCategoryCommunicationPreference;
    return CategoryCommunicationPreference(
      channelFrequencies: <CommunicationChannel, CommunicationFrequency>{
        for (final channel in CommunicationChannel.values)
          channel: _frequencyFromString(
            json[channel.name],
            fallback: kDefaultCategoryCommunicationPreference.frequencyFor(
              channel,
            ),
          ),
      },
    );
  }

  CommunicationFrequency _frequencyFromString(
    String? value, {
    required CommunicationFrequency fallback,
  }) {
    if (value == null) return fallback;
    return CommunicationFrequency.values.firstWhere(
      (frequency) => frequency.name == value,
      orElse: () => fallback,
    );
  }
}
