import '../../../utils/utils.dart';
import '../entities/communication_preferences.dart';

/// Source of truth for [CommunicationPreferences] (TASK-154), one document
/// per user shared by every device that user signs into — no caller ever
/// keeps its own local-only copy as the "real" value the way, say, a draft
/// pedido would; a device that has not synced yet simply has not seen the
/// latest preference, it never has a conflicting one of its own to reconcile.
abstract interface class CommunicationPreferencesRepository {
  /// Reads the current preferences for [userId] within [organizationId],
  /// degrading to [CommunicationPreferences.defaults] (never a
  /// `NotFoundFailure`) when the user has never configured anything yet.
  Future<AppResult<CommunicationPreferences>> get({
    required String organizationId,
    required String userId,
  });

  /// Live stream backed by a Firestore listener — every other device signed
  /// in as the same [userId] and also watching sees the same update in near
  /// real time, satisfying TASK-154's "alteração em um dispositivo reflete
  /// nos demais" requirement. Never throws/terminates on a transient read
  /// error: degrades to [CommunicationPreferences.defaults] instead, so a
  /// UI subscribed to this never gets stuck without a value.
  Stream<CommunicationPreferences> watch({
    required String organizationId,
    required String userId,
  });

  /// Persists [preferences] as the new source of truth for
  /// `(preferences.organizationId, preferences.userId)`. Callers must run
  /// [preferences] through `SaveCommunicationPreferencesUseCase` first — this
  /// method itself performs no business-rule validation, only persistence.
  Future<AppResult<CommunicationPreferences>> save({
    required CommunicationPreferences preferences,
  });
}
