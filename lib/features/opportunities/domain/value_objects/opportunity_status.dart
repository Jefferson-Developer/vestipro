/// Overall lifecycle status of an [Opportunity] (TASK-057), independent from
/// its pipeline [Opportunity.stageId].
///
/// `open` is the only non-terminal status. Both `won` and `lost` are
/// terminal: once reached, the opportunity cannot transition to any other
/// status (including back to `open`) through the normal use cases
/// (`MarkOpportunityWonUseCase`/`MarkOpportunityLostUseCase`). A reopen flow
/// is intentionally out of scope for this task — see
/// [isValidOpportunityStatusTransition] — and must be a future, explicit and
/// audited action, never a regular status edit.
enum OpportunityStatus { open, won, lost }
