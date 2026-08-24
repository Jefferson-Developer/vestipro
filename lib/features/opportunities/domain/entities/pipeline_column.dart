import 'opportunity.dart';
import 'pipeline_stage.dart';

/// One rendered column of the sales pipeline board (TASK-058): a
/// [PipelineStage] plus the [Opportunity]s currently placed on it, and the
/// "active" count/value aggregates shown on the column header.
///
/// [opportunities] holds every Opportunity whose `stageId` matches
/// [stage], in whatever order `buildPipelineColumns` placed them (most
/// recently updated first) — including ones that are no longer "active" for
/// this stage (e.g. a routine column still holding a stale won/lost
/// Opportunity that was never moved). [activeCount]/[activeValueTotal] only
/// ever aggregate the subset [buildPipelineColumns] considers active for
/// this specific stage (open Opportunities for a routine stage; won/lost
/// Opportunities matching the stage's own outcome for a terminal one), per
/// TASK-058's "apenas oportunidades ativas" rule.
final class PipelineColumn {
  const PipelineColumn({
    required this.stage,
    required this.opportunities,
    required this.activeCount,
    required this.activeValueTotal,
  });

  final PipelineStage stage;
  final List<Opportunity> opportunities;
  final int activeCount;
  final double activeValueTotal;
}
