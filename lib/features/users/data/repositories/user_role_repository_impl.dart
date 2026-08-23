import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/user_role_update_result.dart';
import '../../domain/repositories/user_role_repository.dart';
import '../datasources/user_role_data_source.dart';
import '../mappers/user_role_update_result_mapper.dart';

@LazySingleton(as: UserRoleRepository)
final class UserRoleRepositoryImpl implements UserRoleRepository {
  const UserRoleRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final UserRoleDataSource dataSource;
  final UserRoleUpdateResultMapper mapper;

  @override
  Future<AppResult<UserRoleUpdateResult>> updateUserRole({
    required String organizationId,
    required String targetUserId,
    required SystemRoleName roleName,
  }) async {
    try {
      final dto = await dataSource.updateUserRole(
        organizationId: organizationId,
        targetUserId: targetUserId,
        roleName: roleName.code,
      );
      return AppSuccess<UserRoleUpdateResult>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<UserRoleUpdateResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<UserRoleUpdateResult>(
        UnexpectedFailure(
          'Unexpected error updating user role.',
          code: 'user_role_update_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
