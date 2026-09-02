import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
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

    test('listPageByVisibility scopes by recipientUserIds and excludes '
        'dismissed/resolved insights (TASK-132)', () async {
      final generatedAt = DateTime.utc(2026, 9, 1, 12);
      await repository.saveAll(
        organizationId: 'org-1',
        insights: <Insight>[
          _insight(
            id: 'own-1',
            generatedAt: generatedAt,
            recipientUserId: 'seller-1',
          ),
          _insight(
            id: 'own-dismissed',
            generatedAt: generatedAt.subtract(const Duration(minutes: 1)),
            recipientUserId: 'seller-1',
            status: InsightStatus.dismissed,
          ),
          _insight(
            id: 'teammate-1',
            generatedAt: generatedAt.subtract(const Duration(minutes: 2)),
            recipientUserId: 'seller-2',
          ),
          _insight(
            id: 'outsider-1',
            generatedAt: generatedAt.subtract(const Duration(minutes: 3)),
            recipientUserId: 'seller-3',
          ),
        ],
      );

      final ownOnly = await repository.listPageByVisibility(
        organizationId: 'org-1',
        visibility: const InsightVisibilityFilter(
          organizationId: 'org-1',
          userId: 'seller-1',
          mode: InsightVisibilityMode.ownOnly,
        ),
      );
      final teams = await repository.listPageByVisibility(
        organizationId: 'org-1',
        visibility: const InsightVisibilityFilter(
          organizationId: 'org-1',
          userId: 'seller-1',
          mode: InsightVisibilityMode.teams,
          teamMemberIds: <String>{'seller-2'},
        ),
      );
      final allOrganization = await repository.listPageByVisibility(
        organizationId: 'org-1',
        visibility: const InsightVisibilityFilter(
          organizationId: 'org-1',
          userId: 'owner-1',
          mode: InsightVisibilityMode.allOrganization,
        ),
      );
      final none = await repository.listPageByVisibility(
        organizationId: 'org-1',
        visibility: InsightVisibilityFilter.none(
          organizationId: 'org-1',
          userId: 'stranger-1',
        ),
      );

      List<String> idsOf(AppResult<InsightPage> result) => result.fold(
        onSuccess: (page) => page.insights.map((i) => i.id).toList(),
        onFailure: (_) => <String>[],
      );

      expect(idsOf(ownOnly), <String>['own-1']);
      expect(idsOf(teams), <String>['own-1', 'teammate-1']);
      expect(idsOf(allOrganization), <String>[
        'own-1',
        'teammate-1',
        'outsider-1',
      ]);
      expect(idsOf(none), isEmpty);
    });

    test('updateStatus persists the new status and supports undo', () async {
      await repository.saveAll(
        organizationId: 'org-1',
        insights: <Insight>[
          _insight(id: 'i-1', generatedAt: DateTime.utc(2026, 9, 1, 12)),
        ],
      );

      final dismissed = await repository.updateStatus(
        organizationId: 'org-1',
        insightId: 'i-1',
        status: InsightStatus.dismissed,
      );
      expect(
        dismissed.fold(onSuccess: (_) => true, onFailure: (_) => false),
        isTrue,
      );
      expect(dataSource.stored.single.status, 'dismissed');

      final undone = await repository.updateStatus(
        organizationId: 'org-1',
        insightId: 'i-1',
        status: InsightStatus.fresh,
      );
      expect(
        undone.fold(onSuccess: (_) => true, onFailure: (_) => false),
        isTrue,
      );
      expect(dataSource.stored.single.status, 'fresh');
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

  @override
  Future<List<InsightDto>> listPageByVisibility({
    required String organizationId,
    required Set<String>? recipientUserIds,
    int limit = 25,
    DateTime? before,
    String? type,
  }) async {
    if (recipientUserIds != null && recipientUserIds.isEmpty) {
      return const <InsightDto>[];
    }
    final filtered =
        stored
            .where((item) => item.organizationId == organizationId)
            .where(
              (item) =>
                  recipientUserIds == null ||
                  recipientUserIds.contains(item.recipientUserId),
            )
            .where((item) => type == null || item.type == type)
            .where(
              (item) => before == null || item.generatedAt.isBefore(before),
            )
            .toList(growable: false)
          ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> updateStatus({
    required String organizationId,
    required String insightId,
    required String status,
  }) async {
    final index = stored.indexWhere(
      (item) => item.organizationId == organizationId && item.id == insightId,
    );
    if (index == -1) return;
    final current = stored[index];
    stored[index] = InsightDto(
      id: current.id,
      type: current.type,
      title: current.title,
      description: current.description,
      evidence: current.evidence,
      estimatedImpact: current.estimatedImpact,
      severity: current.severity,
      confidenceScore: current.confidenceScore,
      recommendation: current.recommendation,
      quickAction: current.quickAction,
      secondaryActions: current.secondaryActions,
      organizationId: current.organizationId,
      companyId: current.companyId,
      recipientUserId: current.recipientUserId,
      customerId: current.customerId,
      productId: current.productId,
      sellerId: current.sellerId,
      generatedAt: current.generatedAt,
      expiresAt: current.expiresAt,
      status: status,
    );
  }
}

Insight _insight({
  required String id,
  required DateTime generatedAt,
  InsightType type = InsightType.inactiveCustomer,
  InsightStatus status = InsightStatus.fresh,
  List<InsightEvidence>? evidence,
  String recipientUserId = 'seller-1',
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
    recipientUserId: recipientUserId,
    customerId: 'customer-$id',
    generatedAt: generatedAt,
    expiresAt: generatedAt.add(const Duration(days: 7)),
    status: status,
  );
}
