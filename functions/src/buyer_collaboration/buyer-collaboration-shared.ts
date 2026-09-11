import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';
import { requireNonEmptyString } from '../invites/invite-shared';
import { normalizeCurrency, optionalString } from '../pricing/calculate-pricing';
import { requirePortalMembership } from '../customer_portal/customer-portal-shared';

/**
 * TASK-211 — colaboração com comprador em seleções/pedidos. A sessão vive em
 * `organizations/{organizationId}/buyerCollaborationSessions/{sessionId}`,
 * sempre escrita pelo Admin SDK (nunca diretamente pelo cliente — mesmo
 * contrato "leitura via Rules, escrita só via Cloud Function" já usado por
 * `orders`/`returnRequests`/`exchangeRequests`), com uma subcoleção
 * `comments` para o histórico de negociação (comentário geral, comentário
 * por item, solicitação de alteração estruturada e evento de sistema).
 */

export const BUYER_COLLABORATION_SELLER_ROLES: ReadonlySet<string> =
  new Set<string>(['OWNER', 'ADMIN', 'SALES_MANAGER', 'SALES_REP']);

export type BuyerCollaborationStatus =
  | 'seller_draft'
  | 'buyer_review'
  | 'changes_requested'
  | 'buyer_approved'
  | 'converted_to_order'
  | 'expired';

export type BuyerCollaborationSourceType =
  | 'cart'
  | 'quote'
  | 'preBook'
  | 'orderDraft';

export const BUYER_COLLABORATION_SOURCE_TYPES: ReadonlySet<string> =
  new Set<string>(['cart', 'quote', 'preBook', 'orderDraft']);

export interface BuyerCollaborationItem {
  itemId: string;
  productId: string;
  productName: string;
  variantId: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface BuyerCollaborationAttachment {
  name: string;
  url: string;
  contentType: string;
}

const DEFAULT_SESSION_TTL_DAYS = 14;
const MS_PER_DAY = 24 * 60 * 60 * 1000;
const MAX_COMMENT_LENGTH = 2000;
const MAX_ATTACHMENTS = 5;

export function requireSessionItems(value: unknown): BuyerCollaborationItem[] {
  if (!Array.isArray(value) || value.length === 0 || value.length > 200) {
    throw new HttpsError(
      'invalid-argument',
      'items deve conter entre 1 e 200 variantes.',
    );
  }
  return value.map((raw, index) => {
    if (!raw || typeof raw !== 'object') {
      throw new HttpsError('invalid-argument', `items[${index}] é inválido.`);
    }
    const item = raw as Record<string, unknown>;
    const quantity = item.quantity;
    if (!Number.isInteger(quantity) || (quantity as number) <= 0) {
      throw new HttpsError(
        'invalid-argument',
        `items[${index}].quantity é inválido.`,
      );
    }
    const unitPrice = normalizeCurrency(item.unitPrice, `items[${index}].unitPrice`);
    return {
      itemId: requireNonEmptyString(item.itemId, `items[${index}].itemId`),
      productId: requireNonEmptyString(item.productId, `items[${index}].productId`),
      productName: requireNonEmptyString(item.productName, `items[${index}].productName`),
      variantId: requireNonEmptyString(item.variantId, `items[${index}].variantId`),
      quantity: quantity as number,
      unitPrice,
      subtotal: Math.round((quantity as number) * unitPrice * 100) / 100,
    };
  });
}

export function computeItemsTotal(items: BuyerCollaborationItem[]): number {
  return Math.round(items.reduce((sum, item) => sum + item.subtotal, 0) * 100) / 100;
}

export function sessionExpiresAt(now: Timestamp): Timestamp {
  return Timestamp.fromMillis(now.toMillis() + DEFAULT_SESSION_TTL_DAYS * MS_PER_DAY);
}

/**
 * Resolves what a session effectively is *right now*: `converted_to_order`
 * is terminal and always trusted as recorded; every other non-`expired`
 * status lazily becomes `expired` once `expiresAt` has passed, mirroring
 * `cart-share-shared.ts#outcome`/`invite-shared.ts#resolveInviteOutcome` —
 * expiry is a computed property, never a value a scheduled job alone is
 * relied upon to have already written by the time a caller reads/acts on
 * the session.
 */
export function effectiveStatus(
  data: DocumentData,
  now: Timestamp,
): BuyerCollaborationStatus {
  const status = data.status as BuyerCollaborationStatus;
  if (status === 'converted_to_order' || status === 'expired') return status;
  const expiresAt = data.expiresAt as Timestamp;
  if (expiresAt.toMillis() <= now.toMillis()) return 'expired';
  return status;
}

export async function loadSessionOrThrow(
  organizationRef: DocumentReference,
  sessionId: string,
): Promise<{ ref: DocumentReference; data: DocumentData }> {
  const ref = organizationRef.collection('buyerCollaborationSessions').doc(sessionId);
  const snapshot = await ref.get();
  const data = snapshot.data();
  if (!snapshot.exists || !data) {
    throw new HttpsError('not-found', 'Sessão de colaboração não encontrada.');
  }
  return { ref, data };
}

/**
 * A SALES_REP only acts on a session it created; OWNER/ADMIN/SALES_MANAGER
 * (the same tenant-wide/managerial roles `submitOrder`/`convertQuoteToOrder`
 * already trust without a team re-check for this class of action) may act on
 * any session in the organization.
 */
export function assertSellerCanAct(
  roleName: string,
  sessionData: DocumentData,
  uid: string,
): void {
  if (!BUYER_COLLABORATION_SELLER_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode gerenciar colaborações com comprador.',
    );
  }
  if (roleName === 'SALES_REP' && sessionData.sellerId !== uid) {
    throw new HttpsError(
      'permission-denied',
      'Apenas o vendedor responsável pode gerenciar esta sessão.',
    );
  }
}

/** Throws unless [uid] is an active CUSTOMER_PORTAL member whose own
 * `customerId` matches the session's — never trusts a `customerId` supplied
 * by the client itself (same "não confiar apenas em organizationId vindo do
 * cliente" rule every other Function in this codebase already follows). */
export async function assertBuyerCanAct(
  organizationId: string,
  uid: string,
  sessionData: DocumentData,
): Promise<void> {
  const { customerId } = await requirePortalMembership(organizationId, uid);
  if (customerId !== sessionData.customerId) {
    throw new HttpsError(
      'permission-denied',
      'Esta sessão de colaboração pertence a outro cliente.',
    );
  }
}

export function requireComment(value: unknown, required: boolean): string | null {
  const comment = typeof value === 'string' ? value.trim() : '';
  if (comment.length > MAX_COMMENT_LENGTH) {
    throw new HttpsError(
      'invalid-argument',
      `O comentário deve ter no máximo ${MAX_COMMENT_LENGTH} caracteres.`,
    );
  }
  if (required && comment.length === 0) {
    throw new HttpsError('invalid-argument', 'Descreva a alteração ou observação.');
  }
  return comment.length === 0 ? null : comment;
}

export function requireAttachments(value: unknown): BuyerCollaborationAttachment[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_ATTACHMENTS) {
    throw new HttpsError(
      'invalid-argument',
      `Envie no máximo ${MAX_ATTACHMENTS} anexos por comentário.`,
    );
  }
  return value.map((raw, index) => {
    if (!raw || typeof raw !== 'object') {
      throw new HttpsError('invalid-argument', `attachments[${index}] é inválido.`);
    }
    const attachment = raw as Record<string, unknown>;
    const url = requireNonEmptyString(attachment.url, `attachments[${index}].url`);
    if (!url.startsWith('https://')) {
      throw new HttpsError(
        'invalid-argument',
        `attachments[${index}].url deve ser um link seguro (https).`,
      );
    }
    return {
      name: requireNonEmptyString(attachment.name, `attachments[${index}].name`),
      url,
      contentType: optionalString(attachment.contentType) ?? 'application/octet-stream',
    };
  });
}

export interface ProposedItemChange {
  itemId: string;
  action: 'update' | 'remove' | 'add';
  requestedQuantity: number | null;
  productId: string | null;
  variantId: string | null;
  productName: string | null;
}

export function requireProposedChanges(value: unknown): ProposedItemChange[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > 50) {
    throw new HttpsError(
      'invalid-argument',
      'proposedChanges deve conter no máximo 50 alterações.',
    );
  }
  return value.map((raw, index) => {
    if (!raw || typeof raw !== 'object') {
      throw new HttpsError('invalid-argument', `proposedChanges[${index}] é inválido.`);
    }
    const change = raw as Record<string, unknown>;
    const action = change.action;
    if (action !== 'update' && action !== 'remove' && action !== 'add') {
      throw new HttpsError(
        'invalid-argument',
        `proposedChanges[${index}].action é inválido.`,
      );
    }
    const requestedQuantity =
      action === 'remove'
        ? null
        : (() => {
            const quantity = change.requestedQuantity;
            if (!Number.isInteger(quantity) || (quantity as number) <= 0) {
              throw new HttpsError(
                'invalid-argument',
                `proposedChanges[${index}].requestedQuantity é inválido.`,
              );
            }
            return quantity as number;
          })();
    return {
      itemId: requireNonEmptyString(change.itemId, `proposedChanges[${index}].itemId`),
      action,
      requestedQuantity,
      productId: optionalString(change.productId) ?? null,
      variantId: optionalString(change.variantId) ?? null,
      productName: optionalString(change.productName) ?? null,
    };
  });
}

/** Every active CUSTOMER_PORTAL membership scoped to [customerId] — used to
 * notify every portal user of that buyer, not just whoever happens to be
 * signed in when the seller shares/revises a session. */
export async function findPortalRecipientUids(
  db: Firestore,
  organizationId: string,
  customerId: string,
): Promise<string[]> {
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('members')
    .where('roleName', '==', 'CUSTOMER_PORTAL')
    .where('customerId', '==', customerId)
    .where('status', '==', 'active')
    .get();
  return snapshot.docs.map((doc) => doc.id);
}

/**
 * Fields every `comments` subdocument must carry alongside its own
 * authorship/body/visibility, denormalized straight from the parent session
 * at write time. Firestore Security Rules evaluate `resource.data` against
 * the exact document being read — a comment, not its parent session — so
 * `canReadBuyerCollaborationComment` (see `firestore.rules`) needs these
 * fields present on the comment itself to decide visibility without a
 * `get()` round trip per read.
 */
export function commentVisibilityFields(
  session: DocumentData,
): Pick<DocumentData, 'organizationId' | 'companyId' | 'sellerId' | 'customerId'> {
  return {
    organizationId: session.organizationId,
    companyId: session.companyId,
    sellerId: session.sellerId,
    customerId: session.customerId,
  };
}

export function sellerDeepLink(organizationId: string, sessionId: string): string {
  return `/org/${organizationId}/buyer-collaboration/${sessionId}`;
}

export function buyerDeepLink(organizationId: string, sessionId: string): string {
  return `/customer-portal/${organizationId}/collaboration/${sessionId}`;
}

export function notificationPayload(input: {
  organizationId: string;
  userId: string;
  title: string;
  body: string;
  deepLink: string;
  entityId: string;
  createdAt: Timestamp;
}): DocumentData {
  return {
    organizationId: input.organizationId,
    userId: input.userId,
    category: 'commercial',
    priority: 'informative',
    title: input.title,
    body: input.body,
    deepLink: input.deepLink,
    entityId: input.entityId,
    createdAt: input.createdAt,
    readAt: null,
    deliverAt: null,
  };
}
