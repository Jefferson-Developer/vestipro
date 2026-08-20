enum AppEnvironmentName { development, staging, production }

final class AppEnvironment {
  const AppEnvironment({
    required this.name,
    required this.flavor,
    required this.appName,
  });

  static const development = AppEnvironment(
    name: AppEnvironmentName.development,
    flavor: 'dev',
    appName: 'VestiPro Dev',
  );

  static const staging = AppEnvironment(
    name: AppEnvironmentName.staging,
    flavor: 'staging',
    appName: 'VestiPro Staging',
  );

  static const production = AppEnvironment(
    name: AppEnvironmentName.production,
    flavor: 'prod',
    appName: 'VestiPro',
  );

  static AppEnvironment current = development;

  final AppEnvironmentName name;
  final String flavor;
  final String appName;

  String get value => name.name;

  bool get isProduction => name == AppEnvironmentName.production;

  static void configure(AppEnvironment environment) {
    current = environment;
  }

  static AppEnvironment fromDartDefine([
    String value = const String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    ),
  ]) {
    return fromName(value);
  }

  static AppEnvironment fromName(String value) {
    switch (value.trim().toLowerCase()) {
      case 'development':
      case 'dev':
        return development;
      case 'staging':
      case 'stage':
        return staging;
      case 'production':
      case 'prod':
        return production;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Expected development, staging, or production.',
        );
    }
  }
}
