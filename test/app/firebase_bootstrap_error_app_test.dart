import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/firebase_bootstrap_error_app.dart';
import 'package:vestipro/core/environment/app_environment.dart';

void main() {
  group('FirebaseBootstrapErrorApp', () {
    testWidgets('renders a friendly error screen with a retry action', (
      tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        FirebaseBootstrapErrorApp(
          environment: AppEnvironment.development,
          errorDetail: 'FirebaseInitializationException: boom',
          onRetry: () => retried = true,
        ),
      );

      expect(find.text('Não foi possível iniciar o VestiPro'), findsOneWidget);
      expect(
        find.text('FirebaseInitializationException: boom'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Tentar novamente'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('hides the technical error detail in production', (
      tester,
    ) async {
      await tester.pumpWidget(
        FirebaseBootstrapErrorApp(
          environment: AppEnvironment.production,
          errorDetail: 'FirebaseInitializationException: boom',
          onRetry: () {},
        ),
      );

      expect(find.text('Não foi possível iniciar o VestiPro'), findsOneWidget);
      expect(find.text('FirebaseInitializationException: boom'), findsNothing);
    });
  });
}
