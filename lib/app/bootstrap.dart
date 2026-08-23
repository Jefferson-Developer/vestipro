import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../core/design_system/design_system.dart';
import '../core/environment/app_environment.dart';
import '../core/errors/errors.dart';
import '../core/feature_flags/feature_flags.dart';
import '../core/navigation/navigation.dart';
import '../core/services/services.dart';
import '../features/authentication/authentication.dart';
import '../features/authentication/presentation/bloc/forgot_password_bloc.dart';
import '../features/authentication/presentation/bloc/login_bloc.dart';
import '../features/authentication/presentation/bloc/sign_up_bloc.dart';
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
  configureGlobalErrorHandlers();
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

/// Routes every uncaught Flutter framework error and every uncaught async
/// error to [CrashReporter] (TASK-016), preserving whatever default handling
/// (console logging, the debug red screen) was already installed.
///
/// [resolveCrashReporter] defaults to resolving [CrashReporter] from [getIt]
/// — but only inside the handler closures below, i.e. only when an error is
/// actually reported, never eagerly at bootstrap time. Overridable so tests
/// can assert on the wiring itself without a real Firebase Crashlytics
/// instance.
@visibleForTesting
void configureGlobalErrorHandlers({
  CrashReporter Function()? resolveCrashReporter,
}) {
  final resolve = resolveCrashReporter ?? () => getIt<CrashReporter>();

  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutterOnError?.call(details);
    if (isUnexpectedError(details.exception)) {
      unawaited(
        resolve().recordError(
          details.exception,
          details.stack,
          reason: details.library,
          fatal: true,
        ),
      );
    }
  };

  // Uses the real `dart:ui` singleton directly, not
  // `WidgetsBinding.instance.platformDispatcher` — in a `flutter_test`
  // environment the latter is a `TestPlatformDispatcher` whose `onError`
  // setter is a deliberate no-op, so setting it there would silently never
  // fire. `PlatformDispatcher.instance` behaves identically in production
  // and is what Firebase's own Crashlytics setup guide recommends.
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (isUnexpectedError(error)) {
      unawaited(resolve().recordError(error, stackTrace, fatal: true));
    }
    return previousPlatformOnError?.call(error, stackTrace) ?? true;
  };
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
          aboutAppPageBuilder: (context, orgId) => AboutAppPage(
            createBloc: () => getIt<AboutAppBloc>(),
            showInsightsShortcut: _resolveShowInsightsShortcut(),
          ),
          loginPageBuilder: (context) =>
              LoginPage(createBloc: () => getIt<LoginBloc>()),
          signUpPageBuilder: (context) =>
              SignUpPage(createBloc: () => getIt<SignUpBloc>()),
          forgotPasswordPageBuilder: (context) =>
              ForgotPasswordPage(createBloc: () => getIt<ForgotPasswordBloc>()),
        );

    return MaterialApp.router(
      title: environment.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter.router,
    );
  }
}

/// Resolves whether the `feature_insights_enabled` shortcut (TASK-018)
/// should be shown in the reference module, defaulting to `false` (its own
/// code-defined default in `FeatureFlagRegistry`) whenever
/// [FeatureFlagService] itself cannot be resolved — e.g. a widget test that
/// renders [VestiProApp] without going through the real [bootstrap] (and
/// therefore without `Firebase.initializeApp`, which [FeatureFlagService]
/// transitively depends on). A feature flag must never keep the rest of
/// the app from rendering; worst case, the flagged shortcut simply stays
/// hidden, exactly like it would if Remote Config itself were unreachable.
bool _resolveShowInsightsShortcut() {
  try {
    return getIt<FeatureFlagService>().isEnabled(
      FeatureFlagRegistry.featureInsightsEnabled,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to resolve FeatureFlagService; hiding the flagged shortcut.',
      name: 'vestipro.bootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
