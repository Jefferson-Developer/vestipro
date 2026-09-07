import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/completed_sso_login.dart';
import '../../domain/entities/sso_login_route.dart';
import '../../domain/repositories/sso_repository.dart';
import '../datasources/sso_data_source.dart';
import '../mappers/sso_mapper.dart';

@LazySingleton(as: SsoRepository)
final class SsoRepositoryImpl implements SsoRepository {
  const SsoRepositoryImpl({required this.dataSource, required this.mapper});

  final SsoDataSource dataSource;
  final SsoMapper mapper;

  @override
  Future<AppResult<SsoLoginRoute?>> resolveConnectionForEmail({
    required String email,
  }) async {
    try {
      final dto = await dataSource.resolveConnectionForEmail(email: email);
      return AppSuccess<SsoLoginRoute?>(mapper.toRouteEntityOrNull(dto));
    } on AppException catch (exception) {
      return AppFailure<SsoLoginRoute?>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<SsoLoginRoute?>(
        UnexpectedFailure(
          'Unexpected error resolving corporate SSO for this e-mail.',
          code: 'sso_resolve_connection_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CompletedSsoLogin>> completeSsoLogin() async {
    try {
      final dto = await dataSource.completeSsoLogin();
      return AppSuccess<CompletedSsoLogin>(mapper.toCompletedEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<CompletedSsoLogin>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<CompletedSsoLogin>(
        UnexpectedFailure(
          'Unexpected error completing corporate SSO login.',
          code: 'sso_complete_login_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
