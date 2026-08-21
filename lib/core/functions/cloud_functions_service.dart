import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../errors/errors.dart';
import 'app_client_metadata.dart';
import 'cloud_functions_exception_mapper.dart';

/// Reports how long a callable Cloud Function took to answer, and whether it
/// succeeded — a seam for TASK-019 (Firebase Performance Monitoring) to wire
/// a real trace into without touching [CloudFunctionsService] itself. Not
/// called by default.
typedef CloudFunctionCallMetricsRecorder =
    void Function({
      required String functionName,
      required Duration elapsed,
      required bool success,
      required int attempt,
    });

void _noopMetricsRecorder({
  required String functionName,
  required Duration elapsed,
  required bool success,
  required int attempt,
}) {}

/// Standardized entry point for every callable Cloud Function call in the
/// app (TASK-015) — no feature is allowed to call `cloud_functions` on its
/// own. Handles what a raw `FirebaseFunctions.httpsCallable(...)` call does
/// not:
///
/// - a correlation id per call, generated client-side and echoed back by the
///   function for end-to-end tracing;
/// - app version, build number and platform sent as metadata (under the
///   reserved `_meta` key, so it never collides with a function's own
///   request fields — see `functions/src/shared/callable-meta.ts`);
/// - controlled retry with linear backoff, applied only to the transient
///   error codes in [transientCloudFunctionsErrorCodes] — never to
///   validation/permission errors;
/// - response time measurement, reported through [CloudFunctionCallMetricsRecorder];
/// - every `FirebaseFunctionsException` converted to the app's own
///   [AppException] hierarchy before it leaves this class.
///
/// Authentication itself needs no extra wiring: `cloud_functions` already
/// attaches the current Firebase Auth user's ID token automatically, as
/// long as [FirebaseAuth] and [FirebaseFunctions] share the same
/// `FirebaseApp` (true for every instance in this app — both come from
/// `Firebase.app()` via `lib/app/injection_module.dart`). [requireAuth] only
/// adds an explicit, fail-fast client-side guard for calls that are known to
/// need a signed-in user — it is not, and must never be treated as, the
/// real authorization check: that always happens server-side too (see
/// `AGENTS.md`).
@lazySingleton
final class CloudFunctionsService {
  CloudFunctionsService(
    this._functions,
    this._firebaseAuth,
    this._metadataProvider,
  ) : _uuid = const Uuid(),
      _onCallMetrics = _noopMetricsRecorder;

  /// Same as the default constructor, but lets tests substitute [uuid] (for
  /// a deterministic correlation id) and/or [onCallMetrics] (to assert on
  /// reported response times) without injectable trying to resolve either
  /// as a DI dependency — the default (unnamed) constructor is the one
  /// injectable generates a provider for, and it only takes the three real
  /// dependencies above.
  @visibleForTesting
  CloudFunctionsService.withDependencies(
    this._functions,
    this._firebaseAuth,
    this._metadataProvider, {
    Uuid? uuid,
    CloudFunctionCallMetricsRecorder? onCallMetrics,
  }) : _uuid = uuid ?? const Uuid(),
       _onCallMetrics = onCallMetrics ?? _noopMetricsRecorder;

  static const int maxAttempts = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 300);

  final FirebaseFunctions _functions;
  final FirebaseAuth _firebaseAuth;
  final AppClientMetadataProvider _metadataProvider;
  final Uuid _uuid;
  final CloudFunctionCallMetricsRecorder _onCallMetrics;

  /// Calls the callable Cloud Function [name] with [data], returning its
  /// response cast to [T].
  ///
  /// Set [requireAuth] to `true` for a function that never makes sense to
  /// call while signed out — this throws [UnauthorizedException]
  /// immediately, before any network call, instead of waiting for the
  /// server to reject it.
  Future<T> call<T>(
    String name, {
    Map<String, dynamic> data = const {},
    bool requireAuth = false,
    Duration? timeout,
  }) async {
    if (requireAuth && _firebaseAuth.currentUser == null) {
      throw const UnauthorizedException(
        'É necessário estar autenticado para chamar esta função.',
      );
    }

    final metadata = await _metadataProvider.resolve();
    final payload = <String, dynamic>{
      ...data,
      '_meta': {'correlationId': _uuid.v4(), ...metadata.toJson()},
    };

    final callable = _functions.httpsCallable(
      name,
      options: timeout == null ? null : HttpsCallableOptions(timeout: timeout),
    );

    var attempt = 0;
    while (true) {
      attempt++;
      final stopwatch = Stopwatch()..start();
      try {
        final result = await callable.call<T>(payload);
        _onCallMetrics(
          functionName: name,
          elapsed: stopwatch.elapsed,
          success: true,
          attempt: attempt,
        );
        return result.data;
      } on FirebaseFunctionsException catch (exception, stackTrace) {
        _onCallMetrics(
          functionName: name,
          elapsed: stopwatch.elapsed,
          success: false,
          attempt: attempt,
        );

        final canRetry =
            transientCloudFunctionsErrorCodes.contains(exception.code) &&
            attempt < maxAttempts;
        if (!canRetry) {
          throw mapCloudFunctionsExceptionToAppException(exception, stackTrace);
        }

        await Future<void>.delayed(retryBaseDelay * attempt);
      }
    }
  }
}
