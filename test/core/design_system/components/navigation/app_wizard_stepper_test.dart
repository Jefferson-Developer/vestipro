import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppWizardStepper', () {
    testWidgets('shows the progress caption and the current step title', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppWizardStepper(
          currentStep: 2,
          stepLabels: const <String>['Um', 'Dois', 'Três'],
        ),
      );

      expect(find.text('Passo 2 de 3'), findsOneWidget);
      expect(find.text('Dois'), findsOneWidget);
      expect(find.text('Um'), findsNothing);
      expect(find.text('Três'), findsNothing);
    });

    testWidgets('exposes the progress as a single semantics label', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppWizardStepper(
          currentStep: 1,
          stepLabels: const <String>['Primeiro', 'Segundo'],
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppWizardStepper));
      expect(semantics.label, contains('Passo 1 de 2: Primeiro'));
    });
  });
}
