import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/onboarding/data/datasources/onboarding_progress_data_source.dart';
import 'package:vestipro/features/onboarding/data/dtos/onboarding_progress_dto.dart';
import 'package:vestipro/features/onboarding/data/mappers/onboarding_progress_mapper.dart';
import 'package:vestipro/features/onboarding/data/repositories/onboarding_progress_repository_impl.dart';
import 'package:vestipro/features/onboarding/domain/entities/onboarding_progress.dart';

class _MockOnboardingProgressDataSource extends Mock
    implements OnboardingProgressDataSource {}

void main() {
  group('OnboardingProgressRepositoryImpl', () {
    late _MockOnboardingProgressDataSource dataSource;
    const mapper = OnboardingProgressMapper();
    late OnboardingProgressRepositoryImpl repository;

    setUp(() {
      dataSource = _MockOnboardingProgressDataSource();
      repository = OnboardingProgressRepositoryImpl(
        dataSource: dataSource,
        mapper: mapper,
      );
    });

    setUpAll(() {
      registerFallbackValue(
        const OnboardingProgressDto(
          stepIndex: 0,
          organizationName: '',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
      );
    });

    test(
      'getProgress returns null when the data source has nothing saved',
      () async {
        when(
          () => dataSource.getProgress(userId: 'user-1'),
        ).thenAnswer((_) async => null);

        final result = await repository.getProgress(userId: 'user-1');

        expect(result, isA<AppSuccess<OnboardingProgress?>>());
        expect((result as AppSuccess<OnboardingProgress?>).value, isNull);
      },
    );

    test('getProgress maps a saved DTO into an entity', () async {
      when(() => dataSource.getProgress(userId: 'user-1')).thenAnswer(
        (_) async => const OnboardingProgressDto(
          stepIndex: 0,
          organizationName: 'Grupo Fashion XPTO',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
      );

      final result = await repository.getProgress(userId: 'user-1');

      expect(result, isA<AppSuccess<OnboardingProgress?>>());
      expect(
        (result as AppSuccess<OnboardingProgress?>).value?.organizationName,
        'Grupo Fashion XPTO',
      );
    });

    test('getProgress returns an UnexpectedFailure when the data source '
        'throws', () async {
      when(
        () => dataSource.getProgress(userId: 'user-1'),
      ).thenThrow(Exception('boom'));

      final result = await repository.getProgress(userId: 'user-1');

      expect(result, isA<AppFailure<OnboardingProgress?>>());
    });

    test('saveProgress delegates the mapped DTO to the data source', () async {
      when(
        () => dataSource.saveProgress(
          userId: any(named: 'userId'),
          progress: any(named: 'progress'),
        ),
      ).thenAnswer((_) async {});

      const progress = OnboardingProgress(organizationName: 'Grupo Fashion');
      final result = await repository.saveProgress(
        userId: 'user-1',
        progress: progress,
      );

      expect(result, isA<AppSuccess<void>>());
      final captured =
          verify(
                () => dataSource.saveProgress(
                  userId: 'user-1',
                  progress: captureAny(named: 'progress'),
                ),
              ).captured.single
              as OnboardingProgressDto;
      expect(captured.organizationName, 'Grupo Fashion');
    });

    test('clearProgress delegates to the data source', () async {
      when(
        () => dataSource.clearProgress(userId: 'user-1'),
      ).thenAnswer((_) async {});

      final result = await repository.clearProgress(userId: 'user-1');

      expect(result, isA<AppSuccess<void>>());
      verify(() => dataSource.clearProgress(userId: 'user-1')).called(1);
    });
  });
}
