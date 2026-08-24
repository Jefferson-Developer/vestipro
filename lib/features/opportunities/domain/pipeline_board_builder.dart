import 'entities/opportunity.dart';
import 'entities/pipeline_column.dart';
import 'entities/pipeline_stage.dart';
import 'value_objects/opportunity_status.dart';
import 'value_objects/pipeline_stage_terminal_type.dart';

/// Pure domain builder that groups [opportunities] by [PipelineStage]
/// (TASK-058), computing the per-column "active" count/value total shown on
/// the board header.
///
/// Kept independent from `SalesPipelineBloc` so the grouping/aggregation
/// rule is unit-testable without a Bloc, a repository or a widget: given the
/// same stages/opportunities it always returns the same columns, in stage
/// [PipelineStage.order].
List<PipelineColumn> buildPipelineColumns({
  required List<PipelineStage> stages,
  required List<Opportunity> opportunities,
}) {
  final sortedStages = List<PipelineStage>.of(stages)
    ..sort((a, b) => a.order.compareTo(b.order));

  return sortedStages
      .map((stage) {
        final stageOpportunities =
            opportunities
                .where((opportunity) => opportunity.stageId == stage.id)
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final activeOpportunities = stageOpportunities
            .where((opportunity) => _isActiveForStage(opportunity, stage))
            .toList(growable: false);

        return PipelineColumn(
          stage: stage,
          opportunities: stageOpportunities,
          activeCount: activeOpportunities.length,
          activeValueTotal: activeOpportunities.fold<double>(
            0,
            (sum, opportunity) => sum + opportunity.estimatedValue,
          ),
        );
      })
      .toList(growable: false);
}

/// Whether [opportunity] counts toward its current stage's "active"
/// aggregates: open for a routine column, or matching the column's own
/// won/lost outcome for a terminal one (TASK-058's "apenas oportunidades
/// ativas" rule — never every Opportunity that happens to still carry that
/// `stageId`).
bool _isActiveForStage(Opportunity opportunity, PipelineStage stage) {
  return switch (stage.terminalType) {
    PipelineStageTerminalType.none =>
      opportunity.status == OpportunityStatus.open,
    PipelineStageTerminalType.won =>
      opportunity.status == OpportunityStatus.won,
    PipelineStageTerminalType.lost =>
      opportunity.status == OpportunityStatus.lost,
  };
}
