import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/organization.dart';
import '../../domain/value_objects/organization_settings.dart';
import '../../domain/value_objects/organization_status.dart';
import '../dtos/organization_dto.dart';
import '../dtos/organization_settings_dto.dart';

@lazySingleton
final class OrganizationMapper {
  const OrganizationMapper();

  Organization toEntity(OrganizationDto dto) {
    return Organization(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      settings: settingsToEntity(dto.settings),
      status: _statusToEntity(dto.status),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
    );
  }

  OrganizationDto toDto(Organization entity) {
    return OrganizationDto(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      settings: settingsToDto(entity.settings),
      status: _statusToDto(entity.status),
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
    );
  }

  OrganizationSettings settingsToEntity(OrganizationSettingsDto dto) {
    return OrganizationSettings(
      currency: dto.currency,
      country: dto.country,
      defaultLanguage: dto.defaultLanguage,
      segment: dto.segment,
      maxTeamsPerUser: dto.maxTeamsPerUser,
      requiredCustomerFields: dto.requiredCustomerFields,
      customerAddressTypes: dto.customerAddressTypes,
      customerContactTypes: dto.customerContactTypes,
      allowMultipleCollectionsPerProduct:
          dto.allowMultipleCollectionsPerProduct,
      stockReservationExpiresInMinutes: dto.stockReservationExpiresInMinutes,
      positivacaoPeriodGranularity: dto.positivacaoPeriodGranularity,
      positivacaoEligibleOrderStatuses: dto.positivacaoEligibleOrderStatuses,
      positivacaoMinOrderValue: dto.positivacaoMinOrderValue,
      rankingVisibilityMode: dto.rankingVisibilityMode,
    );
  }

  OrganizationSettingsDto settingsToDto(OrganizationSettings settings) {
    return OrganizationSettingsDto(
      currency: settings.currency,
      country: settings.country,
      defaultLanguage: settings.defaultLanguage,
      segment: settings.segment,
      maxTeamsPerUser: settings.maxTeamsPerUser,
      requiredCustomerFields: settings.requiredCustomerFields,
      customerAddressTypes: settings.customerAddressTypes,
      customerContactTypes: settings.customerContactTypes,
      allowMultipleCollectionsPerProduct:
          settings.allowMultipleCollectionsPerProduct,
      stockReservationExpiresInMinutes:
          settings.stockReservationExpiresInMinutes,
      positivacaoPeriodGranularity: settings.positivacaoPeriodGranularity,
      positivacaoEligibleOrderStatuses:
          settings.positivacaoEligibleOrderStatuses,
      positivacaoMinOrderValue: settings.positivacaoMinOrderValue,
      rankingVisibilityMode: settings.rankingVisibilityMode,
    );
  }

  OrganizationStatus _statusToEntity(String value) {
    return switch (value) {
      'active' => OrganizationStatus.active,
      'suspended' => OrganizationStatus.suspended,
      _ => throw ValidationException(
        'Invalid organization status.',
        code: 'invalid_organization_status',
        cause: value,
      ),
    };
  }

  String _statusToDto(OrganizationStatus status) {
    return switch (status) {
      OrganizationStatus.active => 'active',
      OrganizationStatus.suspended => 'suspended',
    };
  }
}
