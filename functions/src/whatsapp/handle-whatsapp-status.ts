import { defineSecret } from 'firebase-functions/params';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import { resolveDeliveryStatus, verifyWebhookSignature, type WhatsAppDeliveryStatus } from './whatsapp-shared';

export const whatsappVerifyToken = defineSecret('WHATSAPP_VERIFY_TOKEN');
export const whatsappAppSecret = defineSecret('WHATSAPP_APP_SECRET');

const KNOWN = new Set<WhatsAppDeliveryStatus>(['sent', 'delivered', 'read', 'failed']);

export interface WhatsAppStatusEvent {
  id?: string;
  status?: string;
  errors?: Array<{ title?: string }>;
}

export function extractWhatsAppStatusEvents(body: unknown): WhatsAppStatusEvent[] {
  const value = body as { entry?: unknown } | null;
  const entries = Array.isArray(value?.entry) ? value.entry : [];
  return entries.flatMap((entry: { changes?: Array<{ value?: { statuses?: unknown[] } }> }) =>
    (entry.changes ?? []).flatMap((change) => change.value?.statuses ?? []),
  ) as WhatsAppStatusEvent[];
}

export async function applyWhatsAppStatusEvents(
  db: Firestore,
  statuses: readonly WhatsAppStatusEvent[],
): Promise<void> {
  for (const event of statuses) {
    if (!event.id || !KNOWN.has(event.status as WhatsAppDeliveryStatus)) continue;
    const index = await db.collection('whatsappMessageIndex').doc(event.id).get();
    const mapping = index.data();
    if (!mapping) continue;
    const ref = db.collection('organizations').doc(mapping.organizationId as string).collection('whatsappMessages').doc(mapping.messageId as string);
    await db.runTransaction(async (transaction) => {
      const current = await transaction.get(ref);
      if (!current.exists) return;
      const status = resolveDeliveryStatus((current.data()?.status as WhatsAppDeliveryStatus | undefined) ?? null, event.status as WhatsAppDeliveryStatus);
      transaction.update(ref, { status, failureReason: status === 'failed' ? (event.errors?.[0]?.title ?? 'Falha reportada pelo WhatsApp.') : null, updatedAt: Timestamp.now(), [`statusTimestamps.${status}`]: Timestamp.now() });
    });
  }
}

export const handleWhatsAppStatus = onRequest(
  { secrets: [whatsappVerifyToken, whatsappAppSecret] },
  async (request, response) => {
    if (request.method === 'GET') {
      if (request.query['hub.mode'] === 'subscribe' && request.query['hub.verify_token'] === whatsappVerifyToken.value()) {
        response.status(200).send(String(request.query['hub.challenge'] ?? ''));
      } else response.sendStatus(403);
      return;
    }
    if (request.method !== 'POST' || !verifyWebhookSignature(request.rawBody, request.header('x-hub-signature-256'), whatsappAppSecret.value())) {
      response.sendStatus(403);
      return;
    }
    const db = getFirestore();
    await applyWhatsAppStatusEvents(db, extractWhatsAppStatusEvents(request.body));
    response.sendStatus(200);
  },
);
