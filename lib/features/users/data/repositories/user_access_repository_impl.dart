import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/user_access_update_result.dart';
import '../../domain/repositories/user_access_repository.dart';
import '../datasources/user_access_data_source.dart';
import '../dtos/user_access_update_result_dto.dart';
import '../mappers/user_access_update_result_mapper.dart';

@LazySingleton(as: UserAccessRepository)
final class UserAccessRepositoryImpl implements UserAccessRepository {
  const UserAccessRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final UserAccessDataSource dataSource;
  final UserAccessUpdateResultMapper mapper;

  @override
  Future<AppResult<UserAccessUpdateResult>> deactivateUser({
    required String organizationId,
    required String targetUserId,
  }) {
    return _changeAccess(
      operation: () => dataSource.deactivateUser(
        organizationId: organizationId,
        targetUserId: targetUserId,
      ),
      unexpectedMessage: 'Unexpected error deactivating user access.',
      unexpectedCode: 'user_access_deactivate_unexpected',
    );
  }

  @override
  Future<AppResult<UserAccessUpdateResult>> reactivateUser({
    required String organizationId,
    required String targetUserId,
  }) {
    return _changeAccess(
      operation: () => dataSource.reactivateUser(
        organizationId: organizationId,
        targetUserId: targetUserId,
      ),
      unexpectedMessage: 'Unexpected error reactivating user access.',
      unexpectedCode: 'user_access_reactivate_unexpected',
    );
  }

  Future<AppResult<UserAccessUpdateResult>> _changeAccess({
    required Future<UserAccessUpdateResultDto> Function() operation,
    required String unexpectedMessage,
    required String unexpectedCode,
  }) async {
    try {
      final dto = await operation();
      return AppSuccess<UserAccessUpdateResult>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<UserAccessUpdateResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<UserAccessUpdateResult>(
        UnexpectedFailure(
          unexpectedMessage,
          code: unexpectedCode,
          cause: exception,
        ),
      );
    }
  }
}
