import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/value_objects/company_status.dart';
import '../datasources/company_data_source.dart';
import '../mappers/company_mapper.dart';

@LazySingleton(as: CompanyRepository)
final class CompanyRepositoryImpl implements CompanyRepository {
  const CompanyRepositoryImpl({required this.dataSource, required this.mapper});

  final CompanyDataSource dataSource;
  final CompanyMapper mapper;

  @override
  Future<AppResult<Company>> create({
    required String id,
    required String organizationId,
    required String name,
    String? legalName,
    String? taxId,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dto = mapper.toDto(
        Company(
          id: id,
          organizationId: organizationId,
          name: name,
          legalName: legalName,
          taxId: taxId,
          status: CompanyStatus.active,
          version: 1,
          createdAt: now,
          createdBy: createdBy,
          updatedAt: now,
          updatedBy: createdBy,
        ),
      );

      final createdDto = await dataSource.create(dto);
      return AppSuccess<Company>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<Company>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Company>(
        UnexpectedFailure(
          'Unexpected error creating company.',
          code: 'company_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Company>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final dtos = await dataSource.listByOrganization(organizationId);
      return AppSuccess<List<Company>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<Company>>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<List<Company>>(
        UnexpectedFailure(
          'Unexpected error listing companies.',
          code: 'company_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Company>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final dto = await dataSource.getById(
        organizationId: organizationId,
        id: id,
      );
      if (dto == null) {
        return AppFailure<Company>(
          const NotFoundFailure(
            'Company not found.',
            code: 'company_not_found',
          ),
        );
      }
      return AppSuccess<Company>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Company>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Company>(
        UnexpectedFailure(
          'Unexpected error loading company.',
          code: 'company_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Company>> update({
    required String organizationId,
    required String id,
    required String name,
    String? legalName,
    String? taxId,
    required CompanyStatus status,
    required String updatedBy,
  }) async {
    try {
      final updatedDto = await dataSource.update(
        organizationId: organizationId,
        id: id,
        name: name,
        legalName: legalName,
        taxId: taxId,
        status: mapper.statusToDto(status),
        updatedAt: DateTime.now().toUtc(),
        updatedBy: updatedBy,
      );
      return AppSuccess<Company>(mapper.toEntity(updatedDto));
    } on AppException catch (exception) {
      return AppFailure<Company>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Company>(
        UnexpectedFailure(
          'Unexpected error updating company.',
          code: 'company_update_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
