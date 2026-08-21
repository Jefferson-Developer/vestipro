import 'app/bootstrap.dart';
import 'core/environment/app_environment.dart';

Future<void> main() async {
  await bootstrap(AppEnvironment.staging);
}
