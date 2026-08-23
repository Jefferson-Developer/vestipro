import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/onboarding_progress.dart';
import '../repositories/onboarding_progress_repository.dart';

/// Persists [userId]'s wizard progress after every step edit/navigation, so
/// the wizard survives the app being closed at any point (TASK-038).
@injectable
final class SaveOnboardingProgressUseCase {
  const SaveOnboardingProgressUseCase(this._repository);

  final OnboardingProgressRepository _repository;

  Future<AppResult<void>> call({
    required String userId,
    required OnboardingProgress progress,
  }) {
    return _repository.saveProgress(userId: userId, progress: progress);
  }
}
