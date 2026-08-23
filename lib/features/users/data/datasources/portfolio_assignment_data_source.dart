import '../dtos/portfolio_assignment_dto.dart';

abstract interface class PortfolioAssignmentDataSource {
  Future<PortfolioAssignmentDto> create(PortfolioAssignmentDto dto);

  Future<List<PortfolioAssignmentDto>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  });

  Future<List<PortfolioAssignmentDto>> listActiveByUser({
    required String organizationId,
    required String companyId,
    required String userId,
  });

  Future<PortfolioAssignmentDto?> findActiveCustomerAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
  });

  Future<PortfolioAssignmentDto> endAssignment({
    required String organizationId,
    required String id,
    required String status,
    required DateTime endedAt,
    required String endedBy,
  });
}
