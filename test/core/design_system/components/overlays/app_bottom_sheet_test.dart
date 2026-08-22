import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppBottomSheet', () {
    testWidgets('show renders the title and dynamic content', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir filtros',
            onPressed: () => AppBottomSheet.show<void>(
              context: context,
              title: 'Filtrar clientes',
              builder: (context) => const Text('Conteúdo dinâmico'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar clientes'), findsOneWidget);
      expect(find.text('Conteúdo dinâmico'), findsOneWidget);
    });

    testWidgets('closes when the close button is tapped', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir filtros',
            onPressed: () => AppBottomSheet.show<void>(
              context: context,
              title: 'Filtrar clientes',
              builder: (context) => const Text('Conteúdo dinâmico'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir filtros'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar clientes'), findsNothing);
    });

    testWidgets('closes with a downward drag gesture', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir filtros',
            onPressed: () => AppBottomSheet.show<void>(
              context: context,
              title: 'Filtrar clientes',
              builder: (context) =>
                  const SizedBox(height: 120, child: Text('Conteúdo dinâmico')),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Filtrar clientes'), findsOneWidget);

      await tester.drag(find.text('Filtrar clientes'), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar clientes'), findsNothing);
    });

    testWidgets('resolves the value the content pops with', (tester) async {
      String? result;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir filtros',
            onPressed: () async {
              result = await AppBottomSheet.show<String>(
                context: context,
                builder: (sheetContext) => AppButton(
                  label: 'Selecionar',
                  onPressed: () =>
                      Navigator.of(sheetContext).pop('selecionado'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir filtros'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();

      expect(result, 'selecionado');
    });
  });
}
