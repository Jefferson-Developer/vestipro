import {
  type Insight,
  type InsightContext,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

export class InactiveCustomerInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    return context.dataset.customerSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId ||
        snapshot.customerStatus.trim().toLowerCase() === 'inactive' ||
        !snapshot.lastOrderAt
      ) {
        return [];
      }

      const normalizedSegment = snapshot.segment?.trim().toLowerCase() ?? '';
      const threshold =
        context.dataset.settings.inactivityThresholdDaysBySegment[
          normalizedSegment
        ] ?? context.dataset.settings.inactivityThresholdDays;
      const daysWithoutPurchase = Math.floor(
        (context.asOf.getTime() - snapshot.lastOrderAt.getTime()) /
          (24 * 60 * 60 * 1000),
      );
      if (daysWithoutPurchase < threshold) {
        return [];
      }

      const averageTicket = snapshot.averageTicket ?? snapshot.lastOrderValue ?? 0;
      const expiresAt = new Date(
        context.asOf.getTime() +
          context.dataset.settings.lifetimeDays * 24 * 60 * 60 * 1000,
      );

      return [
        {
          id: `inactive_customer:${snapshot.recipientUserId}:${snapshot.customerId}`,
          type: 'inactiveCustomer',
          title: `Cliente inativo: ${snapshot.customerName}`,
          description: `${snapshot.customerName} esta sem comprar ha ${daysWithoutPurchase} dias.`,
          evidence: [
            {
              code: 'last_order_date',
              label: 'Data do ultimo pedido',
              value: snapshot.lastOrderAt.toISOString(),
            },
            ...(snapshot.lastOrderValue == null
              ? []
              : [
                  {
                    code: 'last_order_value',
                    label: 'Valor do ultimo pedido',
                    value: snapshot.lastOrderValue.toFixed(2),
                    numericValue: snapshot.lastOrderValue,
                    unit: 'BRL',
                  },
                ]),
            {
              code: 'average_ticket',
              label: 'Ticket medio historico',
              value: averageTicket.toFixed(2),
              numericValue: averageTicket,
              unit: 'BRL',
            },
            {
              code: 'days_without_purchase',
              label: 'Dias sem compra',
              value: `${daysWithoutPurchase}`,
              numericValue: daysWithoutPurchase,
              unit: 'days',
            },
          ],
          estimatedImpact: {
            amount: averageTicket,
            currencyCode: 'BRL',
          },
          severity: severityFor(daysWithoutPurchase, threshold),
          confidenceScore: 0.82,
          recommendation:
            'Agende um contato com o cliente e retome a carteira antes de perder recorrencia.',
          quickAction: {
            type: 'scheduleContact',
            label: 'Agendar contato',
            customerId: snapshot.customerId,
            payload: {
              customerId: snapshot.customerId,
              suggestedReason: 'inactive_customer',
            },
          },
          secondaryActions: [
            {
              type: 'openCustomer',
              label: 'Abrir cliente',
              route: `/customers/${snapshot.customerId}`,
              customerId: snapshot.customerId,
            },
          ],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          sellerId: snapshot.responsibleSellerId ?? undefined,
          generatedAt: context.asOf,
          expiresAt,
          status: 'fresh',
        },
      ];
    });
  }
}

function severityFor(
  daysWithoutPurchase: number,
  threshold: number,
): InsightSeverity {
  if (daysWithoutPurchase >= threshold * 3) {
    return 'critical';
  }
  if (daysWithoutPurchase >= threshold * 2) {
    return 'high';
  }
  if (daysWithoutPurchase >= threshold + 15) {
    return 'medium';
  }
  return 'low';
}
