import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

/// Golden coverage for [AppModal], [AppBottomSheet] and
/// [AppConfirmationDialog] in both light and dark theme, per TASK-022's
/// acceptance criteria. Run `flutter test --update-goldens` after an
/// intentional visual change to this set of components.
void main() {
  Future<void> openAndExpectGolden(
    WidgetTester tester, {
    required void Function(BuildContext context) open,
    required Finder finder,
    required String name,
    Brightness brightness = Brightness.light,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) =>
            AppButton(label: 'Abrir', onPressed: () => open(context)),
      ),
      brightness: brightness,
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await expectLater(finder, matchesGoldenFile('$name.png'));
  }

  group('AppModal goldens', () {
    testWidgets('with actions, light', (tester) async {
      await openAndExpectGolden(
        tester,
        open: (context) => AppModal.show<void>(
          context: context,
          title: 'Detalhes do pedido',
          body: const Text('Cliente: Boutique Malwee Centro'),
          primaryAction: AppModalAction(label: 'Confirmar', onPressed: () {}),
          secondaryAction: AppModalAction(
            label: 'Cancelar',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        finder: find.byType(Dialog),
        name: 'app_modal_light',
      );
    });

    testWidgets('with actions, dark', (tester) async {
      await openAndExpectGolden(
        tester,
        open: (context) => AppModal.show<void>(
          context: context,
          title: 'Detalhes do pedido',
          body: const Text('Cliente: Boutique Malwee Centro'),
          primaryAction: AppModalAction(label: 'Confirmar', onPressed: () {}),
          secondaryAction: AppModalAction(
            label: 'Cancelar',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        finder: find.byType(Dialog),
        name: 'app_modal_dark',
        brightness: Brightness.dark,
      );
    });
  });

  group('AppBottomSheet goldens', () {
    const contentKey = Key('golden-bottom-sheet-content');

    testWidgets('with title and content, light', (tester) async {
      await openAndExpectGolden(
        tester,
        open: (context) => AppBottomSheet.show<void>(
          context: context,
          title: 'Filtrar clientes',
          contentKey: contentKey,
          builder: (context) => const Text('Status, região e carteira'),
        ),
        finder: find.byKey(contentKey),
        name: 'app_bottom_sheet_light',
      );
    });

    testWidgets('with title and content, dark', (tester) async {
      await openAndExpectGolden(
        tester,
        open: (context) => AppBottomSheet.show<void>(
          context: context,
          title: 'Filtrar clientes',
          contentKey: contentKey,
          builder: (context) => const Text('Status, região e carteira'),
        ),
        finder: find.byKey(contentKey),
        name: 'app_bottom_sheet_dark',
        brightness: Brightness.dark,
      );
    });
  });

  group('AppConfirmationDialog goldens', () {
    testWidgets('destructive, light', (tester) async {
      await openAndExpectGolden(
        tester,
        open: (context) => AppConfirmationDialog.show(
          context: context,
          title: 'Excluir cliente?',
          message:
              'Esta ação remove o cliente e seu histórico de pedidos. '
              'Não é possível desfazer.',
          confirmLabel: 'Excluir',
        ),
        finder: find.byType(Dialog),
        name: 'app_confirmation_dialog_light',
      );
    });

    testWidgets('destructive, dark', (tester) async {
      await openAndExpectGolden(
        tester,
        open: (context) => AppConfirmationDialog.show(
          context: context,
          title: 'Excluir cliente?',
          message:
              'Esta ação remove o cliente e seu histórico de pedidos. '
              'Não é possível desfazer.',
          confirmLabel: 'Excluir',
        ),
        finder: find.byType(Dialog),
        name: 'app_confirmation_dialog_dark',
        brightness: Brightness.dark,
      );
    });
  });
}
