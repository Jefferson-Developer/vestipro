import 'package:injectable/injectable.dart';

import '../core/environment/app_environment.dart';
import '../features/settings/data/models/about_app_seed_model.dart';

@module
abstract class AppInjectionModule {
  @lazySingleton
  AppEnvironment get appEnvironment => AppEnvironment.current;

  @lazySingleton
  AboutAppSeedModel aboutAppSeedModel(AppEnvironment environment) {
    return AboutAppSeedModel.fromEnvironment(environment);
  }
}
