import '../../../utils/utils.dart';
import '../entities/push_device.dart';

/// Persists the FCM token↔user↔device link (TASK-150). No caller ever talks
/// to Firestore directly for this — same contract-first rule as every other
/// `Repository` in this codebase.
abstract interface class PushDeviceRepository {
  /// Creates or overwrites the link for [device.id] — idempotent by design:
  /// a token refresh or an app relaunch calls this again with the same
  /// [PushDevice.id] and a new [PushDevice.token]/[PushDevice.lastUsedAt],
  /// never creating a second document for the same physical device.
  Future<AppResult<void>> upsert(PushDevice device);

  /// Soft-deletes the [organizationId]/[deviceId] link (`deletedAt` set,
  /// never physically removed) — called on logout so the account that just
  /// signed out never receives another push on this device, and a
  /// different account signing in afterwards never inherits it either.
  Future<AppResult<void>> deactivate({
    required String organizationId,
    required String deviceId,
  });
}
