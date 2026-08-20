import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/about_app.dart';
import '../../domain/repositories/about_app_repository.dart';
import '../datasources/about_app_data_source.dart';
import '../mappers/about_app_mapper.dart';

final class AboutAppRepositoryImpl implements AboutAppRepository {
  const AboutAppRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final AboutAppDataSource dataSource;
  final AboutAppMapper mapper;

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
}
