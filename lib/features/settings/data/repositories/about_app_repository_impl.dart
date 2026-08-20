import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/about_app.dart';
import '../../domain/entities/about_app_notes_page.dart';
import '../../domain/repositories/about_app_repository.dart';
import '../datasources/about_app_data_source.dart';
import '../mappers/about_app_mapper.dart';
import '../mappers/about_app_notes_mapper.dart';

final class AboutAppRepositoryImpl implements AboutAppRepository {
  const AboutAppRepositoryImpl({
    required this.dataSource,
    required this.mapper,
    required this.notesMapper,
  });

  final AboutAppDataSource dataSource;
  final AboutAppMapper mapper;
  final AboutAppNotesMapper notesMapper;

  @override
  Future<AppResult<AboutApp>> getAboutApp() async {
    try {
      final dto = await dataSource.getAboutApp();
      return AppSuccess<AboutApp>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<AboutApp>(mapAppExceptionToFailure(exception));
    } on FormatException catch (exception) {
      return AppFailure<AboutApp>(
        ValidationFailure(
          'Invalid about app payload.',
          code: 'invalid_about_app_payload',
          cause: exception,
        ),
      );
    } catch (exception) {
      return AppFailure<AboutApp>(
        UnexpectedFailure(
          'Unexpected error loading about app.',
          code: 'about_app_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<AboutAppNotesPage>> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    try {
      final dto = await dataSource.searchArchitectureNotes(
        query: query,
        page: page,
        pageSize: pageSize,
      );
      return AppSuccess<AboutAppNotesPage>(notesMapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<AboutAppNotesPage>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<AboutAppNotesPage>(
        UnexpectedFailure(
          'Unexpected error loading architecture notes.',
          code: 'about_app_notes_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> submitDiagnostics() async {
    try {
      await dataSource.submitDiagnostics();
      return AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error submitting diagnostics.',
          code: 'about_app_diagnostics_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
