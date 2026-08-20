import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/settings/domain/entities/about_app.dart';
import 'package:vestipro/features/settings/domain/entities/about_app_notes_page.dart';
import 'package:vestipro/features/settings/domain/repositories/about_app_repository.dart';
import 'package:vestipro/features/settings/domain/usecases/get_about_app_use_case.dart';
import 'package:vestipro/features/settings/domain/value_objects/app_version.dart';

void main() {
  group('GetAboutAppUseCase', () {
    test('returns the about app entity from the repository', () async {
      final aboutApp = AboutApp(
        name: 'VestiPro',
        version: const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        environmentLabel: 'development',
        updatedAt: DateTime.utc(2026, 8, 20),
      );
      final useCase = GetAboutAppUseCase(
        _AboutAppRepositoryStub(AppSuccess<AboutApp>(aboutApp)),
      );

      final result = await useCase();

      expect(result, isA<AppSuccess<AboutApp>>());
      expect((result as AppSuccess<AboutApp>).value, aboutApp);
    });

    test('returns a failure from the repository', () async {
      const failure = UnexpectedFailure('About app unavailable.');
      final useCase = GetAboutAppUseCase(
        _AboutAppRepositoryStub(const AppFailure<AboutApp>(failure)),
      );

      final result = await useCase();

      expect(result, isA<AppFailure<AboutApp>>());
      expect((result as AppFailure<AboutApp>).failure, failure);
    });
  });
}

final class _AboutAppRepositoryStub implements AboutAppRepository {
  const _AboutAppRepositoryStub(this._result);

  final AppResult<AboutApp> _result;

  @override
  Future<AppResult<AboutApp>> getAboutApp() async {
    return _result;
  }

  @override
  Future<AppResult<AboutAppNotesPage>> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> submitDiagnostics() async {
    return AppSuccess<void>(null);
  }
}
