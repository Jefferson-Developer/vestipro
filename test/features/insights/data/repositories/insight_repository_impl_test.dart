import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('InsightRepositoryImpl', () {
    late _InMemoryInsightDataSource dataSource;
    late InsightRepositoryImpl repository;

    setUp(() {
      dataSource = _InMemoryInsightDataSource();
      repository = InsightRepositoryImpl(
        dataSource: dataSource,
        mapper: const InsightMapper(),
        validator: const InsightStructuralValidator(),
      );
    });

    test('persists and paginates with type/status filters', () async {
      final createdAt = DateTime.utc(2026, 9, 1, 12);
      await repository.saveAll(
        organizationId: 'org-1',
        insights: <Insight>[
          _insight(
            id: 'i-1',
            generatedAt: createdAt,
            status: InsightStatus.fresh,
            type: InsightType.inactiveCustomer,
          ),
          _insight(
            id: 'i-2',
            generatedAt: createdAt.subtract(const Duration(minutes: 1)),
            status: InsightStatus.viewed,
            type: InsightType.revenueDrop,
          ),
          _insight(
            id: 'i-3',
            generatedAt: createdAt.subtract(const Duration(minutes: 2)),
            status: InsightStatus.fresh,
            type: InsightType.inactiveCustomer,
          ),
        ],
      );

      final page1 = await repository.listPageByRecipient(
        organizationId: 'org-1',
        recipientUserId: 'seller-1',
        limit: 2,
      );
      final page2 = await repository.listPageByRecipient(
        organizationId: 'org-1',
        recipientUserId: 'seller-1',
        limit: 2,
        before: page1.fold(
          onSuccess: (value) => value.nextCursor,
          onFailure: (_) => null,
        ),
      );
      final filtered = await repository.listPageByRecipient(
        organizationId: 'org-1',
        recipientUserId: 'seller-1',
        type: InsightType.inactiveCustomer,
        status: InsightStatus.fresh,
      );

      expect(
        page1.fold(
          onSuccess: (value) => value.insights.map((item) => item.id).toList(),
          onFailure: (_) => <String>[],
        ),
        <String>['i-1', 'i-2'],
      );
      expect(
        page2.fold(
          onSuccess: (value) => value.insights.map((item) => item.id).toList(),
          onFailure: (_) => <String>[],
        ),
        <String>['i-3'],
      );
      expect(
        filtered.fold(
          onSuccess: (value) => value.insights.map((item) => item.id).toList(),
          onFailure: (_) => <String>[],
        ),
        <String>['i-1', 'i-3'],
      );
    });

    test('rejects invalid insights before persistence', () async {
      final result = await repository.saveAll(
        organizationId: 'org-1',
        insights: <Insight>[
          _insight(
            id: 'invalid',
            generatedAt: DateTime.utc(2026, 9, 1, 12),
            evidence: const <InsightEvidence>[],
          ),
        ],
      );

      expect(
        result.fold(onSuccess: (_) => false, onFailure: (_) => true),
        isTrue,
      );
      expect(dataSource.stored, isEmpty);
    });
  });
}

final class _InMemoryInsightDataSource implements InsightDataSource {
  final List<InsightDto> stored = <InsightDto>[];

  @override
  Future<List<InsightDto>> listPageByRecipient({
    required String organizationId,
    required String recipientUserId,
    int limit = 25,
    DateTime? before,
    String? type,
    String? status,
  }) async {
    final filtered =
        stored
            .where((item) => item.organizationId == organizationId)
            .where((item) => item.recipientUserId == recipientUserId)
            .where((item) => type == null || item.type == type)
            .where((item) => status == null || item.status == status)
            .where(
              (item) => before == null || item.generatedAt.isBefore(before),
            )
            .toList(growable: false)
          ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> saveAll({
    required String organizationId,
    required List<InsightDto> insights,
  }) async {
    for (final insight in insights) {
      stored.removeWhere((item) => item.id == insight.id);
      stored.add(insight);
    }
  }
}

Insight _insight({
  required String id,
  required DateTime generatedAt,
  InsightType type = InsightType.inactiveCustomer,
  InsightStatus status = InsightStatus.fresh,
  List<InsightEvidence>? evidence,
}) {
  return Insight(
    id: id,
    type: type,
    title: 'Title',
    description: 'Description',
    evidence:
        evidence ??
        const <InsightEvidence>[
          InsightEvidence(code: 'e1', label: 'E1', value: 'value'),
        ],
    estimatedImpact: const InsightEstimatedImpact(amount: 1200),
    severity: InsightSeverity.medium,
    confidenceScore: 0.8,
    recommendation: 'Contact customer',
    quickAction: const InsightAction(
      type: InsightActionType.openCustomer,
      label: 'Abrir cliente',
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    recipientUserId: 'seller-1',
    customerId: 'customer-$id',
    generatedAt: generatedAt,
    expiresAt: generatedAt.add(const Duration(days: 7)),
    status: status,
  );
}
