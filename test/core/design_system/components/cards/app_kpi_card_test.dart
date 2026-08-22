import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppKpiCard', () {
    testWidgets('renders label and value', (tester) async {
      await pumpApp(
        tester,
        const AppKpiCard(label: 'Faturamento (mês)', value: 'R\$ 128.400'),
      );

      expect(find.text('Faturamento (mês)'), findsOneWidget);
      expect(find.text('R\$ 128.400'), findsOneWidget);
    });

    testWidgets('renders a positive variation with the "up" icon', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppKpiCard(
          label: 'Faturamento (mês)',
          value: 'R\$ 128.400',
          trend: AppKpiTrend.up,
          trendPercentage: 12.5,
          trendLabel: 'vs. mês anterior',
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('+12.5%'), findsOneWidget);
      expect(find.text('vs. mês anterior'), findsOneWidget);
    });

    testWidgets('renders a negative variation with the "down" icon', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppKpiCard(
          label: 'Clientes ativos',
          value: '412',
          trend: AppKpiTrend.down,
          trendPercentage: -8.3,
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.text('-8.3%'), findsOneWidget);
    });

    testWidgets('renders a neutral variation with the "flat" icon', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppKpiCard(
          label: 'Ticket médio',
          value: 'R\$ 340',
          trend: AppKpiTrend.neutral,
          trendPercentage: 0,
        ),
      );

      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
    });

    testWidgets('renders no trend row when trendPercentage is omitted', (
      tester,
    ) async {
      await pumpApp(tester, const AppKpiCard(label: 'Pedidos', value: '58'));

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
      expect(find.byIcon(Icons.trending_flat), findsNothing);
    });
  });
}
