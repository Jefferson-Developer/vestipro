import '../../domain/entities/portfolio_assignment.dart';

sealed class AssignPortfolioEvent {
  const AssignPortfolioEvent();
}

final class AssignPortfolioStarted extends AssignPortfolioEvent {
  const AssignPortfolioStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class AssignPortfolioRefreshRequested extends AssignPortfolioEvent {
  const AssignPortfolioRefreshRequested();
}

final class AssignPortfolioSellerSelected extends AssignPortfolioEvent {
  const AssignPortfolioSellerSelected(this.userId);

  final String? userId;
}

final class AssignPortfolioTeamSelected extends AssignPortfolioEvent {
  const AssignPortfolioTeamSelected(this.teamId);

  final String? teamId;
}

final class AssignPortfolioScopeTypeChanged extends AssignPortfolioEvent {
  const AssignPortfolioScopeTypeChanged(this.scopeType);

  final PortfolioAssignmentScopeType scopeType;
}

final class AssignPortfolioCustomerIdChanged extends AssignPortfolioEvent {
  const AssignPortfolioCustomerIdChanged(this.customerId);

  final String customerId;
}

final class AssignPortfolioRegionChanged extends AssignPortfolioEvent {
  const AssignPortfolioRegionChanged(this.region);

  final String region;
}

final class AssignPortfolioSegmentChanged extends AssignPortfolioEvent {
  const AssignPortfolioSegmentChanged(this.segment);

  final String segment;
}

final class AssignPortfolioSubmitted extends AssignPortfolioEvent {
  const AssignPortfolioSubmitted();
}
