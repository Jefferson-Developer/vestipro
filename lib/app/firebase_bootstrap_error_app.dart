import 'package:flutter/material.dart';

import '../core/environment/app_environment.dart';

/// Fallback UI shown instead of a blank/crashed screen when
/// `Firebase.initializeApp` fails during `bootstrap`.
///
/// Kept independent from [VestiProApp] on purpose: dependency injection and
/// the app router are never configured when Firebase fails to initialize, so
/// this widget must not rely on either.
class FirebaseBootstrapErrorApp extends StatelessWidget {
  const FirebaseBootstrapErrorApp({
    required this.environment,
    required this.onRetry,
    this.errorDetail,
    super.key,
  });

  final AppEnvironment environment;
  final VoidCallback onRetry;

  /// Technical detail of the failure. Only rendered outside production, so a
  /// real user never sees internal exception messages.
  final String? errorDetail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: environment.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C73)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Não foi possível iniciar o VestiPro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verifique sua conexão com a internet e tente novamente. '
                    'Se o problema continuar, contate o suporte.',
                    textAlign: TextAlign.center,
                  ),
                  if (!environment.isProduction && errorDetail != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorDetail!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
