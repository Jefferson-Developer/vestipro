import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

const _columns = [
  AppSizeGridColumn(id: 'p', label: 'P'),
  AppSizeGridColumn(id: 'm', label: 'M'),
];

List<AppSizeGridRow> _rows() => [
  const AppSizeGridRow(
    id: 'navy',
    label: 'Azul marinho',
    colorSwatch: Color(0xFF102A43),
    cells: {
      'p': AppSizeGridCell(quantity: 2),
      'm': AppSizeGridCell(quantity: 3),
    },
  ),
  const AppSizeGridRow(
    id: 'white',
    label: 'Branco',
    colorSwatch: Colors.white,
    cells: {
      'p': AppSizeGridCell(quantity: 1),
      'm': AppSizeGridCell(quantity: 0),
    },
  ),
];

void main() {
  group('AppSizeGrid', () {
    testWidgets('renders every already-filled cell and its totals', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppSizeGrid(
          columns: _columns,
          rows: _rows(),
          onQuantityChanged: (_, _, _) {},
        ),
      );

      expect(find.text('Azul marinho'), findsOneWidget);
      expect(find.text('Branco'), findsOneWidget);

      // Row totals: navy = 2 + 3 = 5, white = 1 + 0 = 1. Looked up by key
      // (not by text) since a total can coincidentally equal a raw cell
      // quantity also rendered inside a TextField on screen.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app_size_grid_row_total_navy')))
            .data,
        '5',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('app_size_grid_row_total_white')),
            )
            .data,
        '1',
      );
      // Column totals: P = 2 + 1 = 3, M = 3 + 0 = 3.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app_size_grid_column_total_p')))
            .data,
        '3',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app_size_grid_column_total_m')))
            .data,
        '3',
      );
      // Grand total: 6.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app_size_grid_grand_total')))
            .data,
        '6',
      );
    });

    testWidgets('reports the exact quantity typed by the user', (tester) async {
      Object? changedRowId;
      Object? changedColumnId;
      int? changedQuantity;

      await pumpApp(
        tester,
        AppSizeGrid(
          columns: _columns,
          rows: _rows(),
          onQuantityChanged: (rowId, columnId, quantity) {
            changedRowId = rowId;
            changedColumnId = columnId;
            changedQuantity = quantity;
          },
        ),
      );

      await tester.enterText(find.byType(TextField).first, '7');
      await tester.pump();

      expect(changedRowId, 'navy');
      expect(changedColumnId, 'p');
      expect(changedQuantity, 7);
    });

    testWidgets('advances focus to the next cell on the submit action', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppSizeGrid(
          columns: _columns,
          rows: _rows(),
          onQuantityChanged: (_, _, _) {},
        ),
      );

      final fields = find.byType(TextField);
      await tester.tap(fields.first);
      await tester.pump();
      await tester.enterText(fields.first, '4');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final secondField = tester.widget<TextField>(fields.at(1));
      expect(secondField.focusNode!.hasFocus, isTrue);
    });

    testWidgets(
      'preserves a typed value even if the widget rebuilds with stale data '
      '(e.g. a connectivity/sync banner elsewhere on the screen)',
      (tester) async {
        var reconnected = false;

        await pumpApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppSizeGrid(
                    columns: _columns,
                    rows: _rows(),
                    onQuantityChanged: (_, _, _) {},
                  ),
                  Text(reconnected ? 'Online' : 'Offline'),
                  AppButton(
                    label: 'Simular reconexão',
                    onPressed: () => setState(() => reconnected = true),
                  ),
                ],
              );
            },
          ),
        );

        final field = find.byType(TextField).first;
        await tester.tap(field);
        await tester.pump();
        await tester.enterText(field, '9');
        await tester.pump();

        expect(find.text('9'), findsOneWidget);

        await tester.tap(find.text('Simular reconexão'));
        await tester.pump();

        expect(find.text('Online'), findsOneWidget);
        expect(find.text('9'), findsOneWidget);
      },
    );

    testWidgets(
      'communicates an unavailable cell with text/icon, never color alone, and blocks input',
      (tester) async {
        final rows = [
          const AppSizeGridRow(
            id: 'navy',
            label: 'Azul marinho',
            cells: {
              'p': AppSizeGridCell(
                availability: AppSizeGridCellAvailability.unavailable,
              ),
              'm': AppSizeGridCell(),
            },
          ),
        ];

        await pumpApp(
          tester,
          AppSizeGrid(
            columns: _columns,
            rows: rows,
            onQuantityChanged: (_, _, _) {},
          ),
        );

        expect(find.byIcon(Icons.block), findsOneWidget);
        expect(
          find.bySemanticsLabel('Azul marinho P: Indisponível'),
          findsOneWidget,
        );
        // Only the "M" cell remains editable.
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets('shows a future-stock indicator without blocking input', (
      tester,
    ) async {
      final rows = [
        const AppSizeGridRow(
          id: 'navy',
          label: 'Azul marinho',
          cells: {
            'p': AppSizeGridCell(
              availability: AppSizeGridCellAvailability.futureStock,
            ),
            'm': AppSizeGridCell(),
          },
        ),
      ];

      int? changedQuantity;

      await pumpApp(
        tester,
        AppSizeGrid(
          columns: _columns,
          rows: rows,
          onQuantityChanged: (_, _, quantity) => changedQuantity = quantity,
        ),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '5');
      await tester.pump();

      expect(changedQuantity, 5);
    });
  });
}
