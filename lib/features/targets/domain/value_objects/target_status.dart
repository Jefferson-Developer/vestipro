/// Lifecycle of a [Target] (meta comercial), distinct from sync status.
///
/// A [Target] is only counted for the "duas metas ativas sobrepostas" overlap
/// rule (`CreateTargetUseCase`) while it is [active] — a [draft] target can be
/// prepared/edited freely before it starts competing for a period/dimension
/// slot, and a [closed] target (period over, or manually closed) no longer
/// blocks a new one from being created over the same period.
enum TargetStatus { draft, active, closed }
