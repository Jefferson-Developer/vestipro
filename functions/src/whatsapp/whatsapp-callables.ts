import { defineSecret } from 'firebase-functions/params';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { loadActiveMembership } from '../invites/invite-shared';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  assertOptInTransition,
  normalizeWhatsAppPhone,
  requireOptInStatus,
  sendMetaTemplateMessage,
  validateWhatsAppSendContext,
  type WhatsAppOptInStatus,
} from './whatsapp-shared';

export const whatsappAccessToken = defineSecret('WHATSAPP_ACCESS_TOKEN');
export const whatsappPhoneNumberId = defineSecret('WHATSAPP_PHONE_NUMBER_ID');

interface BaseRequest extends RequestWithMeta {
  organizationId?: string;
  customerId?: string;
}

export interface SaveWhatsAppTemplateRequest extends RequestWithMeta {
  organizationId?: string;
  templateId?: string;
  name?: string;
  language?: string;
  variables?: unknown;
  description?: string;
}

export const saveWhatsAppTemplate = onCall<SaveWhatsAppTemplateRequest>(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
    }
    const organizationId = required(
      request.data?.organizationId,
      'organizationId',
    );
    const templateId = required(request.data?.templateId, 'templateId');
    const name = required(request.data?.name, 'name');
    const language = required(request.data?.language, 'language');
    if (
      !Array.isArray(request.data?.variables) ||
      !request.data.variables.every(
        (item) => typeof item === 'string' && item.trim() !== '',
      ) ||
      request.data.variables.length > 10
    ) {
      throw new HttpsError('invalid-argument', 'Variaveis do template invalidas.');
    }
    const db = getFirestore();
    const membership = await loadActiveMembership(
      db,
      organizationId,
      request.auth.uid,
    );
    if (membership.roleName !== 'OWNER' && membership.roleName !== 'ADMIN') {
      throw new HttpsError(
        'permission-denied',
        'Apenas OWNER/ADMIN podem cadastrar templates aprovados.',
      );
    }
    const now = Timestamp.now();
    await db
      .collection('organizations')
      .doc(organizationId)
      .collection('whatsappTemplates')
      .doc(templateId)
      .set(
        {
          organizationId,
          name,
          language,
          variables: request.data.variables.map((item) => item.trim()),
          description: request.data.description?.trim() || null,
          status: 'approved',
          updatedAt: now,
          updatedBy: request.auth.uid,
        },
        { merge: true },
      );
    return {
      templateId,
      status: 'approved',
      correlationId: resolveCorrelationId(request.data?._meta),
    };
  },
);

function required(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new HttpsError('invalid-argument', `${field} e obrigatorio.`);
  }
  return value.trim();
}

async function authorize(request: { auth?: { uid: string } | null; data?: BaseRequest }) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const organizationId = required(request.data?.organizationId, 'organizationId');
  const customerId = required(request.data?.customerId, 'customerId');
  const db = getFirestore();
  await loadActiveMembership(db, organizationId, request.auth.uid);
  const customerRef = db.collection('organizations').doc(organizationId).collection('customers').doc(customerId);
  const customer = await customerRef.get();
  if (!customer.exists) throw new HttpsError('not-found', 'Cliente nao encontrado nesta organizacao.');
  return { db, organizationId, customerId, customer: customer.data()!, uid: request.auth.uid };
}

function serializeTimestamp(value: unknown): string | null {
  return value instanceof Timestamp ? value.toDate().toISOString() : null;
}

export const getWhatsAppContext = onCall<BaseRequest>(async (request) => {
  const { db, organizationId, customerId } = await authorize(request);
  const root = db.collection('organizations').doc(organizationId);
  const [optInDoc, templatesQuery, messagesQuery] = await Promise.all([
    root.collection('whatsappOptIns').doc(customerId).get(),
    root.collection('whatsappTemplates').where('status', '==', 'approved').limit(100).get(),
    root.collection('whatsappMessages').where('customerId', '==', customerId).orderBy('createdAt', 'desc').limit(50).get(),
  ]);
  const optIn = optInDoc.data();
  const messages = messagesQuery.docs
    .map((doc) => ({ id: doc.id, ...doc.data(), createdAt: serializeTimestamp(doc.data().createdAt), updatedAt: serializeTimestamp(doc.data().updatedAt) }))
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
  return {
    optIn: optIn ? { ...optIn, requestedAt: serializeTimestamp(optIn.requestedAt), decidedAt: serializeTimestamp(optIn.decidedAt), revokedAt: serializeTimestamp(optIn.revokedAt) } : null,
    templates: templatesQuery.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    messages,
  };
});

export interface UpdateOptInRequest extends BaseRequest {
  status?: WhatsAppOptInStatus;
  channel?: string;
}

export const updateWhatsAppOptIn = onCall<UpdateOptInRequest>(async (request) => {
  const { db, organizationId, customerId, uid } = await authorize(request);
  const status = requireOptInStatus(request.data?.status);
  const channel = required(request.data?.channel, 'channel');
  const ref = db.collection('organizations').doc(organizationId).collection('whatsappOptIns').doc(customerId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const current = (snapshot.data()?.status as WhatsAppOptInStatus | undefined) ?? null;
    assertOptInTransition(current, status);
    const now = Timestamp.now();
    const data: DocumentData = {
      organizationId,
      customerId,
      status,
      channel,
      requestedAt: status === 'requested' ? now : (snapshot.data()?.requestedAt ?? now),
      decidedAt: status === 'accepted' || status === 'refused' ? now : (snapshot.data()?.decidedAt ?? null),
      revokedAt: status === 'revoked' ? now : null,
      updatedAt: now,
      updatedBy: uid,
    };
    if (!snapshot.exists) Object.assign(data, { createdAt: now, createdBy: uid });
    transaction.set(ref, data, { merge: true });
    transaction.set(ref.collection('audit').doc(), { ...data, previousStatus: current, createdAt: now, createdBy: uid });
  });
  return { status, correlationId: resolveCorrelationId(request.data?._meta) };
});

export interface SendWhatsAppRequest extends BaseRequest {
  templateId?: string;
  variables?: unknown;
  catalogShareId?: string;
  notificationId?: string;
}

export const sendWhatsAppMessage = onCall<SendWhatsAppRequest>(
  { secrets: [whatsappAccessToken, whatsappPhoneNumberId] },
  async (request) => {
    const { db, organizationId, customerId, customer, uid } = await authorize(request);
    const templateId = required(request.data?.templateId, 'templateId');
    if (!Array.isArray(request.data?.variables) || !request.data.variables.every((item) => typeof item === 'string')) {
      throw new HttpsError('invalid-argument', 'Variaveis do template invalidas.');
    }
    const variables = request.data.variables.map((item) => item.trim());
    const root = db.collection('organizations').doc(organizationId);
    const [optInSnapshot, templateSnapshot] = await Promise.all([
      root.collection('whatsappOptIns').doc(customerId).get(),
      root.collection('whatsappTemplates').doc(templateId).get(),
    ]);
    const template = templateSnapshot.data();
    const variableNames = Array.isArray(template?.variables) ? template.variables : [];
    validateWhatsAppSendContext(
      optInSnapshot.data()?.status,
      templateSnapshot.exists ? template?.status : null,
      variableNames.length,
      variables,
    );
    // `validateWhatsAppSendContext` rejected a missing template above. Keep
    // this explicit alias so TypeScript carries that server-side guarantee
    // through the rest of the handler.
    const approvedTemplate = template!;
    const catalogShareId = request.data?.catalogShareId?.trim();
    if (catalogShareId) {
      const share = await root.collection('catalogShares').doc(catalogShareId).get();
      if (!share.exists || share.data()?.status !== 'active') {
        throw new HttpsError('failed-precondition', 'Link de catalogo invalido, expirado ou revogado.');
      }
    }
    const phone = normalizeWhatsAppPhone(customer.primaryPhone);
    const messageRef = root.collection('whatsappMessages').doc();
    let metaMessageId: string;
    try {
      metaMessageId = await sendMetaTemplateMessage({
        phoneNumberId: whatsappPhoneNumberId.value(),
        accessToken: whatsappAccessToken.value(),
        to: phone,
        templateName: required(approvedTemplate.name, 'template.name'),
        language: required(approvedTemplate.language, 'template.language'),
        variables,
      });
    } catch (error) {
      await messageRef.set({ organizationId, customerId, templateId, variables, status: 'failed', failureReason: error instanceof Error ? error.message : 'Falha desconhecida.', createdAt: Timestamp.now(), updatedAt: Timestamp.now(), createdBy: uid, notificationId: request.data?.notificationId ?? null, catalogShareId: catalogShareId ?? null });
      throw error;
    }
    const now = Timestamp.now();
    await Promise.all([
      messageRef.set({ organizationId, customerId, templateId, templateName: approvedTemplate.name, language: approvedTemplate.language, variables, status: 'sent', metaMessageId, failureReason: null, notificationId: request.data?.notificationId ?? null, catalogShareId: catalogShareId ?? null, createdAt: now, updatedAt: now, createdBy: uid }),
      db.collection('whatsappMessageIndex').doc(metaMessageId).set({ organizationId, messageId: messageRef.id }),
    ]);
    return { messageId: messageRef.id, metaMessageId, status: 'sent', correlationId: resolveCorrelationId(request.data?._meta) };
  },
);
