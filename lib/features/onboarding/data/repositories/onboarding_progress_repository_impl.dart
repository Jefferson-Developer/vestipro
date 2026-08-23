import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/repositories/onboarding_progress_repository.dart';
import '../datasources/onboarding_progress_data_source.dart';
import '../mappers/onboarding_progress_mapper.dart';

@LazySingleton(as: OnboardingProgressRepository)
final class OnboardingProgressRepositoryImpl
    implements OnboardingProgressRepository {
  const OnboardingProgressRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OnboardingProgressDataSource dataSource;
  final OnboardingProgressMapper mapper;

  @override
  Future<AppResult<OnboardingProgress?>> getProgress({
    required String userId,
  }) async {
    try {
      final dto = await dataSource.getProgress(userId: userId);
      if (dto == null) {
        return const AppSuccess<OnboardingProgress?>(null);
      }
      return AppSuccess<OnboardingProgress?>(mapper.toEntity(dto));
    } catch (exception) {
      return AppFailure<OnboardingProgress?>(
        UnexpectedFailure(
          'Unexpected error loading onboarding progress.',
          code: 'onboarding_progress_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> saveProgress({
    required String userId,
    required OnboardingProgress progress,
  }) async {
    try {
      await dataSource.saveProgress(
        userId: userId,
        progress: mapper.toDto(progress),
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving onboarding progress.',
          code: 'onboarding_progress_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> clearProgress({required String userId}) async {
    try {
      await dataSource.clearProgress(userId: userId);
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error clearing onboarding progress.',
          code: 'onboarding_progress_clear_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
