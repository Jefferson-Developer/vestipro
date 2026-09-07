import { createHmac, timingSafeEqual } from 'node:crypto';
import { HttpsError } from 'firebase-functions/v2/https';

export const WHATSAPP_OPT_IN_STATUSES = [
  'requested',
  'accepted',
  'refused',
  'revoked',
] as const;

export type WhatsAppOptInStatus = (typeof WHATSAPP_OPT_IN_STATUSES)[number];
export type WhatsAppDeliveryStatus = 'sent' | 'delivered' | 'read' | 'failed';

const DELIVERY_RANK: Readonly<Record<WhatsAppDeliveryStatus, number>> = {
  sent: 0,
  delivered: 1,
  read: 2,
  failed: 3,
};

export function requireOptInStatus(value: unknown): WhatsAppOptInStatus {
  if (!WHATSAPP_OPT_IN_STATUSES.includes(value as WhatsAppOptInStatus)) {
    throw new HttpsError('invalid-argument', 'Status de consentimento invalido.');
  }
  return value as WhatsAppOptInStatus;
}

export function assertOptInTransition(
  current: WhatsAppOptInStatus | null,
  next: WhatsAppOptInStatus,
): void {
  const allowed: Readonly<Record<string, readonly WhatsAppOptInStatus[]>> = {
    none: ['requested'],
    requested: ['accepted', 'refused', 'revoked'],
    accepted: ['revoked'],
    refused: ['requested'],
    revoked: ['requested'],
  };
  if (!allowed[current ?? 'none'].includes(next)) {
    throw new HttpsError(
      'failed-precondition',
      `Transicao de consentimento ${current ?? 'ausente'} -> ${next} nao permitida.`,
    );
  }
}

export function normalizeWhatsAppPhone(value: unknown): string {
  if (typeof value !== 'string') {
    throw new HttpsError('failed-precondition', 'Cliente sem telefone para WhatsApp.');
  }
  const digits = value.replace(/\D/g, '');
  if (digits.length < 8 || digits.length > 15) {
    throw new HttpsError('failed-precondition', 'Telefone do cliente invalido para WhatsApp.');
  }
  return digits;
}

export function validateWhatsAppSendContext(
  optInStatus: unknown,
  templateStatus: unknown,
  expectedVariables: number,
  variables: readonly string[],
): void {
  if (optInStatus !== 'accepted') {
    throw new HttpsError('failed-precondition', 'O cliente nao possui opt-in ativo para WhatsApp.');
  }
  if (templateStatus !== 'approved') {
    throw new HttpsError('failed-precondition', 'Template nao aprovado ou indisponivel.');
  }
  if (variables.length !== expectedVariables) {
    throw new HttpsError('invalid-argument', `O template exige ${expectedVariables} variaveis.`);
  }
}

export function resolveDeliveryStatus(
  current: WhatsAppDeliveryStatus | null,
  incoming: WhatsAppDeliveryStatus,
): WhatsAppDeliveryStatus {
  if (current === 'failed' || incoming === 'failed') return incoming;
  return current && DELIVERY_RANK[current] > DELIVERY_RANK[incoming] ? current : incoming;
}

export function verifyWebhookSignature(
  rawBody: Buffer,
  signatureHeader: string | undefined,
  appSecret: string,
): boolean {
  if (!signatureHeader?.startsWith('sha256=')) return false;
  const supplied = Buffer.from(signatureHeader.slice(7), 'hex');
  const expected = createHmac('sha256', appSecret).update(rawBody).digest();
  return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}

export interface MetaTemplateRequest {
  phoneNumberId: string;
  accessToken: string;
  to: string;
  templateName: string;
  language: string;
  variables: readonly string[];
}

export async function sendMetaTemplateMessage(
  request: MetaTemplateRequest,
  fetcher: typeof fetch = fetch,
): Promise<string> {
  const response = await fetcher(
    `https://graph.facebook.com/v21.0/${request.phoneNumberId}/messages`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${request.accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to: request.to,
        type: 'template',
        template: {
          name: request.templateName,
          language: { code: request.language },
          components: request.variables.length === 0
            ? []
            : [{
                type: 'body',
                parameters: request.variables.map((text) => ({ type: 'text', text })),
              }],
        },
      }),
    },
  );
  const payload = (await response.json()) as {
    messages?: Array<{ id?: string }>;
    error?: { message?: string; code?: number };
  };
  if (!response.ok) {
    if (response.status === 401) {
      throw new HttpsError('failed-precondition', 'Token do WhatsApp expirado. Contate o administrador.');
    }
    if (response.status === 429) {
      throw new HttpsError('resource-exhausted', 'Limite de envios do WhatsApp atingido. Tente mais tarde.');
    }
    throw new HttpsError('unavailable', payload.error?.message ?? 'WhatsApp indisponivel no momento.');
  }
  const id = payload.messages?.[0]?.id;
  if (!id) throw new HttpsError('internal', 'WhatsApp nao retornou o identificador da mensagem.');
  return id;
}
