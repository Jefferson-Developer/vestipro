import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/bootstrap.dart';
import 'package:vestipro/app/injection.dart';
import 'package:vestipro/core/environment/app_environment.dart';

void main() {
  setUp(() async {
    await resetDependencies();
    configureDependencies(AppEnvironment.staging);
  });

  tearDown(resetDependencies);

  testWidgets('renders the configured about app module', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const VestiProApp(environment: AppEnvironment.staging),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('VestiPro Staging'), findsWidgets);
    expect(find.text('Ambiente'), findsOneWidget);
    expect(find.text('staging'), findsOneWidget);
  });
}
