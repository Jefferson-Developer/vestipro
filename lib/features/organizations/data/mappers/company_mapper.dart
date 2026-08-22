import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/company.dart';
import '../../domain/value_objects/company_status.dart';
import '../dtos/company_dto.dart';

@lazySingleton
final class CompanyMapper {
  const CompanyMapper();

  Company toEntity(CompanyDto dto) {
    return Company(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      legalName: dto.legalName,
      taxId: dto.taxId,
      status: statusToEntity(dto.status),
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
    );
  }

  CompanyDto toDto(Company entity) {
    return CompanyDto(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      legalName: entity.legalName,
      taxId: entity.taxId,
      status: statusToDto(entity.status),
      version: entity.version,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
    );
  }

  CompanyStatus statusToEntity(String value) {
    return switch (value) {
      'active' => CompanyStatus.active,
      'suspended' => CompanyStatus.suspended,
      _ => throw ValidationException(
        'Invalid company status.',
        code: 'invalid_company_status',
        cause: value,
      ),
    };
  }

  String statusToDto(CompanyStatus status) {
    return switch (status) {
      CompanyStatus.active => 'active',
      CompanyStatus.suspended => 'suspended',
    };
  }
}
