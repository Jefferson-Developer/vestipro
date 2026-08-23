import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/bootstrap.dart';
import 'package:vestipro/app/injection.dart';
import 'package:vestipro/core/environment/app_environment.dart';

import 'support/fake_firebase_core.dart';

void main() {
  setUp(() async {
    await resetDependencies();
    // TASK-041: `VestiProApp`'s default `authGuard` is now the real
    // `SessionAuthGuard`, which resolves `FirebaseAuth` transitively
    // through `SessionService`/`AuthRepository` — so rendering it, even in
    // this reference-module test, requires Firebase to be initialized
    // first, exactly like production `bootstrap()` already guarantees.
    await setUpFakeFirebaseCore();
    configureDependencies(AppEnvironment.staging);
  });

  tearDown(() async {
    tearDownFakeFirebaseCore();
    await resetDependencies();
  });

  testWidgets(
    'renders the login screen by default (TASK-041: SessionAuthGuard is '
    'wired for real, and nobody is signed in here)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VestiProApp(environment: AppEnvironment.staging),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      // The "about app" placeholder module used to be reachable with no
      // session at all; since TASK-041 wired the real `SessionAuthGuard`
      // into `VestiProApp`, an unauthenticated request is correctly
      // redirected to the login screen instead.
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
      expect(find.text('Ambiente'), findsNothing);
    },
  );
}
