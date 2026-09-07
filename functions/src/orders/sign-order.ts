import { createHash } from 'node:crypto';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';

/**
 * Only these roles may ever sign a pedido (TASK-180) — the exact same set
 * `submitOrder`'s own `ROLES_ALLOWED_TO_SUBMIT_ORDER` allows to submit one:
 * signing is the closing step of the very same commercial flow, not a
 * separate permission. Re-checked here from the caller's real Membership,
 * never trusted from the client.
 */
const ROLES_ALLOWED_TO_SIGN_ORDER: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

/** Mirrors `kSignableOrderStatuses`
 * (`lib/features/orders/domain/usecases/capture_order_signature_use_case.dart`)
 * — kept in sync manually, same already-accepted risk every other
 * Dart<->TypeScript mirrored rule in this codebase already documents. */
const SIGNABLE_STATUSES: ReadonlySet<string> = new Set<string>([
  'submitted',
  'under_review',
  'approved',
  'processing',
  'invoiced',
  'partially_invoiced',
  'shipped',
  'delivered',
]);

const SIGNER_ROLES: ReadonlySet<string> = new Set<string>(['customer', 'seller']);
const SIGNATURE_METHODS: ReadonlySet<string> = new Set<string>([
  'canvas_drawn',
  'external_provider',
]);

/** Mirrors `CaptureOrderSignatureUseCase`'s own implicit "a drawn stroke
 * produces a small PNG" expectation — generous enough for a high-DPI
 * capture (`OrderSignaturePad.exportPng`'s own `pixelRatio: 3`) while still
 * rejecting an obviously wrong/oversized payload outright. */
const MAX_IMAGE_BYTES = 2 * 1024 * 1024;

const PNG_MAGIC_BYTES = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

export interface SignOrderRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  signatureId?: string;
  signerRole?: string;
  signedByName?: string;
  method?: string;
  imageBase64?: string;
  contentHash?: string;
  orderVersionAtSignature?: number;
  signedAt?: string;
}

export interface SignOrderResponse {
  correlationId: string;
  signatureId: string;
  remoteImageStoragePath: string;
  serverReceivedAt: string;
  deviceInfo: string | null;
  ipAddress: string | null;
}

/**
 * Idempotent Cloud Function persisting the immutable electronic signature
 * closing a pedido (EPIC-13, TASK-180) — the one and only place
 * [OrderSignature.contentHash] is re-verified against the order's own
 * *current, server-side* content (never the client's own echoed value) and
 * the signature image/document are ever written: neither Firestore Rules
 * (`orders/{orderId}/signatures/{signatureId}` — `allow create, update,
 * delete: if false`) nor Storage Rules
 * (`organizations/{organizationId}/orders/{orderId}/signatures/{fileName}` —
 * `allow write: if false`) let a client write either directly.
 *
 * Authenticity/consentimento validated here, never only on the client
 * (`AGENTS.md`'s own "assinatura eletrônica de pedido é uma regra crítica"
 * rule):
 * - the caller must be the pedido's own `sellerId` (mirrors `submitOrder`'s
 *   own "só pode ser enviado pelo próprio vendedor responsável" rule) and
 *   hold one of [ROLES_ALLOWED_TO_SIGN_ORDER];
 * - the pedido must already be in one of [SIGNABLE_STATUSES] — never a
 *   `draft`/`pending_sync`/`cancelled`/`rejected` one;
 * - a pedido that already carries a *valid* signature is rejected outright
 *   ("assinatura nunca pode ser removida ou substituída" — this task adds
 *   no "invalidate"/"re-sign" endpoint, see the CONCLUIDA doc's own
 *   "Decisões técnicas");
 * - [SignOrderRequest.contentHash] (computed client-side,
 *   `OrderContentHasher`) must match `buildOrderContentHash` recomputed
 *   here from the order document's own current, authoritative Firestore
 *   state — a stale local copy (the order changed after the client last
 *   synced it) is rejected instead of silently signing the wrong content;
 * - `deviceInfo`/`ipAddress` are stamped here, from this callable's own
 *   trusted context (`_meta`/the request's own IP), never accepted as
 *   fields the client could set directly.
 *
 * [SignOrderRequest.signatureId] is reused verbatim as this write's own
 * idempotency key/Firestore document id — a retried call (double tap,
 * dropped response, the offline-capture-then-later-sync flow itself)
 * resolves to the exact same persisted signature instead of ever writing a
 * second one, mirroring `submitOrder`'s own `orderId`-as-doc-id precedent.
 */
export const signOrder = onCall<SignOrderRequest, Promise<SignOrderResponse>>(
  async (request) => {
    const startedAt = Date.now();
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'É necessário estar autenticado para assinar um pedido.',
      );
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
    const signatureId = requireNonEmptyString(request.data?.signatureId, 'signatureId');
    const signerRole = requireEnum(request.data?.signerRole, SIGNER_ROLES, 'signerRole');
    const signedByName = requireNonEmptyString(request.data?.signedByName, 'signedByName');
    const method = requireEnum(request.data?.method, SIGNATURE_METHODS, 'method');
    const imageBase64 = requireNonEmptyString(request.data?.imageBase64, 'imageBase64');
    const contentHash = requireNonEmptyString(request.data?.contentHash, 'contentHash');
    const orderVersionAtSignature = requireInt(
      request.data?.orderVersionAtSignature,
      'orderVersionAtSignature',
    );
    const signedAt = requireIsoDate(request.data?.signedAt, 'signedAt');

    const imageBuffer = decodeSignatureImage(imageBase64);

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    if (!ROLES_ALLOWED_TO_SIGN_ORDER.has(membership.roleName)) {
      throw new HttpsError('permission-denied', 'Seu perfil não pode assinar pedidos.');
    }

    const actorName = await resolveActorName(db, uid, request.auth.token);
    const organizationRef = db.collection('organizations').doc(organizationId);
    const orderRef = organizationRef.collection('orders').doc(orderId);
    const signaturesRef = orderRef.collection('signatures');
    const signatureRef = signaturesRef.doc(signatureId);

    // Resolved server-side, from this callable's own trusted context — never
    // accepted as request fields (see this Function's own docs above).
    const deviceInfo = resolveDeviceInfo(request.data?._meta);
    const ipAddress = request.rawRequest?.ip ?? null;

    const result = await db.runTransaction<SignOrderResponse>(async (transaction) => {
      const existingSignatureSnapshot = await transaction.get(signatureRef);
      if (existingSignatureSnapshot.exists) {
        const existing = existingSignatureSnapshot.data();
        if (!existing) {
          throw new HttpsError('internal', 'Invalid order signature record.');
        }
        // Retry/double-tap of the very same capture — never re-writes,
        // same idempotency precedent `submitOrder` already sets.
        return serializeSignature(signatureId, existing, correlationId);
      }

      const orderSnapshot = await transaction.get(orderRef);
      const order = orderSnapshot.data();
      if (!orderSnapshot.exists || !order) {
        throw new HttpsError('failed-precondition', 'Pedido não encontrado.');
      }
      if (order.organizationId !== organizationId || order.companyId !== companyId) {
        throw new HttpsError(
          'failed-precondition',
          'Pedido não pertence à organização/empresa informada.',
        );
      }
      if (order.sellerId !== uid) {
        throw new HttpsError(
          'permission-denied',
          'O pedido só pode ser assinado pelo próprio vendedor responsável.',
        );
      }
      if (!SIGNABLE_STATUSES.has(order.status as string)) {
        throw new HttpsError(
          'failed-precondition',
          'Este pedido não pode ser assinado no status atual.',
        );
      }

      const existingValidSignatureSnapshot = await transaction.get(
        signaturesRef.where('status', '==', 'valid').limit(1),
      );
      if (!existingValidSignatureSnapshot.empty) {
        throw new HttpsError(
          'failed-precondition',
          'Este pedido já foi assinado. Duplique o pedido para uma nova versão.',
        );
      }

      const serverContentHash = buildOrderContentHash(order);
      if (serverContentHash !== contentHash) {
        throw new HttpsError(
          'failed-precondition',
          'O conteúdo do pedido mudou desde a última sincronização — ' +
            'atualize o pedido antes de assiná-lo.',
        );
      }

      const now = Timestamp.now();
      const signatureData: DocumentData = {
        organizationId,
        companyId,
        orderId,
        orderNumber: (order.orderNumber as string | null) ?? null,
        signerRole,
        signedByUserId: uid,
        signedByName,
        method,
        remoteImageStoragePath: buildImageStoragePath(organizationId, orderId, signatureId),
        contentHash,
        orderVersionAtSignature,
        signedAt: Timestamp.fromDate(new Date(signedAt)),
        deviceInfo,
        ipAddress,
        serverReceivedAt: now,
        status: 'valid',
        invalidatedAt: null,
        invalidatedReason: null,
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
        version: 1,
      };
      transaction.set(signatureRef, signatureData);

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'order.signed',
        entityType: 'order',
        entityId: orderId,
        previousValue: null,
        newValue: { signatureId, signerRole },
        timestamp: now,
      });

      return serializeSignature(signatureId, signatureData, correlationId);
    });

    // The image upload happens *after* the transaction commits successfully
    // — Storage writes cannot participate in a Firestore transaction, same
    // limitation every other media-upload Function in this codebase already
    // lives with (`exportReportToPdf`, avatar/product-image uploads). A
    // retried call for an already-persisted `signatureId` (the branch above)
    // never reaches here a second time, so this never re-uploads either.
    await getStorage()
      .bucket()
      .file(buildImageStoragePath(organizationId, orderId, signatureId))
      .save(imageBuffer, {
        contentType: 'image/png',
        metadata: { cacheControl: 'private, max-age=0' },
      });

    logger.info('signOrder succeeded', {
      correlationId,
      organizationId,
      companyId,
      orderId,
      signatureId,
      uid,
      durationMs: Date.now() - startedAt,
    });

    return result;
  },
);

function requireEnum<T extends string>(
  value: unknown,
  allowed: ReadonlySet<T>,
  field: string,
): T {
  if (typeof value !== 'string' || !allowed.has(value as T)) {
    throw new HttpsError('invalid-argument', `${field} is invalid.`);
  }
  return value as T;
}

function requireInt(value: unknown, field: string): number {
  if (typeof value !== 'number' || !Number.isFinite(value) || !Number.isInteger(value)) {
    throw new HttpsError('invalid-argument', `${field} must be an integer.`);
  }
  return value;
}

function requireIsoDate(value: unknown, field: string): string {
  const raw = requireNonEmptyString(value, field);
  if (Number.isNaN(new Date(raw).getTime())) {
    throw new HttpsError('invalid-argument', `${field} must be a valid ISO 8601 date.`);
  }
  return raw;
}

function decodeSignatureImage(imageBase64: string): Buffer {
  let buffer: Buffer;
  try {
    buffer = Buffer.from(imageBase64, 'base64');
  } catch {
    throw new HttpsError('invalid-argument', 'imageBase64 is not valid base64.');
  }
  if (buffer.length === 0 || buffer.length > MAX_IMAGE_BYTES) {
    throw new HttpsError(
      'invalid-argument',
      `imageBase64 must decode to a non-empty PNG up to ${MAX_IMAGE_BYTES} bytes.`,
    );
  }
  if (!buffer.subarray(0, PNG_MAGIC_BYTES.length).equals(PNG_MAGIC_BYTES)) {
    throw new HttpsError('invalid-argument', 'imageBase64 must decode to a PNG image.');
  }
  return buffer;
}

function buildImageStoragePath(organizationId: string, orderId: string, signatureId: string): string {
  return `organizations/${organizationId}/orders/${orderId}/signatures/${signatureId}.png`;
}

function resolveDeviceInfo(meta: SignOrderRequest['_meta']): string | null {
  if (!meta) return null;
  const parts = [meta.platform, meta.appVersion].filter(
    (part): part is string => typeof part === 'string' && part.trim().length > 0,
  );
  return parts.length === 0 ? null : parts.join(' ');
}

/**
 * Recomputes the exact same SHA-256 `OrderContentHasher`
 * (`lib/features/orders/domain/services/order_content_hasher.dart`) already
 * computes client-side, from this order document's own current, persisted
 * Firestore state — kept in sync with that Dart implementation manually
 * (see this file's own top-level docs). Every monetary value is hashed as a
 * fixed-2-decimal *string* (never a raw JSON number) for the exact same
 * reason `OrderContentHasher._money` documents: `JSON.stringify` and Dart's
 * `jsonEncode` render a whole double differently, which would otherwise make
 * the client- and server-computed hashes of the exact same order content
 * disagree purely because of which language serialized a whole number.
 */
function buildOrderContentHash(order: DocumentData): string {
  const items = Array.isArray(order.items) ? (order.items as DocumentData[]) : [];
  const payload = {
    id: order.id ?? null,
    organizationId: order.organizationId ?? null,
    companyId: order.companyId ?? null,
    branchId: order.branchId ?? null,
    customerId: order.customerId ?? null,
    sellerId: order.sellerId ?? null,
    orderNumber: (order.orderNumber as string | null) ?? null,
    deliveryAddress: addressPayload(order.deliveryAddress as DocumentData | undefined),
    billingAddress: addressPayload(order.billingAddress as DocumentData | undefined),
    priceListId: order.priceListId ?? null,
    currency: order.currency ?? null,
    paymentTermId: order.paymentTermId ?? null,
    carrierId: (order.carrierId as string | null) ?? null,
    items: items.map(itemPayload),
    discountAmount: money(order.discountAmount),
    surchargeAmount: money(order.surchargeAmount),
    shippingAmount: money(order.shippingAmount),
    taxAmount: nullableMoney(order.taxAmount as number | null),
    notes: (order.notes as string | null) ?? null,
  };
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

function addressPayload(address: DocumentData | undefined): DocumentData {
  const value = address ?? {};
  return {
    street: value.street ?? null,
    number: value.number ?? null,
    complement: value.complement ?? null,
    district: value.district ?? null,
    city: value.city ?? null,
    state: value.state ?? null,
    zipCode: value.zipCode ?? null,
    country: value.country ?? null,
  };
}

function itemPayload(item: DocumentData): DocumentData {
  return {
    id: item.id ?? null,
    variantId: (item.variantId as string | null) ?? null,
    productId: item.productId ?? null,
    quantity: item.quantity ?? null,
    unitPrice: money(item.unitPrice),
    discountAmount: money(item.discountAmount),
    surchargeAmount: money(item.surchargeAmount),
    subtotal: money(item.subtotal),
  };
}

function money(value: unknown): string {
  const number = typeof value === 'number' && Number.isFinite(value) ? value : 0;
  return number.toFixed(2);
}

function nullableMoney(value: number | null | undefined): string | null {
  return value === null || value === undefined ? null : money(value);
}

function serializeSignature(
  signatureId: string,
  data: DocumentData,
  correlationId: string,
): SignOrderResponse {
  const serverReceivedAt = data.serverReceivedAt as Timestamp;
  return {
    correlationId,
    signatureId,
    remoteImageStoragePath: data.remoteImageStoragePath as string,
    serverReceivedAt: serverReceivedAt.toDate().toISOString(),
    deviceInfo: (data.deviceInfo as string | null) ?? null,
    ipAddress: (data.ipAddress as string | null) ?? null,
  };
}
