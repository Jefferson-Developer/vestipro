import 'value_objects/opportunity_status.dart';

/// Allowed status transitions for the Opportunity pipeline (TASK-057).
///
/// `won` and `lost` are terminal and intentionally map to an empty set: once
/// an Opportunity is closed (won or lost) it can never move to any other
/// status through this table, including back to `open`. Reopening a closed
/// Opportunity is left out of this task's scope and, when implemented, must
/// be an explicit and audited action rather than a regular edit.
const Map<OpportunityStatus, Set<OpportunityStatus>>
_allowedOpportunityStatusTransitions =
    <OpportunityStatus, Set<OpportunityStatus>>{
      OpportunityStatus.open: <OpportunityStatus>{
        OpportunityStatus.won,
        OpportunityStatus.lost,
      },
      OpportunityStatus.won: <OpportunityStatus>{},
      OpportunityStatus.lost: <OpportunityStatus>{},
    };

bool isValidOpportunityStatusTransition(
  OpportunityStatus from,
  OpportunityStatus to,
) {
  return _allowedOpportunityStatusTransitions[from]?.contains(to) ?? false;
}
