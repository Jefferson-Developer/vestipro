import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

@lazySingleton
final class InactiveCustomerInsightRule implements InsightRule {
  const InactiveCustomerInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    for (final snapshot in context.dataset.customerSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId ||
          snapshot.isAdministrativelyInactive ||
          snapshot.lastOrderAt == null) {
        continue;
      }

      final threshold = context.dataset.settings.resolveInactivityThreshold(
        snapshot.segment,
      );
      final daysWithoutPurchase = context.asOf
          .difference(snapshot.lastOrderAt!)
          .inDays;
      if (daysWithoutPurchase < threshold) {
        continue;
      }

      final averageTicket =
          snapshot.averageTicket ?? snapshot.lastOrderValue ?? 0;
      final expiresAt = context.asOf.add(
        context.dataset.settings.defaultLifetime,
      );
      insights.add(
        Insight(
          id: 'inactive_customer:${snapshot.recipientUserId}:${snapshot.customerId}',
          type: InsightType.inactiveCustomer,
          title: 'Cliente inativo: ${snapshot.customerName}',
          description:
              '${snapshot.customerName} esta sem comprar ha $daysWithoutPurchase dias.',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'last_order_date',
              label: 'Data do ultimo pedido',
              value: snapshot.lastOrderAt!.toIso8601String(),
            ),
            if (snapshot.lastOrderValue != null)
              InsightEvidence(
                code: 'last_order_value',
                label: 'Valor do ultimo pedido',
                value: snapshot.lastOrderValue!.toStringAsFixed(2),
                numericValue: snapshot.lastOrderValue,
                unit: 'BRL',
              ),
            InsightEvidence(
              code: 'average_ticket',
              label: 'Ticket medio historico',
              value: averageTicket.toStringAsFixed(2),
              numericValue: averageTicket,
              unit: 'BRL',
            ),
            InsightEvidence(
              code: 'days_without_purchase',
              label: 'Dias sem compra',
              value: '$daysWithoutPurchase',
              numericValue: daysWithoutPurchase.toDouble(),
              unit: 'days',
            ),
          ],
          estimatedImpact: InsightEstimatedImpact(amount: averageTicket),
          severity: _severityFor(daysWithoutPurchase, threshold),
          confidenceScore: 0.82,
          recommendation:
              'Agende um contato com o cliente e retome a carteira antes de perder recorrencia.',
          quickAction: InsightAction(
            type: InsightActionType.scheduleContact,
            label: 'Agendar contato',
            customerId: snapshot.customerId,
            payload: <String, Object?>{
              'customerId': snapshot.customerId,
              'suggestedReason': 'inactive_customer',
            },
          ),
          secondaryActions: <InsightAction>[
            InsightAction(
              type: InsightActionType.openCustomer,
              label: 'Abrir cliente',
              route: '/customers/${snapshot.customerId}',
              customerId: snapshot.customerId,
            ),
          ],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          sellerId: snapshot.responsibleSellerId,
          generatedAt: context.asOf,
          expiresAt: expiresAt,
          status: InsightStatus.fresh,
        ),
      );
    }
    return insights;
  }

  InsightSeverity _severityFor(int daysWithoutPurchase, int threshold) {
    if (daysWithoutPurchase >= threshold * 3) {
      return InsightSeverity.critical;
    }
    if (daysWithoutPurchase >= threshold * 2) {
      return InsightSeverity.high;
    }
    if (daysWithoutPurchase >= threshold + 15) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
