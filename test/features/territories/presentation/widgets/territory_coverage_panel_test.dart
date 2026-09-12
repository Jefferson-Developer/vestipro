import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/territories/territories.dart';

void main() {
  testWidgets('renders coverage rows for manager action', (tester) async {
    const dashboard = TerritoryCoverageDashboard(
      rows: [
        CustomerCoverageRow(
          customerId: 'customer-1',
          status: CoverageStatus.highPotential,
          priority: 70,
          reason: 'Cliente de alto potencial para proxima visita.',
        ),
      ],
      conflicts: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TerritoryCoveragePanel(dashboard: dashboard)),
      ),
    );

    expect(find.text('Cobertura de carteira'), findsOneWidget);
    expect(find.text('Cliente customer-1'), findsOneWidget);
    expect(find.text('Alto potencial'), findsOneWidget);
  });
}
