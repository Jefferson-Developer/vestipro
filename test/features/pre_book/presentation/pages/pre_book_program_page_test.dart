import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/pre_book/pre_book.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

void main() {
  group('PreBookProgramPage', () {
    testWidgets('shows future dates, window state and unavailable stock', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 390,
          height: 720,
          child: PreBookProgramPage(
            program: _program(status: PreBookProgramStatus.open),
            metrics: PreBookCaptureMetrics(
              program: _program(status: PreBookProgramStatus.open),
              reservedPieces: 20,
              soldPieces: 30,
              cancelledPieces: 5,
              deliveryRisk: PreBookProductionRisk.attention,
            ),
            availability: const <PreBookVariantAvailability>[
              PreBookVariantAvailability(
                variantId: 'variant-1',
                productId: 'product-1',
                deliveryWindowId: 'jan',
                status: PreBookAvailabilityStatus.unavailable,
                futureQuantity: 0,
              ),
            ],
            now: DateTime.utc(2026, 9, 15),
          ),
        ),
      );

      expect(find.text('Janela aberta'), findsOneWidget);
      expect(find.text('Janeiro'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();

      expect(find.textContaining('indisponivel'), findsOneWidget);
      expect(find.text('Risco de entrega'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disables creation after the sales window closes', (
      tester,
    ) async {
      var tapped = false;
      await pumpApp(
        tester,
        PreBookProgramPage(
          program: _program(status: PreBookProgramStatus.open),
          metrics: PreBookCaptureMetrics(
            program: _program(status: PreBookProgramStatus.open),
            reservedPieces: 0,
            soldPieces: 0,
            cancelledPieces: 0,
            deliveryRisk: PreBookProductionRisk.low,
          ),
          availability: const <PreBookVariantAvailability>[],
          now: DateTime.utc(2026, 12, 1),
          onCreatePreBookOrder: () => tapped = true,
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar pedido pre-book'));
      await tester.pumpAndSettle();

      expect(find.text('Fora da janela'), findsOneWidget);
      expect(tapped, isFalse);
    });
  });
}

PreBookProgram _program({required PreBookProgramStatus status}) {
  return PreBookProgram(
    id: 'program-1',
    organizationId: 'org-1',
    collectionId: 'col-1',
    name: 'Pre-book Verao 2027',
    salesWindowStart: DateTime.utc(2026, 9, 1),
    salesWindowEnd: DateTime.utc(2026, 10, 31),
    deliveryWindows: <PreBookDeliveryWindow>[
      PreBookDeliveryWindow(
        id: 'jan',
        label: 'Janeiro',
        startsAt: DateTime.utc(2027, 1, 1),
        endsAt: DateTime.utc(2027, 1, 31),
      ),
    ],
    status: status,
    audiencePolicy: const PreBookAudiencePolicy(
      profiles: <PreBookAudienceProfile>{PreBookAudienceProfile.seller},
    ),
    targetPieces: 100,
    cancellationRules: 'Sem cancelamento apos aprovacao.',
    pricingPolicy: const PreBookPricingPolicy(
      type: PreBookPricingPolicyType.launchPrice,
    ),
    commitmentRules: const PreBookCommitmentRules(),
    updatedAt: DateTime.utc(2026, 9, 1),
  );
}
