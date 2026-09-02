import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../entities/insight_organization_settings.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Detects order drafts (`OrderStatus.draft`/`pendingSync`, TASK-096) left
/// untouched for too long, distinguishing a recently-parked "carrinho salvo"
/// from a truly stale "pedido abandonado", so the seller can resume the
/// draft in the exact state it was left, or reach out to the customer.
@lazySingleton
final class AbandonedDraftOrderInsightRule implements InsightRule {
  const AbandonedDraftOrderInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;

    for (final snapshot in context.dataset.abandonedOrderSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      // Only the elapsed time since the last *content* change decides
      // abandonment — a draft with a pending Outbox sync (TASK-108) but
      // recently edited content must never be flagged, regardless of
      // `hasPendingOutboxSync`.
      final hoursSinceChange =
          context.asOf.difference(snapshot.lastContentChangeAt).inMinutes / 60;

      final band = _bandFor(hoursSinceChange, settings);
      if (band == null) {
        continue;
      }

      final expiresAt = context.asOf.add(settings.defaultLifetime);
      final evidence = <InsightEvidence>[
        InsightEvidence(
          code: 'last_content_change_at',
          label: 'Ultima alteracao do rascunho',
          value: snapshot.lastContentChangeAt.toIso8601String(),
        ),
        InsightEvidence(
          code: 'hours_since_last_change',
          label: 'Horas sem alteracao',
          value: hoursSinceChange.toStringAsFixed(1),
          numericValue: hoursSinceChange,
          unit: 'hours',
        ),
        InsightEvidence(
          code: 'item_count',
          label: 'Itens no rascunho',
          value: '${snapshot.itemCount}',
          numericValue: snapshot.itemCount.toDouble(),
        ),
        InsightEvidence(
          code: 'estimated_value',
          label: 'Valor estimado do rascunho',
          value: snapshot.estimatedValue.toStringAsFixed(2),
          numericValue: snapshot.estimatedValue,
          unit: 'BRL',
        ),
        InsightEvidence(
          code: 'abandoned_order_band',
          label: 'Faixa de abandono',
          value: band.label,
        ),
        if (snapshot.hasInvalidReference)
          InsightEvidence(
            code: 'invalid_reference_warning',
            label: 'Aviso ao retomar',
            value:
                snapshot.invalidReferenceReason ??
                'Cliente, produto ou tabela de preco vinculados podem ter mudado.',
          ),
      ];

      insights.add(
        Insight(
          id: 'abandoned_order:${snapshot.recipientUserId}:${snapshot.customerId}:${snapshot.orderId}',
          type: InsightType.abandonedOrder,
          title: '${band.label}: ${snapshot.customerName}',
          description:
              'O rascunho de pedido de ${snapshot.customerName} esta parado '
              'ha ${hoursSinceChange.toStringAsFixed(0)}h sem alteracao, com '
              '${snapshot.itemCount} item(ns) e valor estimado de R\$ '
              '${snapshot.estimatedValue.toStringAsFixed(2)}.'
              '${snapshot.hasInvalidReference ? ' Atencao: ${snapshot.invalidReferenceReason ?? 'dados vinculados ao rascunho podem ter mudado'}.' : ''}',
          evidence: evidence,
          estimatedImpact: InsightEstimatedImpact(
            amount: snapshot.estimatedValue,
          ),
          severity: band.severity,
          confidenceScore: 0.95,
          recommendation: snapshot.hasInvalidReference
              ? 'Revise o cliente, os produtos e a tabela de preco vinculados '
                    'antes de retomar o pedido — algo pode ter mudado desde a '
                    'ultima edicao.'
              : 'Retome o rascunho no estado em que foi deixado ou contate o '
                    'cliente para entender se ainda ha interesse na compra.',
          quickAction: InsightAction(
            type: InsightActionType.resumeOrder,
            label: 'Retomar pedido',
            route: '/orders/draft?orderId=${snapshot.orderId}',
            customerId: snapshot.customerId,
            payload: <String, Object?>{
              'orderId': snapshot.orderId,
              'customerId': snapshot.customerId,
              'hasInvalidReference': snapshot.hasInvalidReference,
            },
          ),
          secondaryActions: <InsightAction>[
            if (snapshot.startedInServiceContext)
              InsightAction(
                type: InsightActionType.scheduleContact,
                label: 'Contatar cliente',
                customerId: snapshot.customerId,
                payload: <String, Object?>{
                  'customerId': snapshot.customerId,
                  'orderId': snapshot.orderId,
                  'suggestedReason': 'abandoned_order',
                },
              ),
            InsightAction(
              type: InsightActionType.openCustomer,
              label: 'Abrir cliente 360',
              route: '/customers/${snapshot.customerId}',
              customerId: snapshot.customerId,
            ),
          ],
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

  _AbandonedOrderBand? _bandFor(
    double hoursSinceChange,
    InsightOrganizationSettings settings,
  ) {
    if (hoursSinceChange >= settings.abandonedOrderAbandonedThresholdHours) {
      return const _AbandonedOrderBand(
        'Pedido abandonado',
        InsightSeverity.medium,
      );
    }
    if (hoursSinceChange >= settings.abandonedOrderSavedCartThresholdHours) {
      return const _AbandonedOrderBand('Carrinho salvo', InsightSeverity.low);
    }
    return null;
  }
}

final class _AbandonedOrderBand {
  const _AbandonedOrderBand(this.label, this.severity);

  final String label;
  final InsightSeverity severity;
}
