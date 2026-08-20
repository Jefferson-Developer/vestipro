import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/environment/app_environment.dart';
import '../features/settings/presentation/bloc/about_app_bloc.dart';
import '../features/settings/settings.dart';
import 'injection.dart';
import 'vestipro_bloc_observer.dart';

void bootstrap(AppEnvironment environment) {
  Bloc.observer = const VestiProBlocObserver();
  configureDependencies(environment);
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
      home: AboutAppPage(createBloc: () => getIt<AboutAppBloc>()),
    );
  }
}
