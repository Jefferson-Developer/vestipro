/// Whether a [PipelineStage] (TASK-058) represents a terminal outcome of
/// the funnel, and which one.
///
/// `none` is a routine, non-terminal column: an Opportunity resting there
/// stays [OpportunityStatus.open]. `won`/`lost` mark the column that
/// represents a closed deal outcome — moving an Opportunity into one of
/// these must always go through `MarkOpportunityWonUseCase`/
/// `MarkOpportunityLostUseCase` (mandatory reason), never a plain
/// `UpdateOpportunityStageUseCase` column move. See `SalesPipelineBloc`.
enum PipelineStageTerminalType { none, won, lost }
