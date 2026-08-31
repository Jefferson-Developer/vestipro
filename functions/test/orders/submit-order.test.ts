import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  submitOrder,
  type SubmitOrderRequest,
  type SubmitOrderResponse,
} from '../../src/orders/submit-order';

const PROJECT_ID = 'demo-vestipro-submit-order-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: SubmitOrderRequest,
  auth?: CallableRequest<SubmitOrderRequest>['auth'],
): CallableRequest<SubmitOrderRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<SubmitOrderRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<SubmitOrderRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<SubmitOrderRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedOrganization(organizationId: string): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(organizationId).set({
    name: 'Grupo Fashion XPTO',
    slug: 'grupo-fashion-xpto',
    settings: { currency: 'BRL', country: 'BR', defaultLanguage: 'pt-BR' },
    status: 'active',
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    deletedAt: null,
  });
}

async function seedMember(
  organizationId: string,
  uid: string,
  roleName: string,
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('members')
    .doc(uid)
    .set({
      organizationId,
      userId: uid,
      roleId: roleName,
      roleName,
      teamIds: [],
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

async function seedCustomer(
  organizationId: string,
  companyId: string,
  customerId: string,
  status = 'active',
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .doc(customerId)
    .set({
      organizationId,
      companyId,
      status,
      segment: 'varejo',
    });
}

async function seedPriceList(
  organizationId: string,
  companyId: string,
  priceListId: string,
  overrides: { validFrom?: Timestamp; validTo?: Timestamp | null; status?: string } = {},
): Promise<void> {
  const priceListRef = db
    .collection('organizations')
    .doc(organizationId)
    .collection('priceLists')
    .doc(priceListId);
  await priceListRef.set({
    organizationId,
    companyId,
    currency: 'BRL',
    status: overrides.status ?? 'active',
    validFrom: overrides.validFrom ?? Timestamp.fromDate(new Date('2020-01-01')),
    validTo: overrides.validTo ?? null,
  });
  await priceListRef.collection('items').doc('item-1').set({
    productId: 'product-1',
    variantId: 'variant-1',
    companyId,
    price: 100,
  });
}

async function seedPaymentTerm(
  organizationId: string,
  companyId: string,
  paymentTermId: string,
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('paymentTerms')
    .doc(paymentTermId)
    .set({
      organizationId,
      companyId,
      name: 'À vista',
      averageTermDays: 0,
      status: 'active',
      priceListIds: [],
    });
}

async function seedDiscountPolicy(
  organizationId: string,
  policyId: string,
  overrides: {
    role?: string;
    maxDiscountPercent?: number;
    requiresApprovalAbovePercent?: number;
    status?: string;
  } = {},
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('discountPolicies')
    .doc(policyId)
    .set({
      role: overrides.role ?? 'SALES_REP',
      maxDiscountPercent: overrides.maxDiscountPercent ?? 15,
      requiresApprovalAbovePercent: overrides.requiresApprovalAbovePercent ?? 10,
      priceListIds: [],
      status: overrides.status ?? 'active',
    });
}

async function seedInventoryBalance(
  organizationId: string,
  companyId: string,
  variantId: string,
  warehouseId: string,
  physicalQuantity: number,
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('inventory')
    .doc(`${variantId}_${warehouseId}`)
    .set({
      organizationId,
      companyId,
      productId: 'product-1',
      variantId,
      warehouseId,
      physicalQuantity,
      reservedQuantity: 0,
      blockedQuantity: 0,
    });
}

function withoutCorrelationId(
  response: SubmitOrderResponse,
): Omit<SubmitOrderResponse, 'correlationId'> {
  const { correlationId, ...rest } = response;
  void correlationId;
  return rest;
}

function baseRequest(overrides: Partial<SubmitOrderRequest> = {}): SubmitOrderRequest {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    deliveryAddress: {
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    },
    billingAddress: {
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    },
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    items: [
      {
        id: 'item-1',
        productId: 'product-1',
        variantId: 'variant-1',
        quantity: 2,
      },
    ],
    shippingAmount: 0,
    ...overrides,
  };
}

async function seedHappyPath(): Promise<void> {
  await seedOrganization('org-1');
  await seedMember('org-1', 'rep-1', 'SALES_REP');
  await seedCustomer('org-1', 'company-1', 'customer-1');
  await seedPriceList('org-1', 'company-1', 'price-list-1');
  await seedPaymentTerm('org-1', 'company-1', 'term-1');
  await seedInventoryBalance('org-1', 'company-1', 'variant-1', 'wh-1', 10);
}

describe('submitOrder', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('submits an order, generates a unique sequential order number and records the first status history entry', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(submitOrder);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('rep-1')),
    )) as SubmitOrderResponse;

    expect(result.orderId).toBe('order-1');
    expect(result.orderNumber).toBe('000001');
    expect(result.status).toBe('submitted');
    expect(result.total).toBe(200);

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.exists).toBe(true);
    const orderData = orderSnapshot.data();
    expect(orderData?.status).toBe('submitted');
    expect(orderData?.statusHistory).toHaveLength(1);
    expect(orderData?.statusHistory[0]).toMatchObject({
      previousStatus: null,
      newStatus: 'submitted',
      actorId: 'rep-1',
    });

    const balanceSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balanceSnapshot.data()?.physicalQuantity).toBe(8);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.docs.filter((doc) => doc.data().action === 'order.submitted')).toHaveLength(
      1,
    );
  });

  it('generates the next sequential order number for a second, different order', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(submitOrder);

    await wrapped(buildRequest(baseRequest(), authFor('rep-1')));
    const second = (await wrapped(
      buildRequest(
        baseRequest({ orderId: 'order-2' }),
        authFor('rep-1'),
      ),
    )) as SubmitOrderResponse;

    expect(second.orderNumber).toBe('000002');
  });

  it('replays the exact same result for a resubmission with the same orderId, never duplicating the order or the stock movement', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(submitOrder);
    const request = buildRequest(baseRequest(), authFor('rep-1'));

    const first = (await wrapped(request)) as SubmitOrderResponse;
    const second = (await wrapped(request)) as SubmitOrderResponse;

    // `correlationId` is per-call (`resolveCorrelationId`), never persisted —
    // every other field must be byte-for-byte the already-persisted order.
    expect(withoutCorrelationId(second)).toEqual(withoutCorrelationId(first));

    const balanceSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balanceSnapshot.data()?.physicalQuantity).toBe(8);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.docs.filter((doc) => doc.data().action === 'order.submitted')).toHaveLength(
      1,
    );
  });

  it('resolves two concurrent submissions with the same idempotency key into exactly one order', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(submitOrder);
    const request = buildRequest(baseRequest(), authFor('rep-1'));

    const [first, second] = (await Promise.all([
      wrapped(request),
      wrapped(request),
    ])) as SubmitOrderResponse[];
    // Transaction contention on the same document forces the emulator to
    // retry the loser — noticeably slower than an uncontended write.

    expect(first.orderNumber).toBe(second.orderNumber);
    expect(first.orderId).toBe(second.orderId);

    const ordersSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .get();
    expect(ordersSnapshot.docs).toHaveLength(1);

    const balanceSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    // Exactly one submission's worth of stock consumed — never twice.
    expect(balanceSnapshot.data()?.physicalQuantity).toBe(8);
  }, 20000);

  it('rejects submission and persists nothing when the customer is not active', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'company-1', 'customer-1', 'inactive');
    await seedPriceList('org-1', 'company-1', 'price-list-1');
    await seedPaymentTerm('org-1', 'company-1', 'term-1');
    await seedInventoryBalance('org-1', 'company-1', 'variant-1', 'wh-1', 10);
    const wrapped = testEnv.wrap(submitOrder);

    await expect(wrapped(buildRequest(baseRequest(), authFor('rep-1')))).rejects.toMatchObject({
      code: 'failed-precondition',
    });

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.exists).toBe(false);
  });

  it('rejects submission when the price list has already expired', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'company-1', 'customer-1');
    await seedPriceList('org-1', 'company-1', 'price-list-1', {
      validFrom: Timestamp.fromDate(new Date('2020-01-01')),
      validTo: Timestamp.fromDate(new Date('2021-01-01')),
    });
    await seedPaymentTerm('org-1', 'company-1', 'term-1');
    await seedInventoryBalance('org-1', 'company-1', 'variant-1', 'wh-1', 10);
    const wrapped = testEnv.wrap(submitOrder);

    await expect(wrapped(buildRequest(baseRequest(), authFor('rep-1')))).rejects.toMatchObject({
      code: 'failed-precondition',
    });
  });

  it('rejects submission when the requested quantity exceeds the available stock', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'company-1', 'customer-1');
    await seedPriceList('org-1', 'company-1', 'price-list-1');
    await seedPaymentTerm('org-1', 'company-1', 'term-1');
    await seedInventoryBalance('org-1', 'company-1', 'variant-1', 'wh-1', 1);
    const wrapped = testEnv.wrap(submitOrder);

    await expect(wrapped(buildRequest(baseRequest(), authFor('rep-1')))).rejects.toMatchObject({
      code: 'failed-precondition',
    });

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.exists).toBe(false);
  });

  it('rejects submission from a role without order.create (SALES_ASSISTANT)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_ASSISTANT');
    await seedCustomer('org-1', 'company-1', 'customer-1');
    await seedPriceList('org-1', 'company-1', 'price-list-1');
    await seedPaymentTerm('org-1', 'company-1', 'term-1');
    await seedInventoryBalance('org-1', 'company-1', 'variant-1', 'wh-1', 10);
    const wrapped = testEnv.wrap(submitOrder);

    await expect(wrapped(buildRequest(baseRequest(), authFor('rep-1')))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('rejects a caller submitting on behalf of a different seller', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(submitOrder);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('someone-else'))),
    ).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('submits straight to "submitted" when the manual discount stays within the profile policy (TASK-103)', async () => {
    await seedHappyPath();
    await seedDiscountPolicy('org-1', 'policy-1');
    const wrapped = testEnv.wrap(submitOrder);

    const result = (await wrapped(
      buildRequest(
        baseRequest({
          items: [
            {
              id: 'item-1',
              productId: 'product-1',
              variantId: 'variant-1',
              quantity: 2,
              manualDiscountPercent: 5,
            },
          ],
        }),
        authFor('rep-1'),
      ),
    )) as SubmitOrderResponse;

    expect(result.status).toBe('submitted');

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.status).toBe('submitted');
    expect(orderSnapshot.data()?.pricingApprovalRequired).toBe(false);
    expect(orderSnapshot.data()?.statusHistory[0]).toMatchObject({
      newStatus: 'submitted',
      reason: null,
    });
  });

  it('routes to "under_review" instead of "submitted" when the manual discount exceeds the profile policy threshold (TASK-103)', async () => {
    await seedHappyPath();
    await seedDiscountPolicy('org-1', 'policy-1');
    const wrapped = testEnv.wrap(submitOrder);

    const result = (await wrapped(
      buildRequest(
        baseRequest({
          items: [
            {
              id: 'item-1',
              productId: 'product-1',
              variantId: 'variant-1',
              quantity: 2,
              manualDiscountPercent: 12,
            },
          ],
        }),
        authFor('rep-1'),
      ),
    )) as SubmitOrderResponse;

    expect(result.status).toBe('under_review');

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    const orderData = orderSnapshot.data();
    expect(orderData?.status).toBe('under_review');
    expect(orderData?.pricingApprovalRequired).toBe(true);
    expect(orderData?.statusHistory).toHaveLength(1);
    expect(orderData?.statusHistory[0].newStatus).toBe('under_review');
    expect(orderData?.statusHistory[0].reason).toEqual(
      expect.stringContaining('12.00%'),
    );
  });

  it('rejects submission when the manual discount exceeds even the policy maximum', async () => {
    await seedHappyPath();
    await seedDiscountPolicy('org-1', 'policy-1');
    const wrapped = testEnv.wrap(submitOrder);

    await expect(
      wrapped(
        buildRequest(
          baseRequest({
            items: [
              {
                id: 'item-1',
                productId: 'product-1',
                variantId: 'variant-1',
                quantity: 2,
                manualDiscountPercent: 50,
              },
            ],
          }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.exists).toBe(false);
  });

  it('proceeds without an inventory movement when the variant has no tracked stock balance', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'company-1', 'customer-1');
    await seedPriceList('org-1', 'company-1', 'price-list-1');
    await seedPaymentTerm('org-1', 'company-1', 'term-1');
    // No inventory balance seeded at all for variant-1.
    const wrapped = testEnv.wrap(submitOrder);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('rep-1')),
    )) as SubmitOrderResponse;

    expect(result.status).toBe('submitted');
  });
});
