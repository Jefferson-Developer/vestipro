import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import { processRecurringOrdersHandler } from '../../src/orders/process-recurring-orders';

const PROJECT_ID = 'demo-vestipro-recurring-order-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });
const now = new Date('2026-09-09T12:00:00.000Z');

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedBase(overrides: {
  planStatus?: string;
  physicalQuantity?: number;
  price?: number;
  expectedUnitPrice?: number;
  manualDiscountPercent?: number;
} = {}): Promise<void> {
  const orgRef = db.collection('organizations').doc('org-1');
  await orgRef.set({ name: 'Org', status: 'active' });
  await orgRef.collection('customers').doc('customer-1').set({
    organizationId: 'org-1',
    companyId: 'company-1',
    status: 'active',
    segment: 'varejo',
  });
  const priceListRef = orgRef.collection('priceLists').doc('price-list-1');
  await priceListRef.set({
    organizationId: 'org-1',
    companyId: 'company-1',
    currency: 'BRL',
    status: 'active',
    validFrom: Timestamp.fromDate(new Date('2020-01-01T00:00:00.000Z')),
    validTo: null,
  });
  await priceListRef.collection('items').doc('item-1').set({
    productId: 'product-1',
    variantId: 'variant-1',
    companyId: 'company-1',
    price: overrides.price ?? 100,
  });
  await orgRef.collection('paymentTerms').doc('term-1').set({
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'A vista',
    averageTermDays: 0,
    status: 'active',
    priceListIds: [],
  });
  await orgRef.collection('inventory').doc('variant-1_wh-1').set({
    organizationId: 'org-1',
    companyId: 'company-1',
    productId: 'product-1',
    variantId: 'variant-1',
    warehouseId: 'wh-1',
    physicalQuantity: overrides.physicalQuantity ?? 10,
    reservedQuantity: 0,
    blockedQuantity: 0,
  });
  await orgRef.collection('discountPolicies').doc('policy-1').set({
    role: 'SALES_REP',
    maxDiscountPercent: 20,
    requiresApprovalAbovePercent: 10,
    priceListIds: [],
    status: 'active',
  });
  await orgRef.collection('recurringOrderPlans').doc('plan-1').set({
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    sourceOrderId: 'source-order-1',
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    frequency: { interval: 7, unit: 'days' },
    nextExecutionAt: Timestamp.fromDate(now),
    status: overrides.planStatus ?? 'active',
    deliveryAddress: {
      street: 'Rua A',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    },
    billingAddress: {
      street: 'Rua A',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    },
    items: [{
      id: 'item-1',
      productId: 'product-1',
      variantId: 'variant-1',
      quantity: 2,
      expectedUnitPrice: overrides.expectedUnitPrice ?? 100,
      manualDiscountPercent: overrides.manualDiscountPercent ?? 0,
    }],
    createdAt: Timestamp.fromDate(new Date('2026-09-01T00:00:00.000Z')),
    createdBy: 'rep-1',
    updatedAt: Timestamp.fromDate(new Date('2026-09-01T00:00:00.000Z')),
    updatedBy: 'rep-1',
    version: 1,
  });
}

describe('processRecurringOrdersHandler', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('generates a submitted order with fresh pricing and consumes stock once', async () => {
    await seedBase();

    const first = await processRecurringOrdersHandler({ db, now });
    const second = await processRecurringOrdersHandler({ db, now });

    expect(first.generatedOrders).toBe(1);
    expect(second.generatedOrders).toBe(0);

    const orders = await db.collection('organizations/org-1/orders').get();
    expect(orders.docs).toHaveLength(1);
    expect(orders.docs[0]!.data()).toMatchObject({
      status: 'submitted',
      submittedVia: 'recurring_order',
      recurringOrderPlanId: 'plan-1',
    });
    const balance = await db.doc('organizations/org-1/inventory/variant-1_wh-1').get();
    expect(balance.data()?.physicalQuantity).toBe(8);
  });

  it('creates a review-required order when stock is unavailable', async () => {
    await seedBase({ physicalQuantity: 1 });

    const summary = await processRecurringOrdersHandler({ db, now });

    expect(summary.reviewRequiredOrders).toBe(1);
    const order = (await db.collection('organizations/org-1/orders').get()).docs[0]!.data();
    expect(order.status).toBe('draft_review_required');
    expect(order.recurringOrderDifferences.unavailableItems).toHaveLength(1);
  });

  it('creates a review-required order when current price changed', async () => {
    await seedBase({ price: 120, expectedUnitPrice: 100 });

    const summary = await processRecurringOrdersHandler({ db, now });

    expect(summary.reviewRequiredOrders).toBe(1);
    const order = (await db.collection('organizations/org-1/orders').get()).docs[0]!.data();
    expect(order.status).toBe('draft_review_required');
    expect(order.recurringOrderDifferences.priceChanges[0]).toMatchObject({
      expectedUnitPrice: 100,
      currentUnitPrice: 120,
    });
  });

  it('keeps approval required for recurring orders when discount policy requires approval', async () => {
    await seedBase({ manualDiscountPercent: 12 });

    await processRecurringOrdersHandler({ db, now });

    const order = (await db.collection('organizations/org-1/orders').get()).docs[0]!.data();
    expect(order.status).toBe('under_review');
    expect(order.pricingApprovalRequired).toBe(true);
  });

  it('does not generate orders for paused plans', async () => {
    await seedBase({ planStatus: 'paused' });

    const summary = await processRecurringOrdersHandler({ db, now });

    expect(summary.processedPlans).toBe(0);
    const orders = await db.collection('organizations/org-1/orders').get();
    expect(orders.docs).toHaveLength(0);
  });
});
