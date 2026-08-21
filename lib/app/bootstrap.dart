import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../core/environment/app_environment.dart';
import '../core/errors/errors.dart';
import '../core/navigation/navigation.dart';
import '../features/settings/presentation/bloc/about_app_bloc.dart';
import '../features/settings/settings.dart';
import '../firebase_options.dart';
import 'firebase_bootstrap_error_app.dart';
import 'injection.dart';
import 'vestipro_bloc_observer.dart';

/// Central bootstrap for every entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`). Firebase must be initialized here, and only here: no
/// feature is allowed to call `Firebase.initializeApp` on its own.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    final exception = FirebaseInitializationException(
      'Falha ao inicializar o Firebase para o ambiente '
      '"${environment.value}".',
      cause: error,
      stackTrace: stackTrace,
    );
    _reportBootstrapFailure(exception);
    runApp(
      FirebaseBootstrapErrorApp(
        environment: environment,
        errorDetail: exception.toString(),
        onRetry: () => bootstrap(environment),
      ),
    );
    return;
  }

  usePathUrlStrategy();
  Bloc.observer = const VestiProBlocObserver();
  configureDependencies(environment);
  runApp(VestiProApp(environment: environment));
}

void _reportBootstrapFailure(FirebaseInitializationException exception) {
  developer.log(
    exception.toString(),
    name: 'vestipro.bootstrap',
    level: 1000,
    error: exception.cause,
    stackTrace: exception.stackTrace,
  );
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
