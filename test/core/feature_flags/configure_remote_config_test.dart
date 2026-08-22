import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';

class _MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _FakeRemoteConfigSettings extends Fake implements RemoteConfigSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRemoteConfigSettings());
    registerFallbackValue(<String, Object>{});
  });

  group('configureRemoteConfig', () {
    late _MockFirebaseRemoteConfig remoteConfig;

    setUp(() {
      remoteConfig = _MockFirebaseRemoteConfig();
      when(
        () => remoteConfig.setConfigSettings(any()),
      ).thenAnswer((_) async {});
      when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {});
      when(() => remoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
    });

    test('calls setConfigSettings, then setDefaults, then fetchAndActivate — '
        'in that order', () async {
      await configureRemoteConfig(
        remoteConfig,
        environment: AppEnvironment.development,
      );

      verifyInOrder([
        () => remoteConfig.setConfigSettings(any()),
        () => remoteConfig.setDefaults(any()),
        () => remoteConfig.fetchAndActivate(),
      ]);
    });

    test('passes every registered flag default to setDefaults', () async {
      await configureRemoteConfig(
        remoteConfig,
        environment: AppEnvironment.development,
      );

      final defaults =
          verify(() => remoteConfig.setDefaults(captureAny())).captured.single
              as Map<String, Object>;
      expect(defaults, FeatureFlagRegistry.remoteConfigDefaults);
    });

    test('setDefaults completes before this function returns, so no caller '
        'can read a flag before the local defaults are applied', () async {
      var defaultsApplied = false;
      when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {
        defaultsApplied = true;
      });

      await configureRemoteConfig(
        remoteConfig,
        environment: AppEnvironment.development,
      );

      expect(defaultsApplied, isTrue);
    });

    test('uses an aggressive minimum fetch interval in development', () async {
      await configureRemoteConfig(
        remoteConfig,
        environment: AppEnvironment.development,
      );

      final settings =
          verify(
                () => remoteConfig.setConfigSettings(captureAny()),
              ).captured.single
              as RemoteConfigSettings;
      expect(settings.minimumFetchInterval, Duration.zero);
    });

    test('uses a conservative minimum fetch interval in production', () async {
      await configureRemoteConfig(
        remoteConfig,
        environment: AppEnvironment.production,
      );

      final settings =
          verify(
                () => remoteConfig.setConfigSettings(captureAny()),
              ).captured.single
              as RemoteConfigSettings;
      expect(settings.minimumFetchInterval, const Duration(hours: 1));
    });

    test('never throws when setConfigSettings fails, and skips setDefaults/'
        'fetchAndActivate afterwards', () async {
      when(
        () => remoteConfig.setConfigSettings(any()),
      ).thenThrow(Exception('unavailable'));

      await expectLater(
        configureRemoteConfig(
          remoteConfig,
          environment: AppEnvironment.development,
        ),
        completes,
      );

      verifyNever(() => remoteConfig.setDefaults(any()));
      verifyNever(() => remoteConfig.fetchAndActivate());
    });

    test('never throws when setDefaults fails', () async {
      when(
        () => remoteConfig.setDefaults(any()),
      ).thenThrow(Exception('unavailable'));

      await expectLater(
        configureRemoteConfig(
          remoteConfig,
          environment: AppEnvironment.development,
        ),
        completes,
      );

      verifyNever(() => remoteConfig.fetchAndActivate());
    });

    test('never throws when fetchAndActivate fails — defaults were already '
        'applied by that point', () async {
      when(
        () => remoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('network unreachable'));

      await expectLater(
        configureRemoteConfig(
          remoteConfig,
          environment: AppEnvironment.development,
        ),
        completes,
      );

      verify(() => remoteConfig.setDefaults(any())).called(1);
    });
  });
}
