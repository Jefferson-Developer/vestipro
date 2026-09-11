import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { computeOutstandingAmount, mapReceivable } from './receivables-shared';

/**
 * Integrates recebíveis into TASK-212's `CustomerCreditProfile`
 * (`creditProfiles/{customerId}`), exactly the wiring `tasks.md` asks for:
 * "integrar status de recebíveis ao perfil de crédito da TASK-212". Runs on
 * every `Receivable` write and recomputes that customer's `openBalance`
 * (soma do saldo em aberto de todo título não pago/cancelado) and
 * `overdueBalance` (idem, só os vencidos) from the full, authoritative
 * ledger — never an incremental patch, so a status correction on any single
 * receivable (e.g. `importReceivableInvoice` re-import, `registerPaymentAllocation`)
 * always leaves the aggregate exactly consistent, same "recompute from the
 * source of truth, never patch a running total" precedent
 * `recalculateCustomerScores`/`recomputeStockTurnoverMetrics` already set for
 * other derived aggregates in this codebase.
 *
 * Only ever merges `openBalance`/`overdueBalance`/`dataSource`/
 * `dataUpdatedAt` onto `creditProfiles/{customerId}` — `creditLimit`,
 * `blockPolicy`, `manualBlock` and `override` (all FINANCE-managed via
 * `updateCreditProfile`/`grantCreditOverride`) are never touched here, so a
 * receivable reconciliation can never silently change how a pedido's crédito
 * is evaluated, only the balances that evaluation reads.
 */
export const reconcileReceivablesToCreditProfile = onDocumentWritten(
  'organizations/{organizationId}/receivables/{receivableId}',
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    const customerId = (after?.customerId ?? before?.customerId) as string | undefined;
    if (!customerId) return;
    const companyId = (after?.companyId ?? before?.companyId) as string | undefined;

    const organizationId = event.params.organizationId;
    const db = getFirestore();
    const organizationRef = db.collection('organizations').doc(organizationId);

    const receivablesSnapshot = await organizationRef
      .collection('receivables')
      .where('customerId', '==', customerId)
      .get();

    let openBalance = 0;
    let overdueBalance = 0;
    for (const doc of receivablesSnapshot.docs) {
      const receivable = mapReceivable(doc.id, doc.data());
      if (receivable.status === 'paid' || receivable.status === 'cancelled') continue;
      const outstanding = computeOutstandingAmount(receivable);
      openBalance += outstanding;
      if (receivable.status === 'overdue') overdueBalance += outstanding;
    }

    const now = Timestamp.now();
    await organizationRef
      .collection('creditProfiles')
      .doc(customerId)
      .set(
        {
          organizationId,
          customerId,
          ...(companyId ? { companyId } : {}),
          openBalance: round2(openBalance),
          overdueBalance: round2(overdueBalance),
          dataSource: 'receivables',
          dataUpdatedAt: now,
        },
        { merge: true },
      );
  },
);

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
