import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppPagination — numeric mode', () {
    testWidgets('advances to the next page', (tester) async {
      int? requestedPage;

      await pumpApp(
        tester,
        AppPagination(
          mode: AppPaginationMode.numeric,
          currentPage: 2,
          totalPages: 5,
          onPageChanged: (page) => requestedPage = page,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Próxima página'));
      await tester.pump();

      expect(requestedPage, 3);
    });

    testWidgets('goes back to the previous page', (tester) async {
      int? requestedPage;

      await pumpApp(
        tester,
        AppPagination(
          mode: AppPaginationMode.numeric,
          currentPage: 2,
          totalPages: 5,
          onPageChanged: (page) => requestedPage = page,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Página anterior'));
      await tester.pump();

      expect(requestedPage, 1);
    });

    testWidgets('disables the previous control on the first page', (
      tester,
    ) async {
      var called = false;

      await pumpApp(
        tester,
        AppPagination(
          mode: AppPaginationMode.numeric,
          currentPage: 1,
          totalPages: 5,
          onPageChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Página anterior'));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('disables the next control on the last page', (tester) async {
      var called = false;

      await pumpApp(
        tester,
        AppPagination(
          mode: AppPaginationMode.numeric,
          currentPage: 5,
          totalPages: 5,
          onPageChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Próxima página'));
      await tester.pump();

      expect(called, isFalse);
    });
  });

  group('AppPagination — load more mode', () {
    testWidgets(
      'appends the next page while preserving every item already loaded',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: _LoadMoreHarness(initialItems: ['Cliente 1', 'Cliente 2']),
            ),
          ),
        );

        expect(find.text('Cliente 1'), findsOneWidget);
        expect(find.text('Cliente 2'), findsOneWidget);
        expect(find.text('Cliente 3'), findsNothing);

        await tester.tap(find.text('Carregar mais'));
        await tester.pump();

        // The two items already loaded remain — the component never clears
        // and reloads from zero, it only appends.
        expect(find.text('Cliente 1'), findsOneWidget);
        expect(find.text('Cliente 2'), findsOneWidget);
        expect(find.text('Cliente 3'), findsOneWidget);
      },
    );

    testWidgets('shows the end-of-list label once hasMore is false', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppPagination(mode: AppPaginationMode.loadMore, hasMore: false),
      );

      expect(find.text('Não há mais itens'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
    });

    testWidgets('disables the load-more button while isLoadingMore is true', (
      tester,
    ) async {
      var called = false;

      await pumpApp(
        tester,
        AppPagination(
          mode: AppPaginationMode.loadMore,
          isLoadingMore: true,
          onLoadMore: () => called = true,
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(called, isFalse);
    });
  });
}

/// Reproduces the real usage pattern: the *caller* owns the growing list of
/// items, [AppPagination] only reports "load more" intent.
class _LoadMoreHarness extends StatefulWidget {
  const _LoadMoreHarness({required this.initialItems});

  final List<String> initialItems;

  @override
  State<_LoadMoreHarness> createState() => _LoadMoreHarnessState();
}

class _LoadMoreHarnessState extends State<_LoadMoreHarness> {
  late List<String> _items = widget.initialItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final item in _items) Text(item),
        AppPagination(
          mode: AppPaginationMode.loadMore,
          onLoadMore: () => setState(
            () => _items = [..._items, 'Cliente ${_items.length + 1}'],
          ),
        ),
      ],
    );
  }
}
