import '../../../../core/utils/utils.dart';
import '../entities/onboarding_progress.dart';

/// Contract for the wizard's resumable local progress (TASK-038).
///
/// Deliberately scoped per [userId] (never a single global slot): the same
/// device could, in principle, be used for a different account's sign-up
/// after a sign-out, and that second account must never resume a wizard it
/// never started.
abstract interface class OnboardingProgressRepository {
  /// Returns the saved progress for [userId], or `null` when there is none
  /// (first time this user reaches the wizard).
  Future<AppResult<OnboardingProgress?>> getProgress({required String userId});

  /// Persists [progress] as [userId]'s current wizard progress, overwriting
  /// whatever was saved before.
  Future<AppResult<void>> saveProgress({
    required String userId,
    required OnboardingProgress progress,
  });

  /// Deletes [userId]'s saved progress — called once the wizard completes
  /// successfully, so a finished onboarding never resurfaces on a future
  /// sign-in.
  Future<AppResult<void>> clearProgress({required String userId});
}
