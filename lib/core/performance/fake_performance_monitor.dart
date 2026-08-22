import 'performance_monitor.dart';

/// A trace recorded by [FakePerformanceMonitor], kept for assertions in
/// tests.
final class RecordedPerformanceTrace {
  const RecordedPerformanceTrace(this.name, this.attributes);

  final String name;
  final Map<String, String>? attributes;

  @override
  String toString() => 'RecordedPerformanceTrace($name, $attributes)';
}

/// In-memory [PerformanceMonitor] for unit/BLoC tests (TASK-019) — lets a
/// use case, repository or BLoC that measures a critical flow be tested
/// without depending on the real `firebase_performance` SDK or a platform
/// channel mock (same reasoning as `FakeAnalyticsService`, TASK-017).
final class FakePerformanceMonitor implements PerformanceMonitor {
  final List<RecordedPerformanceTrace> startedTraces = [];
  final List<String> stoppedTraces = [];

  @override
  Future<void> startTrace(
    String name, {
    Map<String, String>? attributes,
  }) async {
    startedTraces.add(RecordedPerformanceTrace(name, attributes));
  }

  @override
  Future<void> stopTrace(String name) async {
    stoppedTraces.add(name);
  }

  @override
  Future<T> wrapAsync<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  }) async {
    await startTrace(name, attributes: attributes);
    try {
      return await action();
    } finally {
      await stopTrace(name);
    }
  }

  /// Clears every recorded trace — useful between test cases that reuse the
  /// same fake instance.
  void reset() {
    startedTraces.clear();
    stoppedTraces.clear();
  }
}
