import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';

class _MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockRemoteConfigValue extends Mock implements RemoteConfigValue {}

void main() {
  group('FirebaseFeatureFlagService', () {
    late _MockFirebaseRemoteConfig remoteConfig;
    late FirebaseFeatureFlagService service;

    const flagKey = FeatureFlagRegistry.featureInsightsEnabled;

    setUp(() {
      remoteConfig = _MockFirebaseRemoteConfig();
      service = FirebaseFeatureFlagService(remoteConfig);
    });

    void stubSource(ValueSource source) {
      final value = _MockRemoteConfigValue();
      when(() => value.source).thenReturn(source);
      when(() => remoteConfig.getValue(flagKey)).thenReturn(value);
    }

    test('returns the registry default without ever calling the SDK when '
        'Remote Config has not applied setDefaults/a fetch yet '
        '(ValueSource.valueStatic)', () {
      stubSource(ValueSource.valueStatic);

      expect(service.isEnabled(flagKey), isFalse);
      verifyNever(() => remoteConfig.getBool(any()));
    });

    test('reads the SDK value once Remote Config applied a real default '
        '(ValueSource.valueDefault)', () {
      stubSource(ValueSource.valueDefault);
      when(() => remoteConfig.getBool(flagKey)).thenReturn(true);

      expect(service.isEnabled(flagKey), isTrue);
      verify(() => remoteConfig.getBool(flagKey)).called(1);
    });

    test('reads the SDK value once a real value was fetched from the backend '
        '(ValueSource.valueRemote)', () {
      stubSource(ValueSource.valueRemote);
      when(() => remoteConfig.getBool(flagKey)).thenReturn(true);

      expect(service.isEnabled(flagKey), isTrue);
    });

    test('returns the registry default when the SDK itself throws (defensive '
        'coding, e.g. Remote Config unreachable)', () {
      when(
        () => remoteConfig.getValue(flagKey),
      ).thenThrow(Exception('SDK unavailable'));

      expect(service.isEnabled(flagKey), isFalse);
    });

    test(
      'throws for an unregistered flag key, same as FakeFeatureFlagService',
      () {
        expect(
          () => service.isEnabled('feature_never_registered'),
          throwsArgumentError,
        );
      },
    );
  });
}
