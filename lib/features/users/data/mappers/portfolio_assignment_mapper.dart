import 'package:injectable/injectable.dart';

import '../../domain/entities/portfolio_assignment.dart';
import '../dtos/portfolio_assignment_dto.dart';

@lazySingleton
final class PortfolioAssignmentMapper {
  const PortfolioAssignmentMapper();

  PortfolioAssignment toEntity(PortfolioAssignmentDto dto) {
    return PortfolioAssignment(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      userId: dto.userId,
      teamId: dto.teamId,
      scope: _scopeFromDto(dto),
      status: PortfolioAssignmentStatusCode.fromCode(dto.status),
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      endedAt: dto.endedAt,
      endedBy: dto.endedBy,
      deletedAt: dto.deletedAt,
    );
  }

  PortfolioAssignmentDto toDto(PortfolioAssignment assignment) {
    return PortfolioAssignmentDto(
      id: assignment.id,
      organizationId: assignment.organizationId,
      companyId: assignment.companyId,
      userId: assignment.userId,
      teamId: assignment.teamId,
      scopeType: assignment.scope.type.code,
      customerId: assignment.scope.customerId,
      region: assignment.scope.region,
      segment: assignment.scope.segment,
      status: assignment.status.code,
      version: assignment.version,
      createdAt: assignment.createdAt,
      createdBy: assignment.createdBy,
      updatedAt: assignment.updatedAt,
      updatedBy: assignment.updatedBy,
      endedAt: assignment.endedAt,
      endedBy: assignment.endedBy,
      deletedAt: assignment.deletedAt,
    );
  }

  PortfolioAssignmentScope _scopeFromDto(PortfolioAssignmentDto dto) {
    final type = PortfolioAssignmentScopeTypeCode.fromCode(dto.scopeType);
    return switch (type) {
      PortfolioAssignmentScopeType.customer =>
        PortfolioAssignmentScope.customer(dto.customerId ?? ''),
      PortfolioAssignmentScopeType.criteria =>
        PortfolioAssignmentScope.criteria(
          region: dto.region,
          segment: dto.segment,
        ),
    };
  }
}
