import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/localePreferences/{userId}` (TASK-174) —
/// a best-effort mirror of whatever a device already saved locally, never
/// the value the app itself boots from (see `LocalePreferenceRepository`'s
/// own doc). `userId` doubles as the document id, same
/// ownership-from-the-path convention as `CommunicationPreferencesDto`.
final class LocalePreferenceDto {
  const LocalePreferenceDto({
    required this.organizationId,
    required this.userId,
    required this.languageCode,
    this.updatedAt,
  });

  factory LocalePreferenceDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final userId = json['userId'];
    final languageCode = json['languageCode'];
    final updatedAt = json['updatedAt'];

    if (organizationId is! String ||
        userId is! String ||
        languageCode is! String ||
        (updatedAt != null && updatedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid locale preference payload.',
        code: 'invalid_locale_preference_payload',
      );
    }

    return LocalePreferenceDto(
      organizationId: organizationId,
      userId: userId,
      languageCode: languageCode,
      updatedAt: (updatedAt as Timestamp?)?.toDate(),
    );
  }

  final String organizationId;
  final String userId;

  /// Raw `AppLocale.languageCode` (e.g. `"pt"`, `"en"`) — never the enum's
  /// ordinal/name, same "never depend on Dart enum internals" convention as
  /// every other DTO in this codebase.
  final String languageCode;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'userId': userId,
      'languageCode': languageCode,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
