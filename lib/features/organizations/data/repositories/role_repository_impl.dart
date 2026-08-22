import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/role_data_source.dart';
import '../mappers/role_mapper.dart';

@LazySingleton(as: RoleRepository)
final class RoleRepositoryImpl implements RoleRepository {
  const RoleRepositoryImpl({required this.dataSource, required this.mapper});

  final RoleDataSource dataSource;
  final RoleMapper mapper;

  @override
  Future<AppResult<Role>> create({
    required String id,
    required String organizationId,
    required String name,
    required bool isSystemRole,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dto = mapper.toDto(
        Role(
          id: id,
          organizationId: organizationId,
          name: name,
          isSystemRole: isSystemRole,
          version: 1,
          createdAt: now,
          createdBy: createdBy,
          updatedAt: now,
          updatedBy: createdBy,
        ),
      );

      final createdDto = await dataSource.create(dto);
      return AppSuccess<Role>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<Role>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Role>(
        UnexpectedFailure(
          'Unexpected error creating role.',
          code: 'role_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Role>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final dtos = await dataSource.listByOrganization(organizationId);
      return AppSuccess<List<Role>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<Role>>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<List<Role>>(
        UnexpectedFailure(
          'Unexpected error listing roles.',
          code: 'role_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Role>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final dto = await dataSource.getById(
        organizationId: organizationId,
        id: id,
      );
      if (dto == null) {
        return AppFailure<Role>(
          const NotFoundFailure('Role not found.', code: 'role_not_found'),
        );
      }
      return AppSuccess<Role>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Role>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Role>(
        UnexpectedFailure(
          'Unexpected error loading role.',
          code: 'role_get_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
