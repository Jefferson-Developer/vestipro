import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:vestipro/features/onboarding/domain/repositories/onboarding_progress_repository.dart';
import 'package:vestipro/features/onboarding/domain/usecases/clear_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/get_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/save_onboarding_progress_use_case.dart';

class _MockOnboardingProgressRepository extends Mock
    implements OnboardingProgressRepository {}

void main() {
  late _MockOnboardingProgressRepository repository;

  setUp(() {
    repository = _MockOnboardingProgressRepository();
  });

  group('GetOnboardingProgressUseCase', () {
    test('delegates to the repository', () async {
      final useCase = GetOnboardingProgressUseCase(repository);
      const progress = OnboardingProgress(organizationName: 'Grupo Fashion');
      when(() => repository.getProgress(userId: 'user-1')).thenAnswer(
        (_) async => const AppSuccess<OnboardingProgress?>(progress),
      );

      final result = await useCase(userId: 'user-1');

      expect(result, isA<AppSuccess<OnboardingProgress?>>());
      verify(() => repository.getProgress(userId: 'user-1')).called(1);
    });
  });

  group('SaveOnboardingProgressUseCase', () {
    test('delegates to the repository', () async {
      final useCase = SaveOnboardingProgressUseCase(repository);
      const progress = OnboardingProgress(organizationName: 'Grupo Fashion');
      when(
        () => repository.saveProgress(userId: 'user-1', progress: progress),
      ).thenAnswer((_) async => const AppSuccess<void>(null));

      final result = await useCase(userId: 'user-1', progress: progress);

      expect(result, isA<AppSuccess<void>>());
      verify(
        () => repository.saveProgress(userId: 'user-1', progress: progress),
      ).called(1);
    });
  });

  group('ClearOnboardingProgressUseCase', () {
    test('delegates to the repository', () async {
      final useCase = ClearOnboardingProgressUseCase(repository);
      when(
        () => repository.clearProgress(userId: 'user-1'),
      ).thenAnswer((_) async => const AppSuccess<void>(null));

      final result = await useCase(userId: 'user-1');

      expect(result, isA<AppSuccess<void>>());
      verify(() => repository.clearProgress(userId: 'user-1')).called(1);
    });
  });
}
