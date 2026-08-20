import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../core/environment/app_environment.dart';
import '../core/navigation/navigation.dart';
import '../features/settings/presentation/bloc/about_app_bloc.dart';
import '../features/settings/settings.dart';
import 'injection.dart';
import 'vestipro_bloc_observer.dart';

void bootstrap(AppEnvironment environment) {
  usePathUrlStrategy();
  Bloc.observer = const VestiProBlocObserver();
  configureDependencies(environment);
  runApp(VestiProApp(environment: environment));
}

class VestiProApp extends StatelessWidget {
  const VestiProApp({required this.environment, this.router, super.key});

  final AppEnvironment environment;

  /// Overridable for tests. Defaults to the real [AppRouter] wired to the
  /// example module.
  final AppRouter? router;

  @override
  Widget build(BuildContext context) {
    final appRouter =
        router ??
        AppRouter(
          aboutAppPageBuilder: (context, orgId) =>
              AboutAppPage(createBloc: () => getIt<AboutAppBloc>()),
        );

    return MaterialApp.router(
      title: environment.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C73)),
        useMaterial3: true,
      ),
      routerConfig: appRouter.router,
    );
  }
}
