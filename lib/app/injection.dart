import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../core/environment/app_environment.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
void configureDependencies(AppEnvironment environment) {
  AppEnvironment.configure(environment);
  getIt.init(environment: environment.flavor);
}

Future<void> resetDependencies() {
  return getIt.reset();
}
