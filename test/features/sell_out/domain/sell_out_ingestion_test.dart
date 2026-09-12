import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/sell_out/sell_out.dart';

void main() {
  final soldAt = DateTime(2026, 9, 10);
  final receivedAt = DateTime(2026, 9, 12);

  const candidate = ProductMatchCandidate(
    productId: 'product-1',
    variantId: 'variant-1',
    ean: '7891234567895',
    sku: 'SKU-1',
    customerEquivalentCode: 'CUST-1',
    reference: 'REF-1',
    color: 'Preto',
    size: 'M',
  );

  SellOutRawRow row({
    String externalEventId = 'event-1',
    String organizationId = 'org-1',
    String customerId = 'customer-1',
    String? ean = '7891234567895',
    String? sku,
    String? reference,
    String? color,
    String? size,
    String? consumerEmail,
  }) {
    return SellOutRawRow(
      externalEventId: externalEventId,
      organizationId: organizationId,
      customerId: customerId,
      storeId: 'store-1',
      soldAt: soldAt,
      quantity: 2,
      grossAmountCents: 15000,
      channel: SellOutChannel.physicalStore,
      sourceType: SellOutSourceType.pos,
      sourceName: 'Retail POS',
      ean: ean,
      sku: sku,
      reference: reference,
      color: color,
      size: size,
      consumerEmail: consumerEmail,
    );
  }

  test('ingests batch idempotently by tenant customer and external event', () {
    const service = SellOutIngestionService();
    final result = service.ingest(
      batchId: 'batch-1',
      receivedAt: receivedAt,
      rows: [
        row(),
        row(),
        row(externalEventId: 'event-2'),
      ],
      candidates: const [candidate],
      alreadyProcessedEventIds: const {},
    );

    expect(result.acceptedEvents, hasLength(2));
    expect(result.duplicateExternalEventIds, contains('event-1'));
  });

  test('matches product by EAN SKU and customer equivalence', () {
    const matcher = SellOutProductMatcher();

    expect(
      matcher
          .match(
            row: row(ean: '7891234567895'),
            candidates: const [candidate],
            customerEquivalence: const {},
          )!
          .strategy,
      ProductMatchStrategy.ean,
    );
    expect(
      matcher
          .match(
            row: row(ean: null, sku: 'sku-1'),
            candidates: const [candidate],
            customerEquivalence: const {},
          )!
          .strategy,
      ProductMatchStrategy.sku,
    );
    expect(
      matcher
          .match(
            row: row(ean: null, reference: 'store-code'),
            candidates: const [candidate],
            customerEquivalence: const {'store-code': 'variant-1'},
          )!
          .strategy,
      ProductMatchStrategy.customerEquivalence,
    );
  });

  test('isolates idempotency by organization and customer', () {
    const service = SellOutIngestionService();
    final result = service.ingest(
      batchId: 'batch-1',
      receivedAt: receivedAt,
      rows: [
        row(organizationId: 'org-1', customerId: 'customer-1'),
        row(organizationId: 'org-2', customerId: 'customer-1'),
        row(organizationId: 'org-1', customerId: 'customer-2'),
      ],
      candidates: const [candidate],
      alreadyProcessedEventIds: const {},
    );

    expect(result.acceptedEvents, hasLength(3));
    expect(
      result.acceptedEvents.map((event) => event.id).toSet(),
      hasLength(3),
    );
  });

  test('keeps sell-in and sell-out as separate metrics', () {
    const metric = SellInSellOutMetric(
      productId: 'product-1',
      sellInQuantity: 10,
      sellOutQuantity: 4,
    );

    expect(metric.sellInQuantity, 10);
    expect(metric.sellOutQuantity, 4);
    expect(metric.sellThroughRate, 0.4);
  });

  test('rejects consumer personal data in POS payload', () {
    const service = SellOutIngestionService();
    final result = service.ingest(
      batchId: 'batch-1',
      receivedAt: receivedAt,
      rows: [row(consumerEmail: 'cliente@example.com')],
      candidates: const [candidate],
      alreadyProcessedEventIds: const {},
    );

    expect(result.acceptedEvents, isEmpty);
    expect(result.rejectedRows.single.message, contains('dado pessoal'));
  });

  test('aggregates retail sales facts by month without touching orders', () {
    const service = SellOutIngestionService();
    const aggregator = SellOutFactAggregator();
    final result = service.ingest(
      batchId: 'batch-1',
      receivedAt: receivedAt,
      rows: [
        row(),
        row(externalEventId: 'event-2'),
      ],
      candidates: const [candidate],
      alreadyProcessedEventIds: const {},
    );

    final facts = aggregator.aggregateMonthly(result.acceptedEvents);

    expect(facts.single.periodKey, '2026-09');
    expect(facts.single.sellOutQuantity, 4);
    expect(facts.single.sellOutAmountCents, 30000);
    expect(facts.single.averageConfidence, 1);
  });
}
