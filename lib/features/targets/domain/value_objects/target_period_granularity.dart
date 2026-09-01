/// The reporting cadence of a [Target]'s period (`startDate`..`endDate`).
///
/// Purely descriptive of how the period was chosen at creation (e.g. a UI
/// filtering by "metas mensais") — it never itself derives `startDate`/
/// `endDate`, and nothing in the domain re-validates that the two dates
/// actually span exactly one of these cadences: the achievement dashboard
/// (TASK-116) and cadastro screen (TASK-115) are expected to use it to
/// pre-fill/group periods, not to constrain them.
enum TargetPeriodGranularity { monthly, quarterly, yearly }
