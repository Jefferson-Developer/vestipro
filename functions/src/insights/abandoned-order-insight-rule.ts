import {
  type Insight,
  type InsightAction,
  type InsightContext,
  type InsightEvidence,
  type InsightOrganizationSettings,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

interface AbandonedOrderBand {
  label: string;
  severity: InsightSeverity;
}

/**
 * Detects order drafts (`draft`/`pendingSync`) left untouched for too long,
 * distinguishing a recently-parked "carrinho salvo" from a truly stale
 * "pedido abandonado", so the seller can resume the draft in the exact state
 * it was left, or reach out to the customer.
 */
export class AbandonedOrderInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    return context.dataset.abandonedOrderSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId
      ) {
        return [];
      }

      // Only the elapsed time since the last content change decides
      // abandonment — a draft with a pending Outbox sync but recently
      // edited content must never be flagged, regardless of
      // `hasPendingOutboxSync`.
      const hoursSinceChange =
        (context.asOf.getTime() - snapshot.lastContentChangeAt.getTime()) /
        (60 * 60 * 1000);

      const band = bandFor(hoursSinceChange, settings);
      if (!band) {
        return [];
      }

      const expiresAt = new Date(
        context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
      );

      const evidence: InsightEvidence[] = [
        {
          code: 'last_content_change_at',
          label: 'Ultima alteracao do rascunho',
          value: snapshot.lastContentChangeAt.toISOString(),
        },
        {
          code: 'hours_since_last_change',
          label: 'Horas sem alteracao',
          value: hoursSinceChange.toFixed(1),
          numericValue: hoursSinceChange,
          unit: 'hours',
        },
        {
          code: 'item_count',
          label: 'Itens no rascunho',
          value: `${snapshot.itemCount}`,
          numericValue: snapshot.itemCount,
        },
        {
          code: 'estimated_value',
          label: 'Valor estimado do rascunho',
          value: snapshot.estimatedValue.toFixed(2),
          numericValue: snapshot.estimatedValue,
          unit: 'BRL',
        },
        {
          code: 'abandoned_order_band',
          label: 'Faixa de abandono',
          value: band.label,
        },
        ...(snapshot.hasInvalidReference
          ? [
              {
                code: 'invalid_reference_warning',
                label: 'Aviso ao retomar',
                value:
                  snapshot.invalidReferenceReason ??
                  'Cliente, produto ou tabela de preco vinculados podem ter mudado.',
              },
            ]
          : []),
      ];

      const secondaryActions: InsightAction[] = [
        ...(snapshot.startedInServiceContext
          ? [
              {
                type: 'scheduleContact' as const,
                label: 'Contatar cliente',
                customerId: snapshot.customerId,
                payload: {
                  customerId: snapshot.customerId,
                  orderId: snapshot.orderId,
                  suggestedReason: 'abandoned_order',
                },
              },
            ]
          : []),
        {
          type: 'openCustomer',
          label: 'Abrir cliente 360',
          route: `/customers/${snapshot.customerId}`,
          customerId: snapshot.customerId,
        },
      ];

      return [
        {
          id: `abandoned_order:${snapshot.recipientUserId}:${snapshot.customerId}:${snapshot.orderId}`,
          type: 'abandonedOrder',
          title: `${band.label}: ${snapshot.customerName}`,
          description:
            `O rascunho de pedido de ${snapshot.customerName} esta parado ha ` +
            `${hoursSinceChange.toFixed(0)}h sem alteracao, com ${snapshot.itemCount} ` +
            `item(ns) e valor estimado de R$ ${snapshot.estimatedValue.toFixed(2)}.` +
            (snapshot.hasInvalidReference
              ? ` Atencao: ${snapshot.invalidReferenceReason ?? 'dados vinculados ao rascunho podem ter mudado'}.`
              : ''),
          evidence,
          estimatedImpact: {
            amount: snapshot.estimatedValue,
            currencyCode: 'BRL',
          },
          severity: band.severity,
          confidenceScore: 0.95,
          recommendation: snapshot.hasInvalidReference
            ? 'Revise o cliente, os produtos e a tabela de preco vinculados antes ' +
              'de retomar o pedido — algo pode ter mudado desde a ultima edicao.'
            : 'Retome o rascunho no estado em que foi deixado ou contate o ' +
              'cliente para entender se ainda ha interesse na compra.',
          quickAction: {
            type: 'resumeOrder',
            label: 'Retomar pedido',
            route: `/orders/draft?orderId=${snapshot.orderId}`,
            customerId: snapshot.customerId,
            payload: {
              orderId: snapshot.orderId,
              customerId: snapshot.customerId,
              hasInvalidReference: Boolean(snapshot.hasInvalidReference),
            },
          },
          secondaryActions,
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          generatedAt: context.asOf,
          expiresAt,
          status: 'fresh',
        },
      ];
    });
  }
}

function bandFor(
  hoursSinceChange: number,
  settings: InsightOrganizationSettings,
): AbandonedOrderBand | null {
  if (hoursSinceChange >= settings.abandonedOrderAbandonedThresholdHours) {
    return { label: 'Pedido abandonado', severity: 'medium' };
  }
  if (hoursSinceChange >= settings.abandonedOrderSavedCartThresholdHours) {
    return { label: 'Carrinho salvo', severity: 'low' };
  }
  return null;
}
