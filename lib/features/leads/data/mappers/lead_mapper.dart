import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/lead.dart';
import '../../domain/value_objects/lead_source.dart';
import '../../domain/value_objects/lead_status.dart';
import '../../domain/value_objects/lead_sync_status.dart';
import '../dtos/lead_dto.dart';

@lazySingleton
final class LeadMapper {
  const LeadMapper();

  Lead toEntity(LeadDto dto) {
    return Lead(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      name: dto.name,
      document: dto.document,
      source: sourceToEntity(dto.sourceCode, label: dto.sourceLabel),
      responsibleUserId: dto.responsibleUserId,
      status: statusToEntity(dto.status),
      score: dto.score,
      disqualificationReason: dto.disqualificationReason,
      convertedCustomerId: dto.convertedCustomerId,
      convertedOpportunityId: dto.convertedOpportunityId,
      createdAt: dto.createdAt,
      contactedAt: dto.contactedAt,
      qualifiedAt: dto.qualifiedAt,
      convertedAt: dto.convertedAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  LeadDto toDto(Lead entity) {
    return LeadDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      name: entity.name,
      document: entity.document,
      sourceCode: entity.source.code,
      sourceLabel: entity.source.label,
      responsibleUserId: entity.responsibleUserId,
      status: statusToDto(entity.status),
      score: entity.score,
      disqualificationReason: entity.disqualificationReason,
      convertedCustomerId: entity.convertedCustomerId,
      convertedOpportunityId: entity.convertedOpportunityId,
      createdAt: entity.createdAt,
      contactedAt: entity.contactedAt,
      qualifiedAt: entity.qualifiedAt,
      convertedAt: entity.convertedAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  LeadSource sourceToEntity(String code, {required String label}) {
    return leadSourceFromCode(code, label: label) ??
        LeadSource.custom(code, label: label);
  }

  LeadStatus statusToEntity(String value) {
    return switch (value) {
      'new' => LeadStatus.newLead,
      'contacted' => LeadStatus.contacted,
      'qualified' => LeadStatus.qualified,
      'disqualified' => LeadStatus.disqualified,
      'converted' => LeadStatus.converted,
      _ => throw ValidationException(
        'Invalid lead status.',
        code: 'invalid_lead_status',
        cause: value,
      ),
    };
  }

  String statusToDto(LeadStatus status) {
    return switch (status) {
      LeadStatus.newLead => 'new',
      LeadStatus.contacted => 'contacted',
      LeadStatus.qualified => 'qualified',
      LeadStatus.disqualified => 'disqualified',
      LeadStatus.converted => 'converted',
    };
  }

  LeadSyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => LeadSyncStatus.pending,
      'syncing' => LeadSyncStatus.syncing,
      'synced' => LeadSyncStatus.synced,
      'failed' => LeadSyncStatus.failed,
      'conflict' => LeadSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid lead sync status.',
        code: 'invalid_lead_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(LeadSyncStatus status) {
    return switch (status) {
      LeadSyncStatus.pending => 'pending',
      LeadSyncStatus.syncing => 'syncing',
      LeadSyncStatus.synced => 'synced',
      LeadSyncStatus.failed => 'failed',
      LeadSyncStatus.conflict => 'conflict',
    };
  }
}
