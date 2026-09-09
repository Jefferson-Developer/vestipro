import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  testWidgets('edits frequency, pauses, cancels and shows executions', (
    tester,
  ) async {
    var savedInterval = 0;
    var paused = false;
    var canceled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RecurringOrderPlanPage(
          plan: _plan(),
          onSave: (frequency, nextExecutionAt, items) async {
            savedInterval = frequency.interval;
          },
          onPause: () async => paused = true,
          onCancel: () async => canceled = true,
        ),
      ),
    );

    expect(find.text('Pedido recorrente'), findsOneWidget);
    expect(find.text('000123'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('recurring-interval-field')),
      '14',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(savedInterval, 14);

    await tester.tap(find.text('Pausar'));
    await tester.pump();
    expect(paused, isTrue);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(canceled, isTrue);
  });
}

RecurringOrderPlan _plan() {
  final now = DateTime.utc(2026, 9, 9);
  return RecurringOrderPlan(
    id: 'plan-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    sourceOrderId: 'order-1',
    frequency: const RecurringOrderFrequency(
      interval: 7,
      unit: RecurringOrderFrequencyUnit.days,
    ),
    nextExecutionAt: DateTime.utc(2026, 9, 16),
    status: RecurringOrderPlanStatus.active,
    items: const <OrderItem>[
      OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 100,
        subtotal: 200,
      ),
    ],
    executions: <RecurringOrderExecution>[
      RecurringOrderExecution(
        id: 'execution-1',
        scheduledFor: now,
        processedAt: now,
        status: 'generated',
        orderId: 'order-generated-1',
        orderNumber: '000123',
      ),
    ],
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
  );
}
