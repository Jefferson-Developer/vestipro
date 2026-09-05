import 'package:injectable/injectable.dart';

import '../../../opportunities/opportunities.dart';
import '../entities/funnel_dashboard_snapshot.dart';

@injectable
final class BuildFunnelDashboardSnapshotUseCase {
  const BuildFunnelDashboardSnapshotUseCase();

  FunnelDashboardSnapshot call({
    required List<PipelineStage> stages,
    required List<Opportunity> opportunities,
    required DateTime now,
    String? lossStageId,
  }) {
    final ordered = List<PipelineStage>.of(stages)
      ..sort((a, b) => a.order.compareTo(b.order));
    final byStage = <String, List<Opportunity>>{
      for (final stage in ordered) stage.id: <Opportunity>[],
    };
    for (final opportunity in opportunities) {
      byStage[opportunity.stageId]?.add(opportunity);
    }

    final rows = <FunnelStageSnapshot>[];
    for (var index = 0; index < ordered.length; index++) {
      final stage = ordered[index];
      final entries = byStage[stage.id]!;
      final open = entries.where(
        (item) => item.status == OpportunityStatus.open,
      );
      final openList = open.toList(growable: false);
      final agingTotal = openList.fold<double>(
        0,
        (sum, item) => sum + now.difference(item.updatedAt).inMinutes / 1440,
      );
      final nextCount = index + 1 < ordered.length
          ? byStage[ordered[index + 1].id]!.length
          : null;
      rows.add(
        FunnelStageSnapshot(
          stageId: stage.id,
          name: stage.name,
          colorHex: stage.colorHex,
          order: stage.order,
          opportunityCount: entries.length,
          totalValue: entries.fold(0, (sum, item) => sum + item.estimatedValue),
          weightedValue: entries.fold(
            0,
            (sum, item) => sum + item.revenueForecast,
          ),
          averageAgingDays: openList.isEmpty ? 0 : agingTotal / openList.length,
          conversionToNext: nextCount == null
              ? null
              : entries.isEmpty
              ? 0
              : nextCount / entries.length * 100,
        ),
      );
    }

    final reasons = <String, FunnelLossReasonSnapshot>{};
    for (final opportunity in opportunities) {
      if (opportunity.status != OpportunityStatus.lost ||
          (lossStageId != null &&
              (opportunity.outcomeFromStageId ?? opportunity.stageId) !=
                  lossStageId)) {
        continue;
      }
      final id = opportunity.lostReasonId;
      if (id == null || id.isEmpty) continue;
      final current = reasons[id];
      reasons[id] = FunnelLossReasonSnapshot(
        reasonId: id,
        description: opportunity.lostReason ?? id,
        count: (current?.count ?? 0) + 1,
      );
    }
    final ranking = reasons.values.toList()
      ..sort((a, b) {
        final count = b.count.compareTo(a.count);
        return count != 0 ? count : a.description.compareTo(b.description);
      });
    return FunnelDashboardSnapshot(
      stages: rows,
      lossReasons: ranking,
      pipelineWeightedValue: rows.fold(
        0,
        (sum, row) => sum + row.weightedValue,
      ),
      generatedAt: now,
    );
  }
}
