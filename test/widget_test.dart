import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/bootstrap.dart';
import 'package:vestipro/core/environment/app_environment.dart';

void main() {
  testWidgets('renders the configured environment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const VestiProApp(environment: AppEnvironment.staging),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('VestiPro Staging'), findsOneWidget);
    expect(find.text('staging'), findsOneWidget);
  });
}
