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
    sortable: true,
    cellBuilder: (_, client) => Text(client.name),
  ),
  AppDataColumn<_Client>(
    label: 'Cidade',
    cellBuilder: (_, client) => Text(client.city),
  ),
];

Widget _wrap(Widget child, {double width = 800}) {
  return SizedBox(width: width, child: child);
}

void main() {
  group('AppDataTable — table mode', () {
    testWidgets('sorting a sortable column reports index and ascending state', (
      tester,
    ) async {
      int? sortedIndex;
      bool? ascending;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            onSort: (index, isAscending) {
              sortedIndex = index;
              ascending = isAscending;
            },
          ),
        ),
      );

      await tester.tap(find.text('Cliente'));
      await tester.pump();

      expect(sortedIndex, 0);
      expect(ascending, isTrue);
    });

    testWidgets('toggles to descending on a second tap of the sorted column', (
      tester,
    ) async {
      int? sortedIndex;
      bool? ascending;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            sortColumnIndex: 0,
            sortAscending: true,
            onSort: (index, isAscending) {
              sortedIndex = index;
              ascending = isAscending;
            },
          ),
        ),
      );

      await tester.tap(find.text('Cliente'));
      await tester.pump();

      expect(sortedIndex, 0);
      expect(ascending, isFalse);
    });

    testWidgets('selecting a row reports its id via onSelectionChanged', (
      tester,
    ) async {
      Set<Object>? selected;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            selectable: true,
            onSelectionChanged: (ids) => selected = ids,
          ),
        ),
      );

      // Index 0 is the "select all" header checkbox; index 1 is the first
      // row's checkbox.
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(selected, <Object>{1});
    });

    testWidgets('the "select all" checkbox selects every row id', (
      tester,
    ) async {
      Set<Object>? selected;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            selectable: true,
            onSelectionChanged: (ids) => selected = ids,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(selected, <Object>{1, 2});
    });

    testWidgets(
      'a destructive batch action only runs after AppConfirmationDialog confirms',
      (tester) async {
        Set<Object>? confirmedIds;

        await pumpApp(
          tester,
          _wrap(
            AppDataTable<_Client>(
              columns: _columns(),
              rows: _clients,
              rowIdBuilder: (client) => client.id,
              selectable: true,
              selectedIds: const {1},
              onSelectionChanged: (_) {},
              batchActions: [
                AppDataTableBatchAction(
                  label: 'Excluir selecionados',
                  isDestructive: true,
                  confirmationTitle: 'Excluir clientes?',
                  confirmationMessage: 'Esta ação não pode ser desfeita.',
                  confirmLabel: 'Excluir',
                  onConfirmed: (ids) => confirmedIds = ids,
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text('Excluir selecionados'));
        await tester.pumpAndSettle();

        // The dialog is shown; nothing has run yet.
        expect(find.text('Excluir clientes?'), findsOneWidget);
        expect(confirmedIds, isNull);

        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();

        expect(confirmedIds, <Object>{1});
      },
    );

    testWidgets('a non-destructive batch action runs immediately', (
      tester,
    ) async {
      Set<Object>? confirmedIds;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            selectable: true,
            selectedIds: const {1, 2},
            onSelectionChanged: (_) {},
            batchActions: [
              AppDataTableBatchAction(
                label: 'Exportar selecionados',
                onConfirmed: (ids) => confirmedIds = ids,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Exportar selecionados'));
      await tester.pump();

      expect(confirmedIds, <Object>{1, 2});
    });

    testWidgets('a row action calls back with the tapped row item', (
      tester,
    ) async {
      _Client? tapped;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            rowActions: [
              AppDataTableAction<_Client>(
                icon: Icons.visibility_outlined,
                semanticLabel: 'Ver detalhes',
                onPressed: (client) => tapped = client,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Ver detalhes').first);
      await tester.pump();

      expect(tapped?.id, 1);
    });

    testWidgets('renders the empty state when status is empty', (tester) async {
      await pumpApp(
        tester,
        _wrap(
          const AppDataTable<_Client>(
            columns: [],
            rows: [],
            rowIdBuilder: _idOf,
            status: AppDataTableStatus.empty,
            emptyTitle: 'Nenhum cliente encontrado',
          ),
        ),
      );

      expect(find.text('Nenhum cliente encontrado'), findsOneWidget);
    });

    testWidgets('renders the error state and retries when status is error', (
      tester,
    ) async {
      var retried = false;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: const [],
            rows: const [],
            rowIdBuilder: _idOf,
            status: AppDataTableStatus.error,
            errorTitle: 'Falha ao carregar clientes',
            errorMessage: 'Verifique sua conexão e tente novamente.',
            retryLabel: 'Tentar novamente',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Falha ao carregar clientes'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('AppDataTable — mobile card conversion', () {
    testWidgets(
      'converts every row to a card below the mobile breakpoint, reusing the '
      'same column cell builders',
      (tester) async {
        await pumpApp(
          tester,
          _wrap(
            AppDataTable<_Client>(
              columns: _columns(),
              rows: _clients,
              rowIdBuilder: (client) => client.id,
            ),
            width: 360,
          ),
        );

        // The card layout renders remaining columns as "Label: value" text —
        // the table layout never renders that colon-prefixed shape.
        expect(find.textContaining('Cidade: '), findsNWidgets(2));
        expect(find.text('Ana Souza'), findsOneWidget);
        expect(find.text('Bruno Lima'), findsOneWidget);
      },
    );

    testWidgets('still exposes row actions and selection on cards', (
      tester,
    ) async {
      _Client? tapped;
      Set<Object>? selected;

      await pumpApp(
        tester,
        _wrap(
          AppDataTable<_Client>(
            columns: _columns(),
            rows: _clients,
            rowIdBuilder: (client) => client.id,
            selectable: true,
            onSelectionChanged: (ids) => selected = ids,
            rowActions: [
              AppDataTableAction<_Client>(
                icon: Icons.visibility_outlined,
                semanticLabel: 'Ver detalhes',
                onPressed: (client) => tapped = client,
              ),
            ],
          ),
          width: 360,
        ),
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(selected, <Object>{1});

      await tester.tap(find.bySemanticsLabel('Ver detalhes').first);
      await tester.pump();
      expect(tapped?.id, 1);
    });
  });
}

Object _idOf(_Client client) => client.id;
