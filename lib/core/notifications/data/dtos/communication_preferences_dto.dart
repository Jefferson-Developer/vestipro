import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/communicationPreferences/{userId}`
/// (TASK-154). [userId] doubles as the document id (never one of the map's
/// keys in [toJson] — Firestore already keys the document by it, same
/// convention as `PushDeviceDto`/`NotificationDto`), which is what lets
/// Firestore Rules validate ownership from the path alone
/// (`userId == request.auth.uid`) without an extra read.
final class CommunicationPreferencesDto {
  const CommunicationPreferencesDto({
    required this.organizationId,
    required this.userId,
    required this.categories,
    this.quietHours,
    this.updatedAt,
  });

  factory CommunicationPreferencesDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final userId = json['userId'];
    final categories = json['categories'];
    final updatedAt = json['updatedAt'];
    final quietHours = json['quietHours'];

    if (organizationId is! String ||
        userId is! String ||
        categories is! Map ||
        (updatedAt != null && updatedAt is! Timestamp) ||
        (quietHours != null && quietHours is! Map)) {
      throw const ValidationException(
        'Invalid communication preferences payload.',
        code: 'invalid_communication_preferences_payload',
      );
    }

    return CommunicationPreferencesDto(
      organizationId: organizationId,
      userId: userId,
      categories: categories.map((key, value) {
        final channelFrequencies = value is Map
            ? value.map(
                (channelKey, frequencyValue) => MapEntry(
                  channelKey.toString(),
                  frequencyValue?.toString() ?? '',
                ),
              )
            : const <String, String>{};
        return MapEntry(key.toString(), channelFrequencies);
      }),
      quietHours: (quietHours as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      updatedAt: (updatedAt as Timestamp?)?.toDate(),
    );
  }

  final String organizationId;
  final String userId;

  /// Raw `AppNotificationCategory.name` -> (raw `CommunicationChannel.name`
  /// -> raw `CommunicationFrequency.name`) — kept as nested strings, same
  /// "never depend on the domain enum's ordinal" convention `NotificationDto`
  /// already documents for its own `category` field.
  final Map<String, Map<String, String>> categories;

  /// Raw `QuietHours` field map (TASK-155): `enabled` (bool),
  /// `startMinuteOfDay`/`endMinuteOfDay` (int), `activeWeekdays` (List of
  /// int, `DateTime.weekday` values), `timezoneOffsetMinutes` (int?,
  /// nullable until the first device sync) and `timezoneUpdatedAt`
  /// (Timestamp?). `null` for every document written before TASK-155 shipped
  /// this field — `CommunicationPreferencesMapper` degrades that to the
  /// documented default (disabled).
  final Map<String, Object?>? quietHours;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'userId': userId,
      'categories': categories,
      'quietHours': quietHours,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
