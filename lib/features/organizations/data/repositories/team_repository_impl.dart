import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_data_source.dart';
import '../mappers/team_mapper.dart';

@LazySingleton(as: TeamRepository)
final class TeamRepositoryImpl implements TeamRepository {
  const TeamRepositoryImpl({required this.dataSource, required this.mapper});

  final TeamDataSource dataSource;
  final TeamMapper mapper;

  @override
  Future<AppResult<Team>> create({
    required String id,
    required String organizationId,
    required String name,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dto = mapper.toDto(
        Team(
          id: id,
          organizationId: organizationId,
          name: name,
          version: 1,
          createdAt: now,
          createdBy: createdBy,
          updatedAt: now,
          updatedBy: createdBy,
        ),
      );

      final createdDto = await dataSource.create(dto);
      return AppSuccess<Team>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<Team>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Team>(
        UnexpectedFailure(
          'Unexpected error creating team.',
          code: 'team_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Team>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final dtos = await dataSource.listByOrganization(organizationId);
      return AppSuccess<List<Team>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<Team>>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<List<Team>>(
        UnexpectedFailure(
          'Unexpected error listing teams.',
          code: 'team_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Team>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final dto = await dataSource.getById(
        organizationId: organizationId,
        id: id,
      );
      if (dto == null) {
        return AppFailure<Team>(
          const NotFoundFailure('Team not found.', code: 'team_not_found'),
        );
      }
      return AppSuccess<Team>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Team>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Team>(
        UnexpectedFailure(
          'Unexpected error loading team.',
          code: 'team_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Team>> addMember({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) async {
    try {
      final updatedDto = await dataSource.addMember(
        organizationId: organizationId,
        id: id,
        userId: userId,
        updatedAt: DateTime.now().toUtc(),
        updatedBy: updatedBy,
      );
      return AppSuccess<Team>(mapper.toEntity(updatedDto));
    } on AppException catch (exception) {
      return AppFailure<Team>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Team>(
        UnexpectedFailure(
          'Unexpected error adding member to team.',
          code: 'team_add_member_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
