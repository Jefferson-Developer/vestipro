import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

const _navy = AppColorSwatchOption(
  id: 'navy',
  label: 'Azul marinho',
  color: Color(0xFF102A43),
  previewImageUrl: 'https://cdn.vestipro.test/navy.jpg',
);

const _white = AppColorSwatchOption(
  id: 'white',
  label: 'Branco',
  color: Color(0xFFFFFFFF),
  previewImageUrl: 'https://cdn.vestipro.test/white.jpg',
);

const _red = AppColorSwatchOption(
  id: 'red',
  label: 'Vermelho',
  color: Color(0xFFB3261E),
  availability: AppColorAvailability.unavailable,
);

const _yellow = AppColorSwatchOption(
  id: 'yellow',
  label: 'Amarelo',
  color: Color(0xFFF2C400),
  availability: AppColorAvailability.futureStock,
);

void main() {
  group('AppColorSwatchSelector', () {
    testWidgets('reports the full selected option — not just its id', (
      tester,
    ) async {
      AppColorSwatchOption? selected;

      await pumpApp(
        tester,
        AppColorSwatchSelector(
          options: const [_navy, _white],
          selectedId: _navy.id,
          onSelected: (option) => selected = option,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Branco'));
      await tester.pump();

      expect(selected?.id, _white.id);
      expect(selected?.previewImageUrl, _white.previewImageUrl);
    });

    testWidgets(
      'a caller updates its own gallery/availability copy in reaction to onSelected',
      (tester) async {
        await pumpApp(tester, const _GallerySelectionHarness());

        expect(find.text('Foto: ${_navy.previewImageUrl}'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Branco'));
        await tester.pump();

        expect(find.text('Foto: ${_white.previewImageUrl}'), findsOneWidget);
      },
    );

    testWidgets('marks the selected swatch via Semantics', (tester) async {
      await pumpApp(
        tester,
        AppColorSwatchSelector(
          options: const [_navy, _white],
          selectedId: _navy.id,
          onSelected: (_) {},
        ),
      );

      final navySemantics = tester.getSemantics(
        find.bySemanticsLabel('Azul marinho, selecionado'),
      );
      expect(navySemantics.label, contains('selecionado'));
    });

    testWidgets(
      'communicates "indisponível" with text/icon, never color alone, and blocks selection',
      (tester) async {
        var called = false;

        await pumpApp(
          tester,
          AppColorSwatchSelector(
            options: const [_navy, _red],
            selectedId: _navy.id,
            onSelected: (_) => called = true,
          ),
        );

        expect(find.byIcon(Icons.block), findsOneWidget);
        expect(find.bySemanticsLabel('Vermelho, Indisponível'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Vermelho, Indisponível'));
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets('shows a future-stock indicator without blocking selection', (
      tester,
    ) async {
      AppColorSwatchOption? selected;

      await pumpApp(
        tester,
        AppColorSwatchSelector(
          options: const [_navy, _yellow],
          selectedId: _navy.id,
          onSelected: (option) => selected = option,
        ),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Amarelo, Estoque futuro'));
      await tester.pump();

      expect(selected?.id, _yellow.id);
    });
  });
}

/// Reproduces the real usage pattern: [AppColorSwatchSelector] only reports
/// the picked option; the *caller* is the one reacting by swapping its own
/// gallery/preview copy.
class _GallerySelectionHarness extends StatefulWidget {
  const _GallerySelectionHarness();

  @override
  State<_GallerySelectionHarness> createState() =>
      _GallerySelectionHarnessState();
}

class _GallerySelectionHarnessState extends State<_GallerySelectionHarness> {
  AppColorSwatchOption _selected = _navy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Foto: ${_selected.previewImageUrl}'),
        AppColorSwatchSelector(
          options: const [_navy, _white],
          selectedId: _selected.id,
          onSelected: (option) => setState(() => _selected = option),
        ),
      ],
    );
  }
}
