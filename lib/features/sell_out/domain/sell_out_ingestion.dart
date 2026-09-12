enum SellOutChannel { physicalStore, ecommerce, marketplace, unknown }

enum SellOutSourceType { api, csv, xlsx, erp, pos }

enum ProductMatchStrategy {
  ean,
  sku,
  customerEquivalence,
  colorSize,
  unmatched,
}

final class SellOutEvent {
  const SellOutEvent({
    required this.id,
    required this.organizationId,
    required this.customerId,
    required this.storeId,
    required this.soldAt,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.grossAmountCents,
    required this.channel,
    required this.sourceType,
    required this.sourceName,
    required this.matchConfidence,
    required this.matchStrategy,
    required this.receivedAt,
  });

  final String id;
  final String organizationId;
  final String customerId;
  final String storeId;
  final DateTime soldAt;
  final String productId;
  final String variantId;
  final int quantity;
  final int grossAmountCents;
  final SellOutChannel channel;
  final SellOutSourceType sourceType;
  final String sourceName;
  final double matchConfidence;
  final ProductMatchStrategy matchStrategy;
  final DateTime receivedAt;

  Duration get latency => receivedAt.difference(soldAt);
}

final class RetailSalesFact {
  const RetailSalesFact({
    required this.organizationId,
    required this.customerId,
    required this.storeId,
    required this.periodKey,
    required this.productId,
    required this.variantId,
    required this.sellOutQuantity,
    required this.sellOutAmountCents,
    required this.sourceName,
    required this.averageConfidence,
    required this.lastUpdatedAt,
  });

  final String organizationId;
  final String customerId;
  final String storeId;
  final String periodKey;
  final String productId;
  final String variantId;
  final int sellOutQuantity;
  final int sellOutAmountCents;
  final String sourceName;
  final double averageConfidence;
  final DateTime lastUpdatedAt;
}

final class SellOutRawRow {
  const SellOutRawRow({
    required this.externalEventId,
    required this.organizationId,
    required this.customerId,
    required this.storeId,
    required this.soldAt,
    required this.quantity,
    required this.grossAmountCents,
    required this.channel,
    required this.sourceType,
    required this.sourceName,
    this.ean,
    this.sku,
    this.reference,
    this.color,
    this.size,
    this.consumerName,
    this.consumerDocument,
    this.consumerEmail,
  });

  final String externalEventId;
  final String organizationId;
  final String customerId;
  final String storeId;
  final DateTime soldAt;
  final int quantity;
  final int grossAmountCents;
  final SellOutChannel channel;
  final SellOutSourceType sourceType;
  final String sourceName;
  final String? ean;
  final String? sku;
  final String? reference;
  final String? color;
  final String? size;
  final String? consumerName;
  final String? consumerDocument;
  final String? consumerEmail;

  bool get hasConsumerPersonalData =>
      _hasText(consumerName) ||
      _hasText(consumerDocument) ||
      _hasText(consumerEmail);

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

final class ProductMatchCandidate {
  const ProductMatchCandidate({
    required this.productId,
    required this.variantId,
    this.ean,
    this.sku,
    this.customerEquivalentCode,
    this.reference,
    this.color,
    this.size,
  });

  final String productId;
  final String variantId;
  final String? ean;
  final String? sku;
  final String? customerEquivalentCode;
  final String? reference;
  final String? color;
  final String? size;
}

final class ProductMatchResult {
  const ProductMatchResult({
    required this.productId,
    required this.variantId,
    required this.strategy,
    required this.confidence,
  });

  final String productId;
  final String variantId;
  final ProductMatchStrategy strategy;
  final double confidence;
}

final class SellOutProductMatcher {
  const SellOutProductMatcher();

  ProductMatchResult? match({
    required SellOutRawRow row,
    required Iterable<ProductMatchCandidate> candidates,
    required Map<String, String> customerEquivalence,
  }) {
    ProductMatchResult? by(
      bool Function(ProductMatchCandidate) test,
      ProductMatchStrategy strategy,
      double confidence,
    ) {
      for (final candidate in candidates) {
        if (test(candidate)) {
          return ProductMatchResult(
            productId: candidate.productId,
            variantId: candidate.variantId,
            strategy: strategy,
            confidence: confidence,
          );
        }
      }
      return null;
    }

    final ean = _norm(row.ean);
    if (ean != null) {
      final result = by(
        (candidate) => _norm(candidate.ean) == ean,
        ProductMatchStrategy.ean,
        1,
      );
      if (result != null) return result;
    }

    final sku = _norm(row.sku);
    if (sku != null) {
      final result = by(
        (candidate) => _norm(candidate.sku) == sku,
        ProductMatchStrategy.sku,
        0.95,
      );
      if (result != null) return result;
    }

    final equivalent = customerEquivalence[_norm(row.reference) ?? ''];
    if (equivalent != null) {
      final result = by(
        (candidate) => candidate.variantId == equivalent,
        ProductMatchStrategy.customerEquivalence,
        0.9,
      );
      if (result != null) return result;
    }

    final reference = _norm(row.reference);
    final color = _norm(row.color);
    final size = _norm(row.size);
    if (reference != null && color != null && size != null) {
      return by(
        (candidate) =>
            _norm(candidate.reference) == reference &&
            _norm(candidate.color) == color &&
            _norm(candidate.size) == size,
        ProductMatchStrategy.colorSize,
        0.75,
      );
    }
    return null;
  }

  String? _norm(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

final class SellOutIngestionIssue {
  const SellOutIngestionIssue({
    required this.externalEventId,
    required this.message,
  });

  final String externalEventId;
  final String message;
}

final class SellOutIngestionBatchResult {
  const SellOutIngestionBatchResult({
    required this.batchId,
    required this.acceptedEvents,
    required this.rejectedRows,
    required this.duplicateExternalEventIds,
  });

  final String batchId;
  final List<SellOutEvent> acceptedEvents;
  final List<SellOutIngestionIssue> rejectedRows;
  final Set<String> duplicateExternalEventIds;
}

final class SellOutIngestionService {
  const SellOutIngestionService({this.matcher = const SellOutProductMatcher()});

  final SellOutProductMatcher matcher;

  SellOutIngestionBatchResult ingest({
    required String batchId,
    required DateTime receivedAt,
    required Iterable<SellOutRawRow> rows,
    required Iterable<ProductMatchCandidate> candidates,
    required Set<String> alreadyProcessedEventIds,
    Map<String, String> customerEquivalence = const {},
  }) {
    final accepted = <SellOutEvent>[];
    final rejected = <SellOutIngestionIssue>[];
    final duplicates = <String>{};
    final seenInBatch = <String>{};

    for (final row in rows) {
      final idempotencyKey =
          '${row.organizationId}:${row.customerId}:${row.externalEventId}';
      if (alreadyProcessedEventIds.contains(idempotencyKey) ||
          !seenInBatch.add(idempotencyKey)) {
        duplicates.add(row.externalEventId);
        continue;
      }
      if (row.hasConsumerPersonalData) {
        rejected.add(
          SellOutIngestionIssue(
            externalEventId: row.externalEventId,
            message: 'Payload POS contem dado pessoal de consumidor final.',
          ),
        );
        continue;
      }
      if (row.quantity <= 0 || row.grossAmountCents < 0) {
        rejected.add(
          SellOutIngestionIssue(
            externalEventId: row.externalEventId,
            message: 'Quantidade ou valor invalido.',
          ),
        );
        continue;
      }
      final match = matcher.match(
        row: row,
        candidates: candidates,
        customerEquivalence: customerEquivalence,
      );
      if (match == null) {
        rejected.add(
          SellOutIngestionIssue(
            externalEventId: row.externalEventId,
            message: 'Produto/variante nao encontrado para sell-out.',
          ),
        );
        continue;
      }
      accepted.add(
        SellOutEvent(
          id: idempotencyKey,
          organizationId: row.organizationId,
          customerId: row.customerId,
          storeId: row.storeId,
          soldAt: row.soldAt,
          productId: match.productId,
          variantId: match.variantId,
          quantity: row.quantity,
          grossAmountCents: row.grossAmountCents,
          channel: row.channel,
          sourceType: row.sourceType,
          sourceName: row.sourceName,
          matchConfidence: match.confidence,
          matchStrategy: match.strategy,
          receivedAt: receivedAt,
        ),
      );
    }

    return SellOutIngestionBatchResult(
      batchId: batchId,
      acceptedEvents: accepted,
      rejectedRows: rejected,
      duplicateExternalEventIds: duplicates,
    );
  }
}

final class SellInSellOutMetric {
  const SellInSellOutMetric({
    required this.productId,
    required this.sellInQuantity,
    required this.sellOutQuantity,
  });

  final String productId;
  final int sellInQuantity;
  final int sellOutQuantity;

  double get sellThroughRate =>
      sellInQuantity <= 0 ? 0 : sellOutQuantity / sellInQuantity;
}

final class SellOutFactAggregator {
  const SellOutFactAggregator();

  List<RetailSalesFact> aggregateMonthly(Iterable<SellOutEvent> events) {
    final groups = <String, List<SellOutEvent>>{};
    for (final event in events) {
      final key = [
        event.organizationId,
        event.customerId,
        event.storeId,
        _periodKey(event.soldAt),
        event.productId,
        event.variantId,
      ].join('|');
      groups.putIfAbsent(key, () => <SellOutEvent>[]).add(event);
    }
    return groups.values
        .map((group) {
          final first = group.first;
          return RetailSalesFact(
            organizationId: first.organizationId,
            customerId: first.customerId,
            storeId: first.storeId,
            periodKey: _periodKey(first.soldAt),
            productId: first.productId,
            variantId: first.variantId,
            sellOutQuantity: group.fold(
              0,
              (sum, event) => sum + event.quantity,
            ),
            sellOutAmountCents: group.fold(
              0,
              (sum, event) => sum + event.grossAmountCents,
            ),
            sourceName: first.sourceName,
            averageConfidence:
                group.fold<double>(
                  0,
                  (sum, event) => sum + event.matchConfidence,
                ) /
                group.length,
            lastUpdatedAt: group
                .map((event) => event.receivedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b),
          );
        })
        .toList(growable: false);
  }

  String _periodKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }
}
