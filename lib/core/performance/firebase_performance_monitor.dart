import 'dart:developer' as developer;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:injectable/injectable.dart';

import 'performance_monitor.dart';

/// Extra guard applied on top of every `start()`/`stop()` SDK call, in
/// addition to their own `try`/`catch` — belt-and-suspenders so a broken or
/// unresponsive Performance Monitoring native channel (observed while
/// building this task: an unregistered channel can leave `Trace.start()`
/// pending forever instead of rejecting quickly, unlike most other Firebase
/// plugins) can never hang the measured flow, only add a bounded delay
/// before falling back to "unmeasured, but otherwise unaffected" (same
/// reasoning as `remoteConfigFetchGuardTimeout`, TASK-018).
const Duration performanceTraceOperationTimeout = Duration(seconds: 3);

/// [PerformanceMonitor] backed by the real Firebase Performance Monitoring
/// SDK.
///
/// Defensive by design: every public method swallows any error the
/// underlying SDK itself throws (logging it locally instead) so that a
/// broken/unavailable Performance Monitoring channel never becomes the
/// reason a measured flow fails (same reasoning as `FirebaseCrashReporter`,
/// TASK-016, and `FirebaseAnalyticsService`, TASK-017) — and never hangs it
/// either, thanks to [performanceTraceOperationTimeout].
@LazySingleton(as: PerformanceMonitor)
final class FirebasePerformanceMonitor implements PerformanceMonitor {
  FirebasePerformanceMonitor(this._performance);

  final FirebasePerformance _performance;

  /// Traces started via [startTrace], keyed by name, so a later [stopTrace]
  /// call with the same name can find and stop the right [Trace] instance.
  /// `wrapAsync` intentionally does not use this map: it keeps its own local
  /// [Trace] instance so concurrent calls sharing the same trace name never
  /// overwrite each other's entry here.
  final Map<String, Trace> _namedTraces = {};

  @override
  Future<void> startTrace(
    String name, {
    Map<String, String>? attributes,
  }) async {
    try {
      final trace = _performance.newTrace(name);
      _applyAttributes(trace, attributes);
      await trace.start().timeout(performanceTraceOperationTimeout);
      _namedTraces[name] = trace;
    } catch (error, stackTrace) {
      _logFailure('startTrace', name, error, stackTrace);
    }
  }

  @override
  Future<void> stopTrace(String name) async {
    final trace = _namedTraces.remove(name);
    if (trace == null) return;

    try {
      await trace.stop().timeout(performanceTraceOperationTimeout);
    } catch (error, stackTrace) {
      _logFailure('stopTrace', name, error, stackTrace);
    }
  }

  @override
  Future<T> wrapAsync<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  }) async {
    Trace? trace;
    try {
      trace = _performance.newTrace(name);
      _applyAttributes(trace, attributes);
      await trace.start().timeout(performanceTraceOperationTimeout);
    } catch (error, stackTrace) {
      // The trace itself failed to start (e.g. SDK/channel unavailable or
      // unresponsive) — the measured operation must still run normally,
      // just unmeasured.
      _logFailure('wrapAsync.start', name, error, stackTrace);
      trace = null;
    }

    try {
      return await action();
    } finally {
      final startedTrace = trace;
      if (startedTrace != null) {
        try {
          await startedTrace.stop().timeout(performanceTraceOperationTimeout);
        } catch (error, stackTrace) {
          _logFailure('wrapAsync.stop', name, error, stackTrace);
        }
      }
    }
  }

  void _applyAttributes(Trace trace, Map<String, String>? attributes) {
    if (attributes == null) return;
    for (final entry in attributes.entries) {
      trace.putAttribute(entry.key, entry.value);
    }
  }

  void _logFailure(
    String operation,
    String traceName,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      'PerformanceMonitor.$operation failed for trace "$traceName".',
      name: 'vestipro.performance_monitor',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
