import '../dtos/communication_preferences_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/communicationPreferences/{userId}`
/// documents (TASK-154). [FirestoreCommunicationPreferencesDataSource] is the
/// only implementation today.
abstract interface class CommunicationPreferencesDataSource {
  /// `null` when [userId] has never saved a preference yet.
  Future<CommunicationPreferencesDto?> getById({
    required String organizationId,
    required String userId,
  });

  /// Live stream of the same document `getById` reads — emits again whenever
  /// it changes, from this device or any other one signed in as [userId].
  Stream<CommunicationPreferencesDto?> watch({
    required String organizationId,
    required String userId,
  });

  /// Creates or overwrites the whole document for `dto.userId`.
  Future<void> upsert(CommunicationPreferencesDto dto);
}
