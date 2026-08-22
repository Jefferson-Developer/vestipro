/// Centralized catalog of Firebase Performance Monitoring custom trace names
/// for VestiPro (TASK-019). No call site is allowed to pass a raw string
/// literal to [PerformanceMonitor.startTrace]/`wrapAsync` — every trace name
/// must be referenced through a constant defined here, so the catalog stays
/// consistent and grep-able across the whole app (same reasoning as
/// `AnalyticsEvents` for analytics event names).
///
/// Naming convention: `snake_case`, ending in `_duration`.
///
/// A trace name must stay stable once real historical data has been
/// collected under it in the Firebase console — renaming a trace here after
/// that point loses continuity with any dashboard/alert already built on top
/// of the old name.
final class PerformanceTraces {
  const PerformanceTraces._();

  /// Duration of one incremental sync round-trip against Firestore (the
  /// offline sync engine, EPIC-14). Planned in this task; connected to a
  /// real sync flow once the sync engine itself lands (TASK-107+).
  static const String syncIncrementalDuration = 'sync_incremental_duration';

  /// Duration of submitting an order, from the moment the representative
  /// confirms it to the moment the server-side pricing/number/approval
  /// pipeline finishes (TASK-101). Planned in this task; connected to a real
  /// order-submission flow once it lands.
  static const String orderSubmitDuration = 'order_submit_duration';

  /// Duration of loading the product catalog for a representative,
  /// including grade/pricing resolution (EPIC-10). Planned in this task;
  /// connected to a real catalog-loading flow once it lands.
  static const String catalogLoadDuration = 'catalog_load_duration';

  /// Duration of resolving the app's dependency graph during bootstrap
  /// (`configureDependencies`, `lib/app/injection.dart`). Planned in this
  /// task as the candidate to validate the `PerformanceMonitor` mechanism
  /// end-to-end ahead of the traces above landing with their real flows —
  /// not yet wired into `bootstrap.dart` itself; see "Known risk" in
  /// `docs/architecture/performance.md` for why.
  static const String dependencyInjectionSetupDuration =
      'dependency_injection_setup_duration';

  /// Every trace name currently defined in the catalog. Used by tests to
  /// assert there are no duplicates and by tooling that needs to enumerate
  /// the full catalog.
  static const List<String> values = [
    syncIncrementalDuration,
    orderSubmitDuration,
    catalogLoadDuration,
    dependencyInjectionSetupDuration,
  ];
}
