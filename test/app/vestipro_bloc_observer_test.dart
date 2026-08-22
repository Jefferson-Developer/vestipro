import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/vestipro_bloc_observer.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/services/services.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_event.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_state.dart';

void main() {
  test('VestiProBlocObserver handles transitions without throwing', () {
    const observer = VestiProBlocObserver();
    final transition = Transition<AboutAppEvent, AboutAppState>(
      currentState: const AboutAppState.initial(),
      event: const AboutAppEvent.started(),
      nextState: const AboutAppState.loading(),
    );

    expect(
      () => observer.onTransition(_ObserverTestBloc(), transition),
      returnsNormally,
    );
  });

  group('VestiProBlocObserver.onError', () {
    test('reports an unexpected error to CrashReporter as non-fatal', () async {
      final reporter = _RecordingCrashReporter();
      final observer = VestiProBlocObserver(crashReporter: reporter);

      observer.onError(
        _ObserverTestBloc(),
        const UnknownException('unexpected'),
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      expect(reporter.recordedExceptions, hasLength(1));
      expect(reporter.recordedFatalFlags, equals(<bool>[false]));
    });

    test('does not report an expected/handled business exception to '
        'CrashReporter', () async {
      final reporter = _RecordingCrashReporter();
      final observer = VestiProBlocObserver(crashReporter: reporter);

      observer.onError(
        _ObserverTestBloc(),
        const ValidationException('invalid'),
        StackTrace.current,
      );
      await Future<void>.delayed(Duration.zero);

      expect(reporter.recordedExceptions, isEmpty);
    });
  });
}

final class _ObserverTestBloc extends Bloc<AboutAppEvent, AboutAppState> {
  _ObserverTestBloc() : super(const AboutAppState.initial());
}

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
