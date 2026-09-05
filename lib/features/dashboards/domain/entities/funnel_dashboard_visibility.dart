enum FunnelDashboardVisibilityMode { none, own, team, organization }

final class FunnelDashboardVisibility {
  const FunnelDashboardVisibility({
    required this.mode,
    required this.allowedSellerIds,
    required this.allowedTeamIds,
  });

  final FunnelDashboardVisibilityMode mode;
  final Set<String> allowedSellerIds;
  final Set<String> allowedTeamIds;

  bool allowsSeller(String sellerId) =>
      mode == FunnelDashboardVisibilityMode.organization ||
      allowedSellerIds.contains(sellerId);
}
