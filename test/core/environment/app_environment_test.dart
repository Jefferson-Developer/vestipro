import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/environment/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('resolves development names', () {
      expect(
        AppEnvironment.fromName('development'),
        AppEnvironment.development,
      );
      expect(AppEnvironment.fromName('dev'), AppEnvironment.development);
    });

    test('resolves staging names', () {
      expect(AppEnvironment.fromName('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromName('stage'), AppEnvironment.staging);
    });

    test('resolves production names', () {
      expect(AppEnvironment.fromName('production'), AppEnvironment.production);
      expect(AppEnvironment.fromName('prod'), AppEnvironment.production);
    });

    test('defaults dart-define resolution to development', () {
      expect(AppEnvironment.fromDartDefine(), AppEnvironment.development);
    });

    test('rejects unknown environment names', () {
      expect(
        () => AppEnvironment.fromName('qa'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
