/// Lifecycle of a Lead through the CRM qualification pipeline.
///
/// The standard path is `newLead -> contacted -> qualified -> converted`.
/// `disqualified` is reachable from `newLead` or `contacted` (a lead can be
/// discarded before or after first contact). Both `disqualified` and
/// `converted` are terminal: neither can transition to any other status, so
/// (for example) a disqualified lead can never become `converted`. See
/// [isValidLeadStatusTransition] for the full transition table.
enum LeadStatus { newLead, contacted, qualified, disqualified, converted }
