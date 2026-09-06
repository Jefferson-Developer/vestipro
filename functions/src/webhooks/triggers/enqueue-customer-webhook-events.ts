import { logger } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

import { enqueueWebhookEvent } from '../enqueue-webhook-event';

/**
 * Produces the `customer.created` webhook event (TASK-170) from the exact
 * customer-creation write (TASK-048/049/051 — customer create/update is
 * Cloud-Function-only, per `firestore.rules`' `customers/{customerId}`
 * rule). Fires once, on creation only — updates to an existing customer
 * never produce a webhook event in this task's scope (only
 * `order.created`/`order.status_changed`/`customer.created`/
 * `inventory.updated` are in scope per TASK-170).
 *
 * Payload deliberately limited to identity fields a downstream ERP/CRM
 * integration actually needs to reconcile the customer by — never CRM-only
 * fields (`classification`, `potential`, `segment`, scoring) that stay
 * internal to VestiPro.
 */
export const enqueueCustomerWebhookEvents = onDocumentCreated(
  'organizations/{organizationId}/customers/{customerId}',
  async (event) => {
    const { organizationId, customerId } = event.params;
    const customer = event.data?.data();
    if (!customer) return;

    const db = getFirestore();
    try {
      await enqueueWebhookEvent(db, {
        organizationId,
        eventType: 'customer.created',
        entityId: customerId,
        sourceVersion: String(customer.version ?? 1),
        data: {
          customerId,
          organizationId,
          document: customer.document ?? null,
          legalName: customer.legalName ?? null,
          fullName: customer.fullName ?? null,
          createdAt:
            customer.createdAt?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
        },
        now: new Date(),
      });
    } catch (error) {
      logger.error('enqueueCustomerWebhookEvents failed', {
        organizationId,
        customerId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);
