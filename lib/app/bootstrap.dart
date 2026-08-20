import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/environment/app_environment.dart';
import '../features/settings/settings.dart';
import 'vestipro_bloc_observer.dart';

void bootstrap(AppEnvironment environment) {
  Bloc.observer = const VestiProBlocObserver();
  AppEnvironment.configure(environment);
  runApp(VestiProApp(environment: environment));
}

class VestiProApp extends StatelessWidget {
  const VestiProApp({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: environment.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C73)),
        useMaterial3: true,
      ),
      home: AboutAppPage(
        getAboutApp: createAboutAppUseCase(environment),
        searchNotes: createSearchAboutAppNotesUseCase(environment),
        submitDiagnostics: createSubmitAboutAppDiagnosticsUseCase(environment),
      ),
    );
  }
}
