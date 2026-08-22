import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/membership.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/value_objects/membership_status.dart';
import '../datasources/membership_data_source.dart';
import '../mappers/membership_mapper.dart';

@LazySingleton(as: MembershipRepository)
final class MembershipRepositoryImpl implements MembershipRepository {
  const MembershipRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final MembershipDataSource dataSource;
  final MembershipMapper mapper;

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dto = mapper.toDto(
        Membership(
          id: userId,
          organizationId: organizationId,
          userId: userId,
          roleId: roleId,
          roleName: roleName,
          teamIds: teamIds,
          status: MembershipStatus.active,
          version: 1,
          createdAt: now,
          createdBy: createdBy,
          updatedAt: now,
          updatedBy: createdBy,
        ),
      );

      final createdDto = await dataSource.create(dto);
      return AppSuccess<Membership>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<Membership>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Membership>(
        UnexpectedFailure(
          'Unexpected error creating membership.',
          code: 'membership_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final dtos = await dataSource.listByOrganization(organizationId);
      return AppSuccess<List<Membership>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<Membership>>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<List<Membership>>(
        UnexpectedFailure(
          'Unexpected error listing memberships.',
          code: 'membership_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final dto = await dataSource.getByUser(
        organizationId: organizationId,
        userId: userId,
      );
      if (dto == null) {
        return AppFailure<Membership>(
          const NotFoundFailure(
            'Membership not found.',
            code: 'membership_not_found',
          ),
        );
      }
      return AppSuccess<Membership>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Membership>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Membership>(
        UnexpectedFailure(
          'Unexpected error loading membership.',
          code: 'membership_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) async {
    try {
      final updatedDto = await dataSource.update(
        organizationId: organizationId,
        userId: userId,
        roleId: roleId,
        roleName: roleName,
        teamIds: teamIds,
        status: mapper.statusToDto(status),
        updatedAt: DateTime.now().toUtc(),
        updatedBy: updatedBy,
      );
      return AppSuccess<Membership>(mapper.toEntity(updatedDto));
    } on AppException catch (exception) {
      return AppFailure<Membership>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Membership>(
        UnexpectedFailure(
          'Unexpected error updating membership.',
          code: 'membership_update_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
