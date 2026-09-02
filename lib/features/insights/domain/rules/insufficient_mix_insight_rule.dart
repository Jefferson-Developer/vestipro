import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../entities/insight_insufficient_mix_category_candidate.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Maximum number of missing-category suggestions bundled into a single
/// insufficient-mix insight per customer.
const int _maxMissingCategoriesPerCustomer = 5;

/// Identifies customers whose mix (number of distinct categories purchased)
/// sits below the benchmark of an organization-configured comparison group
/// (segment, region, porte, or a combination). The benchmark is never
/// hardcoded: it is derived, category by category, from each candidate's
/// [InsightInsufficientMixCategoryCandidate.peerAdoptionRate] — by linearity
/// of expectation, the sum of adoption rates across the comparison universe
/// equals the group's average number of distinct categories purchased per
/// customer — so the comparison basis is always explainable, never a black
/// box.
@lazySingleton
final class InsufficientMixInsightRule implements InsightRule {
  const InsufficientMixInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    final threshold = settings.insufficientMixThresholdPercentage;
    final expiresAt = context.asOf.add(settings.defaultLifetime);

    for (final snapshot in context.dataset.insufficientMixSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      final excludedCategoryIds = settings
          .resolveInsufficientMixExcludedCategoryIds(snapshot.segment);
      final eligibleCandidates = snapshot.candidates
          .where(
            (candidate) => !excludedCategoryIds.contains(candidate.categoryId),
          )
          .toList();
      if (eligibleCandidates.isEmpty) {
        continue;
      }

      final benchmarkCategoryCount = eligibleCandidates.fold<double>(
        0,
        (sum, candidate) => sum + candidate.peerAdoptionRate,
      );
      if (benchmarkCategoryCount <= 0) {
        continue;
      }

      final customerCategoryCount = eligibleCandidates
          .where((candidate) => candidate.purchasedByCustomer)
          .length;
      final ratio = customerCategoryCount / benchmarkCategoryCount;
      if (ratio >= threshold) {
        continue;
      }

      final missingCategories =
          eligibleCandidates
              .where((candidate) => !candidate.purchasedByCustomer)
              .toList()
            ..sort((a, b) => b.peerAdoptionRate.compareTo(a.peerAdoptionRate));
      if (missingCategories.isEmpty) {
        continue;
      }

      final suggestions = missingCategories
          .take(_maxMissingCategoriesPerCustomer)
          .toList();
      final gap = 1 - ratio;

      insights.add(
        Insight(
          id: 'insufficient_mix:${snapshot.recipientUserId}:${snapshot.customerId}',
          type: InsightType.insufficientMix,
          title: 'Mix abaixo do ideal: ${snapshot.customerName}',
          description:
              '${snapshot.customerName} compra $customerCategoryCount '
              'categoria(s) distinta(s), abaixo do benchmark de '
              '${benchmarkCategoryCount.toStringAsFixed(1)} de clientes '
              'semelhantes (${snapshot.comparisonGroupLabel}, '
              '${snapshot.comparisonGroupSize} clientes na base de '
              'comparacao) — ${(ratio * 100).toStringAsFixed(1)}% do '
              'benchmark do grupo.',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'insufficient_mix_comparison_group',
              label: 'Base de comparacao (clientes semelhantes)',
              value: snapshot.comparisonGroupLabel,
              numericValue: snapshot.comparisonGroupSize.toDouble(),
            ),
            InsightEvidence(
              code: 'insufficient_mix_customer_category_count',
              label: 'Categorias distintas compradas pelo cliente',
              value: '$customerCategoryCount',
              numericValue: customerCategoryCount.toDouble(),
            ),
            InsightEvidence(
              code: 'insufficient_mix_benchmark_category_count',
              label: 'Benchmark de categorias distintas do grupo de comparacao',
              value: benchmarkCategoryCount.toStringAsFixed(1),
              numericValue: benchmarkCategoryCount,
            ),
            InsightEvidence(
              code: 'insufficient_mix_ratio',
              label: 'Percentual do benchmark atingido pelo cliente',
              value: (ratio * 100).toStringAsFixed(1),
              numericValue: ratio * 100,
              unit: 'percent',
            ),
            for (final candidate in suggestions)
              InsightEvidence(
                code:
                    'insufficient_mix_missing_category:${candidate.categoryId}',
                label: 'Categoria ausente no mix: "${candidate.categoryName}"',
                value: (candidate.peerAdoptionRate * 100).toStringAsFixed(1),
                numericValue: candidate.peerAdoptionRate * 100,
                unit: 'percent',
              ),
          ],
          estimatedImpact: InsightEstimatedImpact(percentage: gap),
          severity: _severityFor(gap),
          confidenceScore: 0.6,
          recommendation:
              'Apresente as categorias ausentes no proximo contato e '
              'aproveite para incluir os itens no pedido em rascunho do '
              'cliente.',
          quickAction: _missingCategoriesAction(
            snapshot.customerId,
            suggestions,
          ),
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          generatedAt: context.asOf,
          expiresAt: expiresAt,
          status: InsightStatus.fresh,
        ),
      );
    }
    return insights;
  }

  InsightAction _missingCategoriesAction(
    String customerId,
    List<InsightInsufficientMixCategoryCandidate> missingCategories,
  ) {
    final categoryIds = <String>[
      for (final candidate in missingCategories) candidate.categoryId,
    ];
    final categoryNames = <String>[
      for (final candidate in missingCategories) candidate.categoryName,
    ];
    return InsightAction(
      type: InsightActionType.viewCategory,
      label: 'Ver categorias ausentes',
      route:
          '/catalog?customerId=$customerId&categoryIds=${categoryIds.join(',')}&addToDraftOrder=true',
      customerId: customerId,
      payload: <String, Object?>{
        'customerId': customerId,
        'categoryIds': categoryIds,
        'categoryNames': categoryNames,
        'suggestedReason': 'insufficient_mix',
      },
    );
  }

  InsightSeverity _severityFor(double gap) {
    if (gap >= 0.6) {
      return InsightSeverity.high;
    }
    if (gap >= 0.35) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
