import 'value_objects/lead_status.dart';

/// Allowed status transitions for the Lead qualification pipeline (TASK-055).
///
/// `disqualified` and `converted` are terminal and intentionally map to an
/// empty set: once a Lead is disqualified it can never become `converted`,
/// and a converted Lead can never move back to `newLead`/`qualified`.
const Map<LeadStatus, Set<LeadStatus>> _allowedLeadStatusTransitions =
    <LeadStatus, Set<LeadStatus>>{
      LeadStatus.newLead: <LeadStatus>{
        LeadStatus.contacted,
        LeadStatus.disqualified,
      },
      LeadStatus.contacted: <LeadStatus>{
        LeadStatus.qualified,
        LeadStatus.disqualified,
      },
      LeadStatus.qualified: <LeadStatus>{LeadStatus.converted},
      LeadStatus.disqualified: <LeadStatus>{},
      LeadStatus.converted: <LeadStatus>{},
    };

bool isValidLeadStatusTransition(LeadStatus from, LeadStatus to) {
  return _allowedLeadStatusTransitions[from]?.contains(to) ?? false;
}
