import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  calculatePricing,
  type CalculatePricingRequest,
  type CalculatePricingResponse,
} from '../../src/pricing/calculate-pricing';

/**
 * Firebase Emulator Suite test (TASK-162) — same shape as
 * `functions/test/orders/submit-order.test.ts`: exercises the real `onCall`
 * `calculatePricing` against a real Firestore Emulator instance (never
 * mocked/faked Firestore), covering the "motor de precificação server-side"
 * scenarios required by the task: preço correto, desconto dentro do limite,
 * desconto acima do limite gerando aprovação, e desconto acima do máximo
 * bloqueado.
 *
 * `functions/test/pricing/calculate-pricing.test.ts` (pre-existing, TASK-088)
 * already covers the pricing engine's branching in isolation against a fake
 * in-memory Firestore — kept as-is (fast, exhaustive unit coverage of edge
 * cases). This file does not duplicate those cases; it validates the same
 * Cloud Function end-to-end against the real Firestore Emulator, which the
 * fake-Firestore suite cannot do (it never runs the real `onCall` wiring,
 * the real idempotency cache reads/writes, nor real document shapes).
 *
 * Requires `firebase emulators:start`/`emulators:exec` with Java available —
 * see `docs/tasks/TASK-162-criar-testes-de-integracao-com-emulator-CONCLUIDA.md`
 * if this fails with "Could not spawn `java -version`" in a sandboxed
 * environment; that is a pre-existing environment limitation (BACKLOG-002),
 * not specific to this test.
 *
 *   firebase emulators:exec --only firestore "npm --prefix functions test -- calculate-pricing.emulator"
 */
const PROJECT_ID = 'demo-vestipro-calculate-pricing-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CalculatePricingRequest,
  auth?: CallableRequest<CalculatePricingRequest>['auth'],
): CallableRequest<CalculatePricingRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CalculatePricingRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<CalculatePricingRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<CalculatePricingRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedMember(organizationId: string, uid: string, roleName: string): Promise<void> {
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

async function seedPriceList(
  organizationId: string,
  companyId: string,
  priceListId: string,
  price = 100,
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
    status: 'active',
    validFrom: Timestamp.fromDate(new Date('2020-01-01')),
    validTo: null,
  });
  await priceListRef.collection('items').doc('item-1').set({
    productId: 'product-1',
    variantId: 'variant-1',
    companyId,
    price,
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

function baseRequest(overrides: Partial<CalculatePricingRequest> = {}): CalculatePricingRequest {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    customerSegment: 'varejo',
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    idempotencyKey: 'calc-1',
    shippingAmount: 0,
    items: [
      {
        productId: 'product-1',
        variantId: 'variant-1',
        quantity: 2,
      },
    ],
    ...overrides,
  };
}

async function seedHappyPath(): Promise<void> {
  await seedMember('org-1', 'rep-1', 'SALES_REP');
  await seedPriceList('org-1', 'company-1', 'price-list-1');
  await seedPaymentTerm('org-1', 'company-1', 'term-1');
}

describe('calculatePricing (Firebase Emulator, real Firestore)', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('calculates the correct total for a plain price-list lookup, no discounts or campaigns', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('rep-1')),
    )) as CalculatePricingResponse;

    expect(result.subtotal).toBe(200);
    expect(result.total).toBe(200);
    expect(result.manualDiscountTotal).toBe(0);
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(false);
    expect(result.items[0].validationStatus).toBe('allowed');
  });

  it('applies a manual discount within the policy threshold without requiring approval', async () => {
    await seedHappyPath();
    await seedDiscountPolicy('org-1', 'policy-1');
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(
        baseRequest({
          items: [
            { productId: 'product-1', variantId: 'variant-1', quantity: 2, manualDiscountPercent: 5 },
          ],
        }),
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.total).toBe(190);
    expect(result.manualDiscountTotal).toBe(10);
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(false);
    expect(result.items[0].validationStatus).toBe('allowed');
  });

  it('routes to requires_approval when the manual discount exceeds the approval threshold but stays within the maximum', async () => {
    await seedHappyPath();
    await seedDiscountPolicy('org-1', 'policy-1');
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(
        baseRequest({
          items: [
            { productId: 'product-1', variantId: 'variant-1', quantity: 2, manualDiscountPercent: 12 },
          ],
        }),
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(true);
    expect(result.items[0].validationStatus).toBe('requires_approval');
    expect(result.items[0].approvalRequest).toMatchObject({
      discountPolicyId: 'policy-1',
      requestedDiscountPercent: 12,
      approvalThresholdPercent: 10,
      maxDiscountPercent: 15,
    });
  });

  it('blocks the calculation when the manual discount exceeds even the policy maximum', async () => {
    await seedHappyPath();
    await seedDiscountPolicy('org-1', 'policy-1');
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(
        baseRequest({
          items: [
            { productId: 'product-1', variantId: 'variant-1', quantity: 2, manualDiscountPercent: 20 },
          ],
        }),
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.blocked).toBe(true);
    expect(result.items[0].validationStatus).toBe('blocked');
    // Blocked lines never apply the requested manual discount to the total.
    expect(result.total).toBe(200);
  });

  it('blocks the manual discount when the caller role has no active discount policy at all', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(
        baseRequest({
          items: [
            { productId: 'product-1', variantId: 'variant-1', quantity: 2, manualDiscountPercent: 5 },
          ],
        }),
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.blocked).toBe(true);
    expect(result.items[0].validationStatus).toBe('blocked');
  });

  it('replays the exact same response for a repeated idempotencyKey instead of recalculating', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(calculatePricing);
    const request = buildRequest(baseRequest(), authFor('rep-1'));

    const first = (await wrapped(request)) as CalculatePricingResponse;
    const second = (await wrapped(request)) as CalculatePricingResponse;

    expect(second.total).toBe(first.total);
    expect(second.subtotal).toBe(first.subtotal);

    const cacheSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('pricingCalculations')
      .doc('calc-1')
      .get();
    expect(cacheSnapshot.exists).toBe(true);
  });

  it('rejects reusing the same idempotencyKey with a different payload', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(calculatePricing);

    await wrapped(buildRequest(baseRequest(), authFor('rep-1')));

    await expect(
      wrapped(
        buildRequest(
          baseRequest({
            items: [{ productId: 'product-1', variantId: 'variant-1', quantity: 3 }],
          }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'already-exists' });
  });

  it('rejects an unauthenticated call', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(calculatePricing);

    await expect(wrapped(buildRequest(baseRequest(), undefined))).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('rejects a caller with no Membership in the requested organization', async () => {
    await seedPriceList('org-1', 'company-1', 'price-list-1');
    await seedPaymentTerm('org-1', 'company-1', 'term-1');
    const wrapped = testEnv.wrap(calculatePricing);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('no-membership'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});
