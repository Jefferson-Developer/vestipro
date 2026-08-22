import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/bootstrap.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/services/services.dart';

class _RecordingCrashReporter implements CrashReporter {
  final List<Object> recordedExceptions = <Object>[];
  final List<bool> recordedFatalFlags = <bool>[];

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedExceptions.add(exception);
    recordedFatalFlags.add(fatal);
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserIdentifier(String? userId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? originalFlutterOnError;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
  });

  test('forwards an unexpected FlutterError.onError report to CrashReporter as '
      'fatal, without dropping the previous handler', () async {
    var previousHandlerCalled = false;
    FlutterError.onError = (_) => previousHandlerCalled = true;
    final reporter = _RecordingCrashReporter();

    configureGlobalErrorHandlers(resolveCrashReporter: () => reporter);

    final details = FlutterErrorDetails(
      exception: const UnknownException('unexpected'),
      stack: StackTrace.current,
    );
    FlutterError.onError!(details);
    await Future<void>.delayed(Duration.zero);

    expect(previousHandlerCalled, isTrue);
    expect(reporter.recordedExceptions, hasLength(1));
    expect(reporter.recordedFatalFlags, equals(<bool>[true]));
  });

  test('does not forward an expected/handled AppException from '
      'FlutterError.onError to CrashReporter', () async {
    FlutterError.onError = (_) {};
    final reporter = _RecordingCrashReporter();

    configureGlobalErrorHandlers(resolveCrashReporter: () => reporter);

    FlutterError.onError!(
      FlutterErrorDetails(
        exception: const ValidationException('invalid'),
        stack: StackTrace.current,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(reporter.recordedExceptions, isEmpty);
  });

  test(
    'forwards an unexpected PlatformDispatcher.onError report to '
    'CrashReporter as fatal and preserves the previous handler result',
    () async {
      final previousOnError = PlatformDispatcher.instance.onError;
      addTearDown(() => PlatformDispatcher.instance.onError = previousOnError);

      var previousHandlerCalled = false;
      PlatformDispatcher.instance.onError = (error, stack) {
        previousHandlerCalled = true;
        return false;
      };
      final reporter = _RecordingCrashReporter();

      configureGlobalErrorHandlers(resolveCrashReporter: () => reporter);

      final handled = PlatformDispatcher.instance.onError!(
        const UnknownException('unexpected'),
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      expect(previousHandlerCalled, isTrue);
      expect(handled, isFalse);
      expect(reporter.recordedExceptions, hasLength(1));
      expect(reporter.recordedFatalFlags, equals(<bool>[true]));
    },
  );
}
