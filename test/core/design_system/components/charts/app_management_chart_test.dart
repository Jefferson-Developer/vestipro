import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppManagementChart — empty dataset', () {
    testWidgets('renders the empty state when there are no series', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppManagementChart(type: AppChartType.line, series: []),
      );

      expect(find.text('Sem dados para exibir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the empty state when every series has no points', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppManagementChart(
          type: AppChartType.bar,
          series: [AppChartSeries(label: 'Faturamento', points: [])],
        ),
      );

      expect(find.text('Sem dados para exibir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppManagementChart — single-point dataset', () {
    testWidgets('renders a single-point line series without throwing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        const AppManagementChart(
          type: AppChartType.line,
          series: [
            AppChartSeries(
              label: 'Faturamento',
              points: [AppChartPoint(x: 1, y: 100, label: 'Jan')],
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final semantics = tester.getSemantics(find.byType(AppManagementChart));
      expect(semantics.label, contains('Gráfico de linha'));
      expect(semantics.label, contains('Jan'));
      handle.dispose();
    });

    testWidgets('renders a single-point bar series without throwing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        const AppManagementChart(
          type: AppChartType.bar,
          series: [
            AppChartSeries(
              label: 'Faturamento',
              points: [AppChartPoint(x: 1, y: 100, label: 'Jan')],
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final semantics = tester.getSemantics(find.byType(AppManagementChart));
      expect(semantics.label, contains('Gráfico de barra'));
      handle.dispose();
    });

    testWidgets(
      'the accessible data table toggle shows the same exact value as text',
      (tester) async {
        await pumpApp(
          tester,
          const AppManagementChart(
            type: AppChartType.line,
            series: [
              AppChartSeries(
                label: 'Faturamento',
                points: [AppChartPoint(x: 1, y: 100, label: 'Jan')],
              ),
            ],
          ),
        );

        // The toggle button starts as "switch to table" (table icon).
        expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.table_chart_outlined));
        await tester.pump();

        expect(find.textContaining('Jan: 100'), findsOneWidget);
        // After switching, the toggle now offers to go back to the chart.
        expect(find.byIcon(Icons.show_chart), findsOneWidget);
      },
    );
  });

  group('AppManagementChart — multi-series dataset', () {
    testWidgets('renders the series legend and does not throw', (tester) async {
      await pumpApp(
        tester,
        const AppManagementChart(
          type: AppChartType.bar,
          series: [
            AppChartSeries(
              label: 'Este ano',
              points: [
                AppChartPoint(x: 1, y: 100, label: 'Jan'),
                AppChartPoint(x: 2, y: 140, label: 'Fev'),
              ],
            ),
            AppChartSeries(
              label: 'Ano anterior',
              points: [
                AppChartPoint(x: 1, y: 90, label: 'Jan'),
                AppChartPoint(x: 2, y: 110, label: 'Fev'),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Este ano'), findsOneWidget);
      expect(find.text('Ano anterior'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
