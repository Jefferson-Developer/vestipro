import '../dtos/locale_preference_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/localePreferences/{userId}` documents
/// (TASK-174). [FirestoreLocalePreferenceDataSource] is the only
/// implementation today.
abstract interface class LocalePreferenceDataSource {
  /// Creates or overwrites the whole document for `dto.userId`. Failures
  /// (offline, permission) are the caller's (`LocalePreferenceRepositoryImpl`)
  /// responsibility to swallow — this method itself still throws/propagates
  /// like every other datasource, it just is never awaited in a way that
  /// blocks the local save.
  Future<void> upsert(LocalePreferenceDto dto);
}
