import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/services/services.dart';

class _MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  group('configureCrashlytics', () {
    late _MockFirebaseCrashlytics crashlytics;

    setUp(() {
      crashlytics = _MockFirebaseCrashlytics();
      when(
        () => crashlytics.setCrashlyticsCollectionEnabled(any()),
      ).thenAnswer((_) async {});
    });

    test('disables collection for development', () {
      configureCrashlytics(
        crashlytics,
        environment: AppEnvironment.development,
      );

      verify(
        () => crashlytics.setCrashlyticsCollectionEnabled(false),
      ).called(1);
    });

    test('enables collection for staging', () {
      configureCrashlytics(crashlytics, environment: AppEnvironment.staging);

      verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
    });

    test('enables collection for production', () {
      configureCrashlytics(crashlytics, environment: AppEnvironment.production);

      verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
    });
  });
}
