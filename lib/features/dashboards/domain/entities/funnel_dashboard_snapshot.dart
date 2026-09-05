final class FunnelStageSnapshot {
  const FunnelStageSnapshot({
    required this.stageId,
    required this.name,
    required this.colorHex,
    required this.order,
    required this.opportunityCount,
    required this.totalValue,
    required this.weightedValue,
    required this.averageAgingDays,
    required this.conversionToNext,
  });

  final String stageId;
  final String name;
  final String colorHex;
  final int order;
  final int opportunityCount;
  final double totalValue;
  final double weightedValue;
  final double averageAgingDays;
  final double? conversionToNext;
}

final class FunnelLossReasonSnapshot {
  const FunnelLossReasonSnapshot({
    required this.reasonId,
    required this.description,
    required this.count,
  });

  final String reasonId;
  final String description;
  final int count;
}

final class FunnelDashboardSnapshot {
  const FunnelDashboardSnapshot({
    required this.stages,
    required this.lossReasons,
    required this.pipelineWeightedValue,
    required this.generatedAt,
  });

  final List<FunnelStageSnapshot> stages;
  final List<FunnelLossReasonSnapshot> lossReasons;
  final double pipelineWeightedValue;
  final DateTime generatedAt;
}
