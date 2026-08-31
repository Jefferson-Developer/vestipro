/// Central abstraction for device network connectivity (TASK-109, EPIC-14).
///
/// No feature is allowed to depend on `package:connectivity_plus` directly —
/// every connectivity read/observation goes through this interface, so the
/// concrete plugin stays swappable and mockable in tests, same reasoning as
/// [AnalyticsService]/[CrashReporter] for their own SDKs.
///
/// [SyncScheduler] (TASK-109) is this interface's first consumer, triggering
/// a sync cycle when connectivity is regained; the connectivity indicator
/// (TASK-113) is expected to reuse this exact same abstraction rather than
/// read the plugin a second time.
abstract interface class ConnectivityService {
  /// Whether the device currently has *some* network connectivity (Wi-Fi,
  /// mobile data, ethernet, ...). This is a reachability signal, not a
  /// guarantee that Firebase itself is reachable (e.g. a captive portal or a
  /// VPN-only network can still report connected here).
  Future<bool> get isConnected;

  /// Emits the current connectivity state every time it changes. Does not
  /// necessarily emit the current value immediately upon subscription for
  /// every implementation — callers that need the current value right away
  /// should also read [isConnected] once.
  Stream<bool> get onConnectivityChanged;
}
