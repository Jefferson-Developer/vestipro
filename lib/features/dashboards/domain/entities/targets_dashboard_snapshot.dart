import '../../../targets/domain/entities/ranking_entry.dart';

enum TargetsDashboardLevel { organization, team, seller }

final class TargetsDashboardMetric {
  const TargetsDashboardMetric({
    required this.targetValue,
    required this.realizedValue,
    required this.achievementPercentage,
    required this.projectedValue,
    required this.projectedAchievementPercentage,
  });

  final double targetValue;
  final double realizedValue;
  final double achievementPercentage;
  final double projectedValue;
  final double projectedAchievementPercentage;

  double get gap => targetValue - realizedValue;
}

final class TargetsDashboardRow {
  const TargetsDashboardRow({
    required this.id,
    required this.label,
    required this.level,
    required this.metric,
    this.children = const <TargetsDashboardRow>[],
    this.isBelowTargetInsightActive = false,
  });

  final String id;
  final String label;
  final TargetsDashboardLevel level;
  final TargetsDashboardMetric? metric;
  final List<TargetsDashboardRow> children;
  final bool isBelowTargetInsightActive;
}

final class TargetsDashboardSnapshot {
  const TargetsDashboardSnapshot({
    required this.root,
    required this.ranking,
    required this.availableTeamIds,
    required this.availableSellerIds,
    required this.generatedAt,
    required this.isFromLocalCache,
  });

  final TargetsDashboardRow root;
  final List<RankingEntry> ranking;
  final List<String> availableTeamIds;
  final List<String> availableSellerIds;
  final DateTime? generatedAt;
  final bool isFromLocalCache;
}
