import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

class _Client {
  const _Client({required this.id, required this.name, required this.city});

  final int id;
  final String name;
  final String city;
}

const _clients = <_Client>[
  _Client(id: 1, name: 'Ana Souza', city: 'Blumenau'),
  _Client(id: 2, name: 'Bruno Lima', city: 'Jaraguá do Sul'),
];

List<AppDataColumn<_Client>> _columns() => <AppDataColumn<_Client>>[
  AppDataColumn<_Client>(
    label: 'Cliente',
    cellBuilder: (_, client) => Text(client.name),
  ),
  AppDataColumn<_Client>(
    label: 'Cidade',
    cellBuilder: (_, client) => Text(client.city),
  ),
];

/// Golden coverage for [AppDataTable] (table and card layout) and
/// [AppKpiCard] in both light and dark theme, per TASK-023's acceptance
/// criteria. Run `flutter test --update-goldens` after an intentional
/// visual change to this set of components.
void main() {
  Future<void> expectGolden(
    WidgetTester tester,
    Widget child,
    String name, {
    Brightness brightness = Brightness.light,
    required double width,
  }) async {
    await pumpApp(
      tester,
      RepaintBoundary(
        key: Key(name),
        child: SizedBox(width: width, child: child),
      ),
      brightness: brightness,
    );
    await tester.pump();
    await expectLater(find.byKey(Key(name)), matchesGoldenFile('$name.png'));
  }

  group('AppDataTable goldens — table mode', () {
    testWidgets('light', (tester) async {
      await expectGolden(
        tester,
        AppDataTable<_Client>(
          columns: _columns(),
          rows: _clients,
          rowIdBuilder: (client) => client.id,
        ),
        'app_data_table_mode_light',
        width: 640,
      );
    });

    testWidgets('dark', (tester) async {
      await expectGolden(
        tester,
        AppDataTable<_Client>(
          columns: _columns(),
          rows: _clients,
          rowIdBuilder: (client) => client.id,
        ),
        'app_data_table_mode_dark',
        brightness: Brightness.dark,
        width: 640,
      );
    });
  });

  group('AppDataTable goldens — card mode', () {
    testWidgets('light', (tester) async {
      await expectGolden(
        tester,
        AppDataTable<_Client>(
          columns: _columns(),
          rows: _clients,
          rowIdBuilder: (client) => client.id,
        ),
        'app_data_table_card_light',
        width: 320,
      );
    });

    testWidgets('dark', (tester) async {
      await expectGolden(
        tester,
        AppDataTable<_Client>(
          columns: _columns(),
          rows: _clients,
          rowIdBuilder: (client) => client.id,
        ),
        'app_data_table_card_dark',
        brightness: Brightness.dark,
        width: 320,
      );
    });
  });

  group('AppKpiCard goldens', () {
    testWidgets('light', (tester) async {
      await expectGolden(
        tester,
        const AppKpiCard(
          label: 'Faturamento (mês)',
          value: 'R\$ 128.400',
          trend: AppKpiTrend.up,
          trendPercentage: 12.5,
          trendLabel: 'vs. mês anterior',
        ),
        'app_kpi_card_light',
        width: 260,
      );
    });

    testWidgets('dark', (tester) async {
      await expectGolden(
        tester,
        const AppKpiCard(
          label: 'Faturamento (mês)',
          value: 'R\$ 128.400',
          trend: AppKpiTrend.up,
          trendPercentage: 12.5,
          trendLabel: 'vs. mês anterior',
        ),
        'app_kpi_card_dark',
        brightness: Brightness.dark,
        width: 260,
      );
    });
  });
}
