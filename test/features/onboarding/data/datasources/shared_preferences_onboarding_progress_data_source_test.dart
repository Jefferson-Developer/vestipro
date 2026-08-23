import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/features/onboarding/data/datasources/shared_preferences_onboarding_progress_data_source.dart';
import 'package:vestipro/features/onboarding/data/dtos/onboarding_progress_dto.dart';

void main() {
  group('SharedPreferencesOnboardingProgressDataSource', () {
    const dataSource = SharedPreferencesOnboardingProgressDataSource();

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'getProgress returns null when nothing was saved for the user',
      () async {
        final result = await dataSource.getProgress(userId: 'user-1');
        expect(result, isNull);
      },
    );

    test('saveProgress persists the progress, scoped per user', () async {
      const progress = OnboardingProgressDto(
        stepIndex: 2,
        organizationName: 'Grupo Fashion XPTO',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segmentCode: 'apparel',
      );

      await dataSource.saveProgress(userId: 'user-1', progress: progress);

      final savedForUser1 = await dataSource.getProgress(userId: 'user-1');
      expect(savedForUser1?.organizationName, 'Grupo Fashion XPTO');
      expect(savedForUser1?.segmentCode, 'apparel');

      final savedForUser2 = await dataSource.getProgress(userId: 'user-2');
      expect(savedForUser2, isNull);
    });

    test(
      'clearProgress removes only the given user\'s saved progress',
      () async {
        const progress = OnboardingProgressDto(
          stepIndex: 0,
          organizationName: 'Grupo Fashion XPTO',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        );
        await dataSource.saveProgress(userId: 'user-1', progress: progress);
        await dataSource.saveProgress(userId: 'user-2', progress: progress);

        await dataSource.clearProgress(userId: 'user-1');

        expect(await dataSource.getProgress(userId: 'user-1'), isNull);
        expect(await dataSource.getProgress(userId: 'user-2'), isNotNull);
      },
    );

    test('getProgress returns null instead of throwing for a corrupted '
        'cache entry', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_progress_user-1': 'not-valid-json{{{',
      });

      final result = await dataSource.getProgress(userId: 'user-1');

      expect(result, isNull);
    });

    test('getProgress returns null instead of throwing when the saved JSON '
        'has an unexpected shape', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_progress_user-1': '{"unexpected":"shape"}',
      });

      final result = await dataSource.getProgress(userId: 'user-1');

      expect(result, isNull);
    });
  });
}
