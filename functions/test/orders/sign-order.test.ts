import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { signOrder, type SignOrderRequest, type SignOrderResponse } from '../../src/orders/sign-order';

const PROJECT_ID = 'demo-vestipro-sign-order-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID, storageBucket: `${PROJECT_ID}.appspot.com` });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

const VALID_PNG_BASE64 = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x01, 0x02, 0x03,
]).toString('base64');

function buildRequest(
  data: SignOrderRequest,
  auth?: CallableRequest<SignOrderRequest>['auth'],
): CallableRequest<SignOrderRequest> {
  return {
    data,
    auth,
    rawRequest: { ip: '203.0.113.10' } as CallableRequest<SignOrderRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(uid: string, token: Record<string, unknown> = {}): CallableRequest<SignOrderRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<SignOrderRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
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

interface SeedOrderOverrides {
  status?: string;
  discountAmount?: number;
}

async function seedOrder(
  organizationId: string,
  companyId: string,
  orderId: string,
  sellerId: string,
  overrides: SeedOrderOverrides = {},
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('orders')
    .doc(orderId)
    .set({
      organizationId,
      companyId,
      branchId: 'branch-1',
      customerId: 'customer-1',
      sellerId,
      orderNumber: '000001',
      deliveryAddress: {
        street: 'Rua das Flores',
        number: null,
        complement: null,
        district: null,
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010000',
        country: 'BR',
      },
      billingAddress: {
        street: 'Rua das Flores',
        number: null,
        complement: null,
        district: null,
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010000',
        country: 'BR',
      },
      priceListId: 'price-list-1',
      currency: 'BRL',
      paymentTermId: 'term-1',
      carrierId: null,
      items: [
        {
          id: 'item-1',
          variantId: 'variant-1',
          productId: 'product-1',
          quantity: 2,
          unitPrice: 88,
          discountAmount: 12,
          surchargeAmount: 0,
          subtotal: 176,
        },
      ],
      discountAmount: overrides.discountAmount ?? 24,
      surchargeAmount: 0,
      shippingAmount: 0,
      taxAmount: null,
      notes: null,
      status: overrides.status ?? 'submitted',
      statusHistory: [],
      approvedBy: null,
      approvedAt: null,
      rejectionReason: null,
      createdAt: now,
      createdBy: sellerId,
      updatedAt: now,
      updatedBy: sellerId,
      deletedAt: null,
      version: 1,
      syncStatus: 'synced',
    });
}

/** Mirrors `buildOrderContentHash` (`../../src/orders/sign-order.ts`) exactly
 * for the fixed order shape `seedOrder` above always writes — this test
 * suite's own way of computing "the client's own already-correct hash"
 * without importing a private function. */
function expectedContentHash(): string {
  const payload = {
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    orderNumber: '000001',
    deliveryAddress: {
      street: 'Rua das Flores',
      number: null,
      complement: null,
      district: null,
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
      country: 'BR',
    },
    billingAddress: {
      street: 'Rua das Flores',
      number: null,
      complement: null,
      district: null,
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
      country: 'BR',
    },
    priceListId: 'price-list-1',
    currency: 'BRL',
    paymentTermId: 'term-1',
    carrierId: null,
    items: [
      {
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: '88.00',
        discountAmount: '12.00',
        surchargeAmount: '0.00',
        subtotal: '176.00',
      },
    ],
    discountAmount: '24.00',
    surchargeAmount: '0.00',
    shippingAmount: '0.00',
    taxAmount: null,
    notes: null,
  };
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

describe('signOrder', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('persists an immutable signature + its PNG evidence for an eligible, unsigned order', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          signatureId: 'signature-1',
          signerRole: 'customer',
          signedByName: 'Maria Cliente',
          method: 'canvas_drawn',
          imageBase64: VALID_PNG_BASE64,
          contentHash: expectedContentHash(),
          orderVersionAtSignature: 1,
          signedAt: new Date().toISOString(),
          _meta: { platform: 'android', appVersion: '1.0.0' },
        },
        authFor('rep-1'),
      ),
    )) as SignOrderResponse;

    expect(result.signatureId).toBe('signature-1');
    expect(result.deviceInfo).toBe('android 1.0.0');
    expect(result.ipAddress).toBe('203.0.113.10');

    const signatureSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .collection('signatures')
      .doc('signature-1')
      .get();
    const signatureData = signatureSnapshot.data();
    expect(signatureData?.status).toBe('valid');
    expect(signatureData?.signedByUserId).toBe('rep-1');
    expect(signatureData?.contentHash).toBe(expectedContentHash());

    const [imageExists] = await getStorage()
      .bucket()
      .file(`organizations/org-1/orders/order-1/signatures/signature-1.png`)
      .exists();
    expect(imageExists).toBe(true);
  });

  it('rejects signing when the client-computed content hash does not match the order\'s current server-side state', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            signatureId: 'signature-1',
            signerRole: 'customer',
            signedByName: 'Maria Cliente',
            method: 'canvas_drawn',
            imageBase64: VALID_PNG_BASE64,
            contentHash: 'stale-hash-from-a-different-order-version',
            orderVersionAtSignature: 1,
            signedAt: new Date().toISOString(),
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const signaturesSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .collection('signatures')
      .get();
    expect(signaturesSnapshot.empty).toBe(true);
  });

  it('rejects signing the same order twice', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);
    const firstRequest = buildRequest(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
        signatureId: 'signature-1',
        signerRole: 'customer',
        signedByName: 'Maria Cliente',
        method: 'canvas_drawn',
        imageBase64: VALID_PNG_BASE64,
        contentHash: expectedContentHash(),
        orderVersionAtSignature: 1,
        signedAt: new Date().toISOString(),
      },
      authFor('rep-1'),
    );
    await wrapped(firstRequest);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            signatureId: 'signature-2',
            signerRole: 'seller',
            signedByName: 'Vendedor Teste',
            method: 'canvas_drawn',
            imageBase64: VALID_PNG_BASE64,
            contentHash: expectedContentHash(),
            orderVersionAtSignature: 1,
            signedAt: new Date().toISOString(),
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('replays the exact same result for a retried capture with the same signatureId, never writing a second document', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);
    const request = buildRequest(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
        signatureId: 'signature-1',
        signerRole: 'customer',
        signedByName: 'Maria Cliente',
        method: 'canvas_drawn',
        imageBase64: VALID_PNG_BASE64,
        contentHash: expectedContentHash(),
        orderVersionAtSignature: 1,
        signedAt: new Date().toISOString(),
      },
      authFor('rep-1'),
    );

    const first = (await wrapped(request)) as SignOrderResponse;
    const second = (await wrapped(request)) as SignOrderResponse;

    expect(second).toEqual(first);

    const signaturesSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .collection('signatures')
      .get();
    expect(signaturesSnapshot.docs).toHaveLength(1);
  });

  it('rejects signing a pedido still in draft/pending_sync status', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1', { status: 'draft' });
    const wrapped = testEnv.wrap(signOrder);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            signatureId: 'signature-1',
            signerRole: 'customer',
            signedByName: 'Maria Cliente',
            method: 'canvas_drawn',
            imageBase64: VALID_PNG_BASE64,
            contentHash: expectedContentHash(),
            orderVersionAtSignature: 1,
            signedAt: new Date().toISOString(),
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('denies a SALES_ASSISTANT (not allowed to sign orders) from signing', async () => {
    await seedMember('org-1', 'assistant-1', 'SALES_ASSISTANT');
    await seedOrder('org-1', 'company-1', 'order-1', 'assistant-1');
    const wrapped = testEnv.wrap(signOrder);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            signatureId: 'signature-1',
            signerRole: 'seller',
            signedByName: 'Assistente Teste',
            method: 'canvas_drawn',
            imageBase64: VALID_PNG_BASE64,
            contentHash: expectedContentHash(),
            orderVersionAtSignature: 1,
            signedAt: new Date().toISOString(),
          },
          authFor('assistant-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('denies signing a pedido that belongs to a different seller', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedMember('org-1', 'rep-2', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            signatureId: 'signature-1',
            signerRole: 'customer',
            signedByName: 'Maria Cliente',
            method: 'canvas_drawn',
            imageBase64: VALID_PNG_BASE64,
            contentHash: expectedContentHash(),
            orderVersionAtSignature: 1,
            signedAt: new Date().toISOString(),
          },
          authFor('rep-2'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects an unauthenticated call', async () => {
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);

    await expect(
      wrapped(
        buildRequest({
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          signatureId: 'signature-1',
          signerRole: 'customer',
          signedByName: 'Maria Cliente',
          method: 'canvas_drawn',
          imageBase64: VALID_PNG_BASE64,
          contentHash: expectedContentHash(),
          orderVersionAtSignature: 1,
          signedAt: new Date().toISOString(),
        }),
      ),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('rejects a payload whose imageBase64 does not decode to a PNG', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(signOrder);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            signatureId: 'signature-1',
            signerRole: 'customer',
            signedByName: 'Maria Cliente',
            method: 'canvas_drawn',
            imageBase64: Buffer.from('not-a-png').toString('base64'),
            contentHash: expectedContentHash(),
            orderVersionAtSignature: 1,
            signedAt: new Date().toISOString(),
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
