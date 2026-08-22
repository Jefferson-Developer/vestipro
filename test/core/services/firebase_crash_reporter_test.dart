import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/core/services/services.dart';

class _MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

void main() {
  group('FirebaseCrashReporter', () {
    late _MockFirebaseCrashlytics crashlytics;
    late _MockAppClientMetadataProvider metadataProvider;
    late FirebaseCrashReporter reporter;

    setUp(() {
      crashlytics = _MockFirebaseCrashlytics();
      metadataProvider = _MockAppClientMetadataProvider();

      when(
        () => crashlytics.setCustomKey(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => crashlytics.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<String?>(named: 'reason'),
          fatal: any<bool>(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});
      when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});
      when(() => metadataProvider.resolve()).thenAnswer(
        (_) async => const AppClientMetadata(
          appVersion: '1.2.3',
          buildNumber: '45',
          platform: 'test',
        ),
      );

      reporter = FirebaseCrashReporter(
        crashlytics,
        AppEnvironment.development,
        metadataProvider,
      );
    });

    test(
      'recordError attaches base context once, then forwards to the SDK',
      () async {
        await reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          reason: 'unit test',
          fatal: true,
        );
        await reporter.recordError(Exception('boom again'), null);

        verify(
          () => crashlytics.setCustomKey('environment', 'development'),
        ).called(1);
        verify(() => crashlytics.setCustomKey('appVersion', '1.2.3')).called(1);
        verify(() => crashlytics.setCustomKey('platform', 'test')).called(1);
        verify(
          () => crashlytics.recordError(
            any<dynamic>(),
            any<StackTrace?>(),
            reason: any<String?>(named: 'reason'),
            fatal: any<bool>(named: 'fatal'),
          ),
        ).called(2);
      },
    );

    test(
      'setUserIdentifier forwards to the SDK, empty string clears it',
      () async {
        await reporter.setUserIdentifier('user-123');
        verify(() => crashlytics.setUserIdentifier('user-123')).called(1);

        await reporter.setUserIdentifier(null);
        verify(() => crashlytics.setUserIdentifier('')).called(1);
      },
    );

    test('setCustomKey forwards to the SDK', () async {
      await reporter.setCustomKey('module', 'crm');
      verify(() => crashlytics.setCustomKey('module', 'crm')).called(1);
    });

    test(
      'never throws when the underlying SDK call fails (defensive coding)',
      () async {
        when(
          () => crashlytics.recordError(
            any<dynamic>(),
            any<StackTrace?>(),
            reason: any<String?>(named: 'reason'),
            fatal: any<bool>(named: 'fatal'),
          ),
        ).thenThrow(Exception('SDK unavailable'));
        when(
          () => crashlytics.setCustomKey(any(), any()),
        ).thenThrow(Exception('SDK unavailable'));
        when(
          () => crashlytics.setUserIdentifier(any()),
        ).thenThrow(Exception('SDK unavailable'));

        await expectLater(
          reporter.recordError(Exception('boom'), StackTrace.current),
          completes,
        );
        await expectLater(reporter.setUserIdentifier('user-123'), completes);
        await expectLater(reporter.setCustomKey('module', 'crm'), completes);
      },
    );
  });
}
