import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/onboarding_progress.dart';
import '../repositories/onboarding_progress_repository.dart';

/// Loads [userId]'s saved wizard progress, if any, so `OnboardingBloc` can
/// resume exactly where the user left it (TASK-038).
@injectable
final class GetOnboardingProgressUseCase {
  const GetOnboardingProgressUseCase(this._repository);

  final OnboardingProgressRepository _repository;

  Future<AppResult<OnboardingProgress?>> call({required String userId}) {
    return _repository.getProgress(userId: userId);
  }
}
