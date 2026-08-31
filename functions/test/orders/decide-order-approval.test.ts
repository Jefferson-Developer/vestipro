import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  decideOrderApproval,
  type DecideOrderApprovalRequest,
  type DecideOrderApprovalResponse,
} from '../../src/orders/decide-order-approval';

const PROJECT_ID = 'demo-vestipro-decide-order-approval-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: DecideOrderApprovalRequest,
  auth?: CallableRequest<DecideOrderApprovalRequest>['auth'],
): CallableRequest<DecideOrderApprovalRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<DecideOrderApprovalRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<DecideOrderApprovalRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<DecideOrderApprovalRequest>['auth'];
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
  teamIds: string[] = [],
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
      teamIds,
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

async function seedOrderUnderReview(
  organizationId: string,
  companyId: string,
  orderId: string,
  sellerId: string,
  overrides: { status?: string } = {},
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
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010000',
        country: 'BR',
      },
      billingAddress: {
        street: 'Rua das Flores',
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010000',
        country: 'BR',
      },
      priceListId: 'price-list-1',
      paymentTermId: 'term-1',
      carrierId: null,
      collectionId: null,
      orderType: null,
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
      discountAmount: 24,
      surchargeAmount: 0,
      shippingAmount: 0,
      taxAmount: null,
      notes: null,
      attachmentUrls: [],
      status: overrides.status ?? 'under_review',
      statusHistory: [
        {
          previousStatus: null,
          newStatus: 'under_review',
          changedAt: now,
          actorId: sellerId,
          reason: 'Desconto manual de 12.00% excede o limite de 10.00%.',
        },
      ],
      approvedBy: null,
      approvedAt: null,
      rejectionReason: null,
      pricingApprovalRequired: true,
      idempotencyKey: orderId,
      createdAt: now,
      createdBy: sellerId,
      updatedAt: now,
      updatedBy: sellerId,
      deletedAt: null,
      version: 1,
      syncStatus: 'synced',
    });
}

describe('decideOrderApproval', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('approves a pedido under_review as OWNER, recording approvedBy/approvedAt and the status history entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          decision: 'approved',
        },
        authFor('owner-1'),
      ),
    )) as DecideOrderApprovalResponse;

    expect(result.status).toBe('approved');
    expect(result.approverId).toBe('owner-1');

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    const orderData = orderSnapshot.data();
    expect(orderData?.status).toBe('approved');
    expect(orderData?.approvedBy).toBe('owner-1');
    expect(orderData?.approvedAt).not.toBeNull();
    expect(orderData?.statusHistory).toHaveLength(2);
    expect(orderData?.statusHistory[1]).toMatchObject({
      previousStatus: 'under_review',
      newStatus: 'approved',
      actorId: 'owner-1',
    });

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(
      auditSnapshot.docs.filter((doc) => doc.data().action === 'order.approved'),
    ).toHaveLength(1);
  });

  it('rejects a pedido under_review with a mandatory justification, recording rejectionReason and the status history entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', ['team-1']);
    await seedMember('org-1', 'rep-1', 'SALES_REP', ['team-1']);
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          decision: 'rejected',
          reason: 'Desconto acima do que o cliente costuma negociar.',
        },
        authFor('manager-1'),
      ),
    )) as DecideOrderApprovalResponse;

    expect(result.status).toBe('rejected');
    expect(result.reason).toBe('Desconto acima do que o cliente costuma negociar.');

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    const orderData = orderSnapshot.data();
    expect(orderData?.status).toBe('rejected');
    expect(orderData?.rejectionReason).toBe(
      'Desconto acima do que o cliente costuma negociar.',
    );
    expect(orderData?.approvedBy).toBeNull();
  });

  it('rejects the call when a rejection carries no reason', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            decision: 'rejected',
          },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.status).toBe('under_review');
  });

  it('denies a SALES_REP (no order.approve) from deciding a pedido', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            decision: 'approved',
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('denies a SALES_MANAGER from deciding a pedido whose seller is outside every one of their own teams', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', ['team-1']);
    await seedMember('org-1', 'rep-1', 'SALES_REP', ['team-2']);
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            decision: 'approved',
          },
          authFor('manager-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.status).toBe('under_review');
  });

  it('rejects deciding a pedido that is not currently under_review', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1', {
      status: 'submitted',
    });
    const wrapped = testEnv.wrap(decideOrderApproval);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            decision: 'approved',
          },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects deciding a pedido that does not belong to the requested company', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-2',
            orderId: 'order-1',
            decision: 'approved',
          },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('replays the exact same result for a retried decision, never appending a second status history entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrderUnderReview('org-1', 'company-1', 'order-1', 'rep-1');
    const wrapped = testEnv.wrap(decideOrderApproval);
    const request = buildRequest(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
        decision: 'approved',
      },
      authFor('owner-1'),
    );

    const first = (await wrapped(request)) as DecideOrderApprovalResponse;
    const second = (await wrapped(request)) as DecideOrderApprovalResponse;

    expect(second).toEqual(first);

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.statusHistory).toHaveLength(2);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(
      auditSnapshot.docs.filter((doc) => doc.data().action === 'order.approved'),
    ).toHaveLength(1);
  });
});
