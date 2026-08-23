import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/security/security.dart';

/// Hand-written fake instead of a `mocktail` `Mock`: `FirebaseAppCheck.
/// activate` declares several deprecated, defaulted named parameters
/// (`webProvider`, `androidProvider`, `appleProvider`) alongside the ones
/// `configureAppCheck` actually passes — stubbing/verifying every possible
/// combination through `mocktail` would be far more brittle than simply
/// overriding the two methods under test and capturing what was passed.
class _FakeFirebaseAppCheck extends Fake implements FirebaseAppCheck {
  bool? tokenAutoRefreshEnabled;
  bool throwOnSetTokenAutoRefreshEnabled = false;
  bool throwOnActivate = false;

  int activateCallCount = 0;
  AndroidAppCheckProvider? capturedAndroidProvider;
  AppleAppCheckProvider? capturedAppleProvider;
  WebProvider? capturedWebProvider;

  @override
  Future<void> setTokenAutoRefreshEnabled(
    bool isTokenAutoRefreshEnabled,
  ) async {
    if (throwOnSetTokenAutoRefreshEnabled) {
      throw Exception('App Check SDK unavailable (simulated in test).');
    }
    tokenAutoRefreshEnabled = isTokenAutoRefreshEnabled;
  }

  @override
  Future<void> activate({
    WebProvider? webProvider,
    WebProvider? providerWeb,
    AndroidProvider androidProvider = AndroidProvider.playIntegrity,
    AppleProvider appleProvider = AppleProvider.deviceCheck,
    AndroidAppCheckProvider providerAndroid =
        const AndroidPlayIntegrityProvider(),
    AppleAppCheckProvider providerApple = const AppleDeviceCheckProvider(),
    WindowsAppCheckProvider providerWindows = const WindowsDebugProvider(),
  }) async {
    activateCallCount++;
    if (throwOnActivate) {
      throw Exception('App Check SDK unavailable (simulated in test).');
    }
    capturedAndroidProvider = providerAndroid;
    capturedAppleProvider = providerApple;
    capturedWebProvider = providerWeb ?? webProvider;
  }
}

void main() {
  group('configureAppCheck', () {
    late _FakeFirebaseAppCheck appCheck;

    setUp(() {
      appCheck = _FakeFirebaseAppCheck();
    });

    test('enables token auto-refresh for every environment', () async {
      await configureAppCheck(appCheck, environment: AppEnvironment.production);

      expect(appCheck.tokenAutoRefreshEnabled, isTrue);
    });

    test(
      'activates the Debug provider on every platform for development',
      () async {
        await configureAppCheck(
          appCheck,
          environment: AppEnvironment.development,
        );

        expect(appCheck.activateCallCount, 1);
        expect(appCheck.capturedAndroidProvider, isA<AndroidDebugProvider>());
        expect(appCheck.capturedAppleProvider, isA<AppleDebugProvider>());
        expect(appCheck.capturedWebProvider, isA<WebDebugProvider>());
      },
    );

    test(
      'activates the Debug provider on every platform for staging '
      '(ADR-0002: staging never touches the real Firebase project)',
      () async {
        await configureAppCheck(appCheck, environment: AppEnvironment.staging);

        expect(appCheck.activateCallCount, 1);
        expect(appCheck.capturedAndroidProvider, isA<AndroidDebugProvider>());
        expect(appCheck.capturedAppleProvider, isA<AppleDebugProvider>());
        expect(appCheck.capturedWebProvider, isA<WebDebugProvider>());
      },
    );

    test('activates Play Integrity (Android) and App Attest with DeviceCheck '
        'fallback (Apple) for production', () async {
      await configureAppCheck(appCheck, environment: AppEnvironment.production);

      expect(appCheck.activateCallCount, 1);
      expect(
        appCheck.capturedAndroidProvider,
        isA<AndroidPlayIntegrityProvider>(),
      );
      expect(
        appCheck.capturedAppleProvider,
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
      );
    });

    test('skips Web activation for production when no reCAPTCHA site key was '
        'provisioned via --dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY '
        '(default in this test binary)', () async {
      expect(appCheckWebRecaptchaSiteKey, isEmpty);

      await configureAppCheck(appCheck, environment: AppEnvironment.production);

      expect(appCheck.capturedWebProvider, isNull);
    });

    test(
      'never throws when setTokenAutoRefreshEnabled fails (defensive coding)',
      () async {
        appCheck.throwOnSetTokenAutoRefreshEnabled = true;

        await expectLater(
          configureAppCheck(appCheck, environment: AppEnvironment.production),
          completes,
        );
      },
    );

    test('never throws when activate fails (defensive coding)', () async {
      appCheck.throwOnActivate = true;

      await expectLater(
        configureAppCheck(appCheck, environment: AppEnvironment.development),
        completes,
      );
    });
  });
}
