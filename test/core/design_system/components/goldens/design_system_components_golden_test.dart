import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

/// Golden coverage for [AppButton], [AppTextField], [AppStatusBadge] and
/// [AppSkeleton] in both light and dark theme, per TASK-021's acceptance
/// criteria. Run `flutter test --update-goldens` after an intentional
/// visual change to this set of components.
void main() {
  Future<void> expectGolden(
    WidgetTester tester,
    Widget child,
    String name, {
    Brightness brightness = Brightness.light,
    double? width = 260,
  }) async {
    await pumpApp(
      tester,
      RepaintBoundary(
        key: Key(name),
        child: width == null ? child : SizedBox(width: width, child: child),
      ),
      brightness: brightness,
    );
    await tester.pump();
    await expectLater(find.byKey(Key(name)), matchesGoldenFile('$name.png'));
  }

  group('AppButton goldens', () {
    testWidgets('primary, light', (tester) async {
      await expectGolden(
        tester,
        AppButton(label: 'Enviar pedido', onPressed: () {}),
        'app_button_primary_light',
      );
    });

    testWidgets('primary, dark', (tester) async {
      await expectGolden(
        tester,
        AppButton(label: 'Enviar pedido', onPressed: () {}),
        'app_button_primary_dark',
        brightness: Brightness.dark,
      );
    });
  });

  group('AppTextField goldens', () {
    testWidgets('with label and helper text, light', (tester) async {
      await expectGolden(
        tester,
        const AppTextField(
          label: 'Nome do cliente',
          helperText: 'Como aparece na nota fiscal',
          isRequired: true,
        ),
        'app_text_field_light',
      );
    });

    testWidgets('with label and helper text, dark', (tester) async {
      await expectGolden(
        tester,
        const AppTextField(
          label: 'Nome do cliente',
          helperText: 'Como aparece na nota fiscal',
          isRequired: true,
        ),
        'app_text_field_dark',
        brightness: Brightness.dark,
      );
    });
  });

  group('AppStatusBadge goldens', () {
    testWidgets('success, light', (tester) async {
      await expectGolden(
        tester,
        const AppStatusBadge(
          label: 'Pedido confirmado',
          variant: AppStatusBadgeVariant.success,
        ),
        'app_status_badge_light',
        width: null,
      );
    });

    testWidgets('success, dark', (tester) async {
      await expectGolden(
        tester,
        const AppStatusBadge(
          label: 'Pedido confirmado',
          variant: AppStatusBadgeVariant.success,
        ),
        'app_status_badge_dark',
        brightness: Brightness.dark,
        width: null,
      );
    });
  });

  group('AppSkeleton goldens', () {
    testWidgets('card, light', (tester) async {
      await expectGolden(
        tester,
        const AppSkeleton.card(width: 220, height: 120),
        'app_skeleton_light',
        width: null,
      );
    });

    testWidgets('card, dark', (tester) async {
      await expectGolden(
        tester,
        const AppSkeleton.card(width: 220, height: 120),
        'app_skeleton_dark',
        brightness: Brightness.dark,
        width: null,
      );
    });
  });
}
