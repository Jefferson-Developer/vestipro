import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../repositories/onboarding_progress_repository.dart';

/// Deletes [userId]'s saved wizard progress once the wizard has completed
/// successfully (TASK-038), so it never resurfaces for a finished
/// onboarding.
@injectable
final class ClearOnboardingProgressUseCase {
  const ClearOnboardingProgressUseCase(this._repository);

  final OnboardingProgressRepository _repository;

  Future<AppResult<void>> call({required String userId}) {
    return _repository.clearProgress(userId: userId);
  }
}
