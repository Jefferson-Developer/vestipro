final class FunnelDashboardFilters {
  const FunnelDashboardFilters({
    required this.monthKey,
    this.companyId,
    this.teamId,
    this.sellerId,
    this.lossStageId,
  });

  final String monthKey;
  final String? companyId;
  final String? teamId;
  final String? sellerId;
  final String? lossStageId;

  FunnelDashboardFilters copyWith({
    String? monthKey,
    String? companyId,
    String? teamId,
    String? sellerId,
    String? lossStageId,
    bool clearTeamId = false,
    bool clearSellerId = false,
    bool clearLossStageId = false,
  }) => FunnelDashboardFilters(
    monthKey: monthKey ?? this.monthKey,
    companyId: companyId ?? this.companyId,
    teamId: clearTeamId ? null : (teamId ?? this.teamId),
    sellerId: clearSellerId ? null : (sellerId ?? this.sellerId),
    lossStageId: clearLossStageId ? null : (lossStageId ?? this.lossStageId),
  );

  Map<String, String> toQueryParameters() {
    final result = <String, String>{'month': monthKey};
    final company = companyId;
    final team = teamId;
    final seller = sellerId;
    final lossStage = lossStageId;
    if (company != null) result['companyId'] = company;
    if (team != null) result['teamId'] = team;
    if (seller != null) result['sellerId'] = seller;
    if (lossStage != null) result['lossStageId'] = lossStage;
    return result;
  }

  factory FunnelDashboardFilters.fromQueryParameters(
    Map<String, String> query, {
    required String fallbackMonthKey,
    String? fallbackCompanyId,
  }) => FunnelDashboardFilters(
    monthKey: query['month'] ?? fallbackMonthKey,
    companyId: query['companyId'] ?? fallbackCompanyId,
    teamId: query['teamId'],
    sellerId: query['sellerId'],
    lossStageId: query['lossStageId'],
  );
}
