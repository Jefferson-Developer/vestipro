import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentReference,
  type Transaction,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  calculatePricingEngine,
  type PricingEngineItemInput,
  type PricingEngineOutput,
} from '../pricing/pricing-engine';
import {
  ensureActivePriceList,
  ensureCompanyScope,
  ensureValidPaymentTerm,
  mapCampaign,
  mapDiscountPolicy,
  mapPaymentTerm,
  mapPriceList,
  mapPriceListItem,
  normalizeCurrency,
  optionalString,
} from '../pricing/calculate-pricing';
import { asInt, requirePositiveInteger } from '../inventory/stock-reservation-shared';

/**
 * Only these roles may ever submit an order (TASK-101) — mirrors exactly
 * `Capability.orderCreate`'s grant list in
 * `lib/core/permissions/role_permission_matrix.dart` (OWNER/ADMIN/
 * SALES_MANAGER/SALES_REP; SALES_ASSISTANT/FINANCE/READ_ONLY never get it).
 * Re-checked here from the caller's real Membership — never trusted from the
 * client, same "não confiar apenas em organizationId... como autorização"
 * rule every other Function in this codebase already follows.
 */
const ROLES_ALLOWED_TO_SUBMIT_ORDER: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

const ACTIVE_CUSTOMER_STATUS = 'active';

export interface SubmitOrderAddressInput {
  street?: string;
  number?: string;
  complement?: string;
  district?: string;
  city?: string;
  state?: string;
  zipCode?: string;
  country?: string;
}

export interface SubmitOrderItemInput {
  id?: string;
  productId?: string;
  variantId?: string;
  quantity?: number;
  collectionId?: string;
  categoryId?: string;
  /**
   * Set only when the client already holds an active commercial reservation
   * for this line (TASK-092, `createStockReservation`) — when present, this
   * line's stock is consumed from that exact reservation instead of a direct
   * decrement (`tasks.md`/TASK-101's "consumir a reserva... quando a flag
   * estiver ativa"). No order-flow entry point creates one yet (TASK-092's
   * own reservation UI is not wired into the draft screen as of this task),
   * so in practice every submission today takes the direct-decrement branch
   * — this field exists so a future reservation-aware entry point can opt
   * in without another Cloud Function change.
   */
  reservationId?: string;
}

export interface SubmitOrderRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  /**
   * The draft's own client-generated id (`Order.id`, a uuid minted once when
   * `OrderDraftCustomerSelected` first creates the local draft, TASK-096) —
   * doubles as this call's idempotency key *and* the resulting Firestore
   * document id: a resubmission (double tap, retry after a dropped
   * response) always carries the very same [orderId], so it can never create
   * a second order for one seller intent, mirroring
   * `createStockReservation`'s own `reservationId`-as-doc-id pattern.
   */
  orderId?: string;
  branchId?: string;
  customerId?: string;
  sellerId?: string;
  deliveryAddress?: SubmitOrderAddressInput;
  billingAddress?: SubmitOrderAddressInput;
  priceListId?: string;
  paymentTermId?: string;
  carrierId?: string;
  collectionId?: string;
  orderType?: string;
  items?: SubmitOrderItemInput[];
  notes?: string;
  attachmentUrls?: string[];
  shippingAmount?: number;
  clientOrderTotal?: number;
}

export interface SubmitOrderResponseItem {
  id: string;
  productId: string;
  variantId?: string;
  quantity: number;
  unitPrice: number;
  discountAmount: number;
  subtotal: number;
}

export interface SubmitOrderResponse {
  correlationId: string;
  orderId: string;
  orderNumber: string;
  status: string;
  discountAmount: number;
  surchargeAmount: number;
  shippingAmount: number;
  total: number;
  submittedAt: string;
  items: SubmitOrderResponseItem[];
}

interface NormalizedAddress {
  street: string;
  // `null`, never `undefined`: the Admin SDK rejects `undefined` inside a
  // nested map field written via `transaction.set` unless
  // `ignoreUndefinedProperties` is enabled (it is not, same default every
  // other Function in this codebase relies on).
  number: string | null;
  complement: string | null;
  district: string | null;
  city: string;
  state: string;
  zipCode: string;
  country: string;
}

interface NormalizedItem {
  id: string;
  productId: string;
  variantId: string;
  quantity: number;
  collectionId?: string;
  categoryId?: string;
  reservationId?: string;
}

/**
 * Idempotent Cloud Function submitting an `Order` draft (EPIC-13, TASK-101):
 * revalidates every TASK-100 condition (cliente ativo, tabela de preço
 * vigente, condição de pagamento válida, desconto dentro da política,
 * disponibilidade) against Firestore's own current state — never trusting
 * the client's local snapshot — before generating a unique, sequential
 * `orderNumber` and persisting the order as `submitted`, with its first
 * `OrderStatusHistoryEntry`.
 *
 * A single `runTransaction` call stages every read and write (order
 * existence check, customer/Price List/Payment Term/inventory lookups,
 * order-number counter, the order document itself, its stock movement and
 * the audit log entry): either everything commits together or nothing does,
 * so a failure mid-submission never leaves the order half-created
 * (`tasks.md`'s own "status final deve ser sempre determinístico" rule) —
 * same technique `createOrganization`/`createStockReservation` already use.
 * A retried call with the exact same [SubmitOrderRequest.orderId] short-
 * circuits to the already-persisted result instead of writing again,
 * including under real concurrency (two simultaneous calls for the same
 * `orderId`: Firestore's transaction contention automatically retries the
 * loser, which then observes the winner's committed document and returns
 * it) — this is what makes a double tap/network retry safe.
 */
export const submitOrder = onCall<SubmitOrderRequest, Promise<SubmitOrderResponse>>(
  async (request) => {
    const startedAt = Date.now();
    const correlationId = resolveCorrelationId(request.data?._meta);

    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'É necessário estar autenticado para enviar um pedido.',
      );
    }
    const uid = request.auth.uid;

    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
    const branchId = requireNonEmptyString(request.data?.branchId, 'branchId');
    const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
    const sellerId = requireNonEmptyString(request.data?.sellerId, 'sellerId');
    const priceListId = requireNonEmptyString(request.data?.priceListId, 'priceListId');
    const paymentTermId = requireNonEmptyString(request.data?.paymentTermId, 'paymentTermId');
    const carrierId = optionalString(request.data?.carrierId);
    const collectionId = optionalString(request.data?.collectionId);
    const orderType = optionalString(request.data?.orderType);
    const notes = optionalString(request.data?.notes);
    const attachmentUrls = normalizeAttachmentUrls(request.data?.attachmentUrls);
    const shippingAmount = normalizeCurrency(request.data?.shippingAmount ?? 0, 'shippingAmount');
    const deliveryAddress = requireAddress(request.data?.deliveryAddress, 'deliveryAddress');
    const billingAddress = requireAddress(request.data?.billingAddress, 'billingAddress');
    const items = requireItems(request.data?.items);

    if (sellerId !== uid) {
      throw new HttpsError(
        'permission-denied',
        'O pedido só pode ser enviado pelo próprio vendedor responsável.',
      );
    }

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    if (!ROLES_ALLOWED_TO_SUBMIT_ORDER.has(membership.roleName)) {
      throw new HttpsError(
        'permission-denied',
        'Seu perfil não pode enviar pedidos.',
      );
    }

    const actorName = await resolveActorName(db, uid, request.auth.token);
    const organizationRef = db.collection('organizations').doc(organizationId);
    const orderRef = organizationRef.collection('orders').doc(orderId);

    const result = await db.runTransaction<SubmitOrderResponse>(async (transaction) => {
      const existingOrderSnapshot = await transaction.get(orderRef);
      if (existingOrderSnapshot.exists) {
        const existing = existingOrderSnapshot.data();
        if (!existing) {
          throw new HttpsError('internal', 'Invalid order record.');
        }
        // Double submit (retry, double tap, lost response) of the exact same
        // draft — never a new order, always the one already persisted.
        return serializeOrder(orderId, existing, correlationId);
      }

      const customerSnapshot = await transaction.get(
        organizationRef.collection('customers').doc(customerId),
      );
      const customerData = customerSnapshot.data();
      if (!customerSnapshot.exists || !customerData) {
        throw new HttpsError('failed-precondition', 'Customer not found.');
      }
      if (customerData.companyId !== companyId) {
        throw new HttpsError(
          'failed-precondition',
          'Customer does not belong to the requested company.',
        );
      }
      if (customerData.status !== ACTIVE_CUSTOMER_STATUS) {
        throw new HttpsError(
          'failed-precondition',
          'Este cliente não está ativo. Regularize a situação para enviar o pedido.',
        );
      }
      const customerSegment =
        typeof customerData.segment === 'string' ? customerData.segment.trim() : '';

      const priceListSnapshot = await transaction.get(
        organizationRef.collection('priceLists').doc(priceListId),
      );
      if (!priceListSnapshot.exists) {
        throw new HttpsError('failed-precondition', 'Price list not found.');
      }
      const selectedPriceList = mapPriceList(priceListId, priceListSnapshot.data());
      ensureCompanyScope(companyId, 'Price list', selectedPriceList);
      ensureActivePriceList(selectedPriceList);
      ensurePriceListCurrentlyValid(selectedPriceList);

      const paymentTermSnapshot = await transaction.get(
        organizationRef.collection('paymentTerms').doc(paymentTermId),
      );
      if (!paymentTermSnapshot.exists) {
        throw new HttpsError('failed-precondition', 'Payment term not found.');
      }
      const paymentTerm = mapPaymentTerm(paymentTermId, paymentTermSnapshot.data());
      ensureCompanyScope(companyId, 'Payment term', paymentTerm);
      ensureValidPaymentTerm(paymentTerm, priceListId);

      const priceItemSnapshots = await transaction.get(
        organizationRef.collection('priceLists').doc(priceListId).collection('items'),
      );
      const priceListItems = priceItemSnapshots.docs.map((doc) => mapPriceListItem(doc.data()));
      priceListItems.forEach((item) => ensureCompanyScope(companyId, 'Price list item', item));

      const policiesSnapshot = await transaction.get(
        organizationRef.collection('discountPolicies'),
      );
      const discountPolicy = policiesSnapshot.docs
        .map((doc) => mapDiscountPolicy(doc.id, doc.data()))
        .find(
          (policy) =>
            (policy.companyId === undefined || policy.companyId === companyId) &&
            policy.role === membership.roleName &&
            policy.status === 'active' &&
            (policy.priceListIds === undefined ||
              policy.priceListIds.length === 0 ||
              policy.priceListIds.includes(priceListId)),
        );

      const campaignSnapshots = await transaction.get(
        organizationRef.collection('promotionalCampaigns'),
      );
      const campaigns = campaignSnapshots.docs.map((doc) => mapCampaign(doc.id, doc.data()));
      campaigns.forEach((campaign) => ensureCompanyScope(companyId, 'Campaign', campaign));

      const pricingItems: PricingEngineItemInput[] = items.map((item) => ({
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
        collectionId: item.collectionId,
        categoryId: item.categoryId,
        manualDiscountPercent: 0,
      }));
      const pricing: PricingEngineOutput = calculatePricingEngine({
        selectedPriceList,
        priceListItems,
        paymentTerm,
        discountPolicy,
        campaigns,
        customerSegment,
        items: pricingItems,
        shippingAmount,
      });
      if (pricing.blocked) {
        throw new HttpsError(
          'failed-precondition',
          'Um desconto aplicado está fora do limite permitido para o seu perfil.',
        );
      }

      // ---- availability (reads only — writes staged further below) ------
      const availability = await resolveItemAvailability(transaction, organizationRef, items);

      // ---- order number (transactional per-company sequence) ------------
      const sequenceRef = organizationRef.collection('orderNumberSequences').doc(companyId);
      const sequenceSnapshot = await transaction.get(sequenceRef);
      const nextSequence = asInt(sequenceSnapshot.data()?.lastValue) + 1;
      const orderNumber = formatOrderNumber(nextSequence);

      // ---- writes ---------------------------------------------------------
      const now = Timestamp.now();
      transaction.set(
        sequenceRef,
        { organizationId, companyId, lastValue: nextSequence, updatedAt: now, updatedBy: uid },
        { merge: true },
      );

      const responseItems = pricing.items.map((item, index) =>
        buildResponseItem(items[index]!, item),
      );

      const orderData: DocumentData = {
        organizationId,
        companyId,
        branchId,
        customerId,
        sellerId,
        orderNumber,
        deliveryAddress,
        billingAddress,
        priceListId,
        paymentTermId,
        carrierId: carrierId ?? null,
        collectionId: collectionId ?? null,
        orderType: orderType ?? null,
        items: responseItems.map((item) => ({
          id: item.id,
          variantId: item.variantId ?? null,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discountAmount: item.discountAmount,
          surchargeAmount: 0,
          subtotal: item.subtotal,
        })),
        discountAmount: roundCurrency(pricing.campaignDiscountTotal + pricing.manualDiscountTotal),
        surchargeAmount: roundCurrency(pricing.paymentTermAdjustmentTotal),
        shippingAmount: roundCurrency(pricing.shippingAmount),
        taxAmount: null,
        notes: notes ?? null,
        attachmentUrls,
        status: 'submitted',
        statusHistory: [
          {
            previousStatus: null,
            newStatus: 'submitted',
            changedAt: now,
            actorId: uid,
            reason: null,
          },
        ],
        approvedBy: null,
        approvedAt: null,
        rejectionReason: null,
        pricingApprovalRequired: pricing.approvalRequired,
        idempotencyKey: orderId,
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
        deletedAt: null,
        version: 1,
        syncStatus: 'synced',
      };
      transaction.set(orderRef, orderData);

      applyStockMovements(transaction, items, availability, {
        uid,
        orderId,
        now,
      });

      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'order.submitted',
        entityType: 'order',
        entityId: orderId,
        previousValue: null,
        newValue: { orderNumber, customerId, total: pricing.total },
        timestamp: now,
      });

      return serializeOrder(orderId, orderData, correlationId);
    }, {
      // Higher than the SDK's default (5): this transaction touches 3
      // contended documents at once (the order itself, its per-company
      // order-number sequence and every affected inventory balance), so two
      // genuinely concurrent submissions of the very same draft (the exact
      // scenario this task's idempotency contract must hold under) can
      // plausibly need more than 5 retries to settle before the loser
      // observes the winner's already-committed order.
      maxAttempts: 10,
    });

    logger.info('submitOrder succeeded', {
      correlationId,
      organizationId,
      companyId,
      orderId,
      orderNumber: result.orderNumber,
      uid,
      itemCount: result.items.length,
      total: result.total,
      durationMs: Date.now() - startedAt,
    });

    return result;
  },
);

function normalizeAttachmentUrls(value: unknown): string[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== 'string')) {
    throw new HttpsError('invalid-argument', 'attachmentUrls must be an array of strings.');
  }
  return value as string[];
}

function requireAddress(
  value: SubmitOrderAddressInput | undefined,
  field: string,
): NormalizedAddress {
  if (typeof value !== 'object' || value === null) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return {
    street: requireNonEmptyString(value.street, `${field}.street`),
    number: optionalString(value.number) ?? null,
    complement: optionalString(value.complement) ?? null,
    district: optionalString(value.district) ?? null,
    city: requireNonEmptyString(value.city, `${field}.city`),
    state: requireNonEmptyString(value.state, `${field}.state`),
    zipCode: requireNonEmptyString(value.zipCode, `${field}.zipCode`),
    country: optionalString(value.country) ?? 'BR',
  };
}

function requireItems(value: SubmitOrderItemInput[] | undefined): NormalizedItem[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('invalid-argument', 'items is required.');
  }
  return value.map((item, index) => {
    if (typeof item !== 'object' || item === null) {
      throw new HttpsError('invalid-argument', `items[${index}] is invalid.`);
    }
    return {
      id: requireNonEmptyString(item.id, `items[${index}].id`),
      productId: requireNonEmptyString(item.productId, `items[${index}].productId`),
      variantId: requireNonEmptyString(item.variantId, `items[${index}].variantId`),
      quantity: requirePositiveInteger(item.quantity, `items[${index}].quantity`),
      collectionId: optionalString(item.collectionId),
      categoryId: optionalString(item.categoryId),
      reservationId: optionalString(item.reservationId),
    };
  });
}

/** Mirrors `PriceList.isApplicableAt` (`lib/features/pricing/domain/entities/price_list.dart`)
 * — `ensureActivePriceList` (reused from `calculatePricing`, TASK-088) only
 * checks `status`, never the date range, so TASK-101's own "tabela de preço
 * vigente" revalidation adds this check on top instead of silently relying
 * on an incomplete guard. */
function ensurePriceListCurrentlyValid(priceList: { validFrom: string; validTo?: string | null }): void {
  const now = Date.now();
  if (new Date(priceList.validFrom).getTime() > now) {
    throw new HttpsError('failed-precondition', 'Price list is not yet valid.');
  }
  if (priceList.validTo && new Date(priceList.validTo).getTime() < now) {
    throw new HttpsError(
      'failed-precondition',
      'A tabela de preço deste pedido venceu.',
    );
  }
}

interface ItemAvailabilityPlan {
  /** `undefined` when this item's stock is simply not tracked yet (no
   * balance/reservation found) — never blocking, mirrors TASK-100's own
   * "missing means unresolved, not non-existent" rule for this same lookup,
   * now enforced with real Firestore data instead of a best-effort client
   * cache. */
  balanceRef?: DocumentReference;
  reservationRef?: DocumentReference;
  /** Only set alongside [reservationRef] — the exact balance the reservation
   * itself already points to (`StockReservation.variantId`/`.warehouseId`),
   * consumed the same way `consumeStockReservation` (TASK-092) already does:
   * `physicalQuantity` and `reservedQuantity` decremented together. */
  reservationBalanceRef?: DocumentReference;
  reservationQuantity?: number;
}

/**
 * Reads (never writes — Firestore transactions require every read staged
 * before any write) every item's stock situation: a reservation doc when
 * [NormalizedItem.reservationId] is set, otherwise every
 * `organizations/{organizationId}/inventory` balance for that variant. Rejects
 * with `failed-precondition` the moment one item cannot be fulfilled from a
 * single warehouse/reservation (splitting one line across multiple
 * warehouses is out of this task's scope) — the caller only proceeds to
 * write once every line has a confirmed plan.
 */
async function resolveItemAvailability(
  transaction: Transaction,
  organizationRef: DocumentReference,
  items: NormalizedItem[],
): Promise<Map<string, ItemAvailabilityPlan>> {
  const plans = new Map<string, ItemAvailabilityPlan>();

  for (const item of items) {
    if (item.reservationId) {
      const reservationRef = organizationRef
        .collection('stockReservations')
        .doc(item.reservationId);
      const reservationSnapshot = await transaction.get(reservationRef);
      const reservation = reservationSnapshot.data();
      if (!reservationSnapshot.exists || !reservation) {
        throw new HttpsError(
          'failed-precondition',
          'A reserva de estoque informada não foi encontrada.',
        );
      }
      if (
        reservation.status !== 'active' ||
        reservation.variantId !== item.variantId ||
        asInt(reservation.quantity) !== item.quantity
      ) {
        throw new HttpsError(
          'failed-precondition',
          'A reserva de estoque não corresponde mais a este item do pedido.',
        );
      }
      const reservationWarehouseId = requireNonEmptyString(
        reservation.warehouseId,
        'reservation.warehouseId',
      );
      plans.set(item.id, {
        reservationRef,
        reservationBalanceRef: organizationRef
          .collection('inventory')
          .doc(`${item.variantId}_${reservationWarehouseId}`),
        reservationQuantity: asInt(reservation.quantity),
      });
      continue;
    }

    const balanceSnapshots = await transaction.get(
      organizationRef.collection('inventory').where('variantId', '==', item.variantId),
    );
    if (balanceSnapshots.empty) {
      // Stock not tracked for this variant yet — never blocks submission
      // (TASK-100's own precedent), just skips the movement below.
      plans.set(item.id, {});
      continue;
    }

    const fulfillable = balanceSnapshots.docs
      .map((doc) => ({ ref: doc.ref, data: doc.data() }))
      .filter((balance) => sellableQuantity(balance.data) >= item.quantity)
      .sort((left, right) => left.ref.id.localeCompare(right.ref.id))[0];
    if (!fulfillable) {
      throw new HttpsError(
        'failed-precondition',
        'A quantidade solicitada não está disponível em estoque para um dos itens.',
      );
    }
    plans.set(item.id, { balanceRef: fulfillable.ref });
  }

  return plans;
}

function sellableQuantity(data: DocumentData | undefined): number {
  return asInt(data?.physicalQuantity) - asInt(data?.reservedQuantity) - asInt(data?.blockedQuantity);
}

function applyStockMovements(
  transaction: Transaction,
  items: NormalizedItem[],
  availability: Map<string, ItemAvailabilityPlan>,
  context: { uid: string; orderId: string; now: Timestamp },
): void {
  for (const item of items) {
    const plan = availability.get(item.id);
    if (!plan) continue;

    if (plan.reservationRef && plan.reservationBalanceRef) {
      transaction.update(plan.reservationRef, {
        status: 'consumed',
        consumedAt: context.now,
        consumedBy: context.uid,
        updatedAt: context.now,
        updatedBy: context.uid,
        version: FieldValue.increment(1),
      });
      transaction.set(
        plan.reservationBalanceRef,
        {
          physicalQuantity: FieldValue.increment(-(plan.reservationQuantity ?? 0)),
          reservedQuantity: FieldValue.increment(-(plan.reservationQuantity ?? 0)),
          updatedAt: context.now,
          updatedBy: context.uid,
          lastSource: 'order_submission_reservation_consumption',
          version: FieldValue.increment(1),
        },
        { merge: true },
      );
      continue;
    }

    if (plan.balanceRef) {
      transaction.set(
        plan.balanceRef,
        {
          physicalQuantity: FieldValue.increment(-item.quantity),
          updatedAt: context.now,
          updatedBy: context.uid,
          lastSource: 'order_submission',
          version: FieldValue.increment(1),
        },
        { merge: true },
      );
    }
  }
}

function buildResponseItem(
  item: NormalizedItem,
  pricingItem: PricingEngineOutput['items'][number],
): SubmitOrderResponseItem {
  return {
    id: item.id,
    productId: pricingItem.productId,
    variantId: pricingItem.variantId,
    quantity: pricingItem.quantity,
    unitPrice: pricingItem.finalUnitPrice,
    discountAmount: roundCurrency(pricingItem.lineSubtotal - pricingItem.lineTotal),
    subtotal: pricingItem.lineTotal,
  };
}

function formatOrderNumber(sequence: number): string {
  return sequence.toString().padStart(6, '0');
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function serializeOrder(
  orderId: string,
  data: DocumentData,
  correlationId: string,
): SubmitOrderResponse {
  const createdAt = data.createdAt as Timestamp;
  const rawItems = Array.isArray(data.items) ? (data.items as DocumentData[]) : [];
  return {
    correlationId,
    orderId,
    orderNumber: data.orderNumber as string,
    status: data.status as string,
    discountAmount: asNumber(data.discountAmount),
    surchargeAmount: asNumber(data.surchargeAmount),
    shippingAmount: asNumber(data.shippingAmount),
    total: roundCurrency(
      rawItems.reduce((sum, item) => sum + asNumber(item.subtotal), 0) +
        asNumber(data.surchargeAmount) +
        asNumber(data.shippingAmount),
    ),
    submittedAt: createdAt.toDate().toISOString(),
    items: rawItems.map((item) => ({
      id: item.id as string,
      productId: item.productId as string,
      variantId: (item.variantId as string | null) ?? undefined,
      quantity: asInt(item.quantity),
      unitPrice: asNumber(item.unitPrice),
      discountAmount: asNumber(item.discountAmount),
      subtotal: asNumber(item.subtotal),
    })),
  };
}

function asNumber(value: unknown): number {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}
