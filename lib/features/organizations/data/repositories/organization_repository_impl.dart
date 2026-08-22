import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../domain/value_objects/organization_settings.dart';
import '../../domain/value_objects/organization_status.dart';
import '../datasources/organization_data_source.dart';
import '../mappers/organization_mapper.dart';

@LazySingleton(as: OrganizationRepository)
final class OrganizationRepositoryImpl implements OrganizationRepository {
  const OrganizationRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OrganizationDataSource dataSource;
  final OrganizationMapper mapper;

  @override
  Future<AppResult<Organization>> create({
    required String id,
    required String name,
    required String slug,
    required OrganizationSettings settings,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dto = mapper.toDto(
        Organization(
          id: id,
          name: name,
          slug: slug,
          settings: settings,
          status: OrganizationStatus.active,
          createdAt: now,
          createdBy: createdBy,
          updatedAt: now,
          updatedBy: createdBy,
        ),
      );

      final createdDto = await dataSource.create(dto);
      return AppSuccess<Organization>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<Organization>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Organization>(
        UnexpectedFailure(
          'Unexpected error creating organization.',
          code: 'organization_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Organization>> getById(String id) async {
    try {
      final dto = await dataSource.getById(id);
      if (dto == null) {
        return AppFailure<Organization>(
          const NotFoundFailure(
            'Organization not found.',
            code: 'organization_not_found',
          ),
        );
      }
      return AppSuccess<Organization>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Organization>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Organization>(
        UnexpectedFailure(
          'Unexpected error loading organization.',
          code: 'organization_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Organization>> updateSettings({
    required String id,
    required OrganizationSettings settings,
    required String updatedBy,
  }) async {
    try {
      final updatedDto = await dataSource.updateSettings(
        id: id,
        settings: mapper.settingsToDto(settings),
        updatedAt: DateTime.now().toUtc(),
        updatedBy: updatedBy,
      );
      return AppSuccess<Organization>(mapper.toEntity(updatedDto));
    } on AppException catch (exception) {
      return AppFailure<Organization>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Organization>(
        UnexpectedFailure(
          'Unexpected error updating organization settings.',
          code: 'organization_update_settings_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
