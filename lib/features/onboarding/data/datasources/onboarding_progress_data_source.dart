import '../dtos/onboarding_progress_dto.dart';

/// Local-device persistence contract for the onboarding wizard's progress
/// (TASK-038). [SharedPreferencesOnboardingProgressDataSource] is the only
/// implementation today.
abstract interface class OnboardingProgressDataSource {
  /// Returns the saved progress for [userId], or `null` when there is none
  /// yet, or when whatever was saved could not be parsed (treated the same
  /// as "none" — a corrupted local cache must never crash the wizard,
  /// only lose the resume point).
  Future<OnboardingProgressDto?> getProgress({required String userId});

  Future<void> saveProgress({
    required String userId,
    required OnboardingProgressDto progress,
  });

  Future<void> clearProgress({required String userId});
}
