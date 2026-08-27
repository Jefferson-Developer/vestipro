import { getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

type StoredDocument = Record<string, unknown>;

class FakeDocumentSnapshot {
  constructor(
    readonly id: string,
    private readonly value: StoredDocument | undefined,
  ) {}

  get exists(): boolean {
    return this.value !== undefined;
  }

  data(): StoredDocument | undefined {
    return this.value ? { ...this.value } : undefined;
  }
}

class FakeQueryDocumentSnapshot extends FakeDocumentSnapshot {
  override get exists(): boolean {
    return true;
  }

  override data(): StoredDocument {
    return super.data() ?? {};
  }
}

class FakeCollectionReference {
  constructor(
    private readonly store: Map<string, StoredDocument>,
    readonly path: string,
  ) {}

  doc(id: string): FakeDocumentReference {
    return new FakeDocumentReference(this.store, `${this.path}/${id}`);
  }

  async get(): Promise<{ docs: FakeQueryDocumentSnapshot[] }> {
    const docs = [...this.store.entries()]
      .filter(([key]) => this.isDirectChild(key))
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, value]) => new FakeQueryDocumentSnapshot(lastSegment(key), value));

    return { docs };
  }

  private isDirectChild(key: string): boolean {
    if (!key.startsWith(`${this.path}/`)) return false;
    const remainder = key.slice(this.path.length + 1);
    return !remainder.includes('/');
  }
}

class FakeDocumentReference {
  constructor(
    private readonly store: Map<string, StoredDocument>,
    readonly path: string,
  ) {}

  collection(name: string): FakeCollectionReference {
    return new FakeCollectionReference(this.store, `${this.path}/${name}`);
  }

  async get(): Promise<FakeDocumentSnapshot> {
    return new FakeDocumentSnapshot(lastSegment(this.path), this.store.get(this.path));
  }

  async set(value: StoredDocument): Promise<void> {
    this.store.set(this.path, { ...value });
  }

  async create(value: StoredDocument): Promise<void> {
    if (this.store.has(this.path)) {
      const error = new Error('already exists') as Error & { code?: number };
      error.code = 6;
      throw error;
    }
    this.store.set(this.path, { ...value });
  }
}

class FakeFirestore {
  private readonly store = new Map<string, StoredDocument>();

  collection(path: string): FakeCollectionReference {
    return new FakeCollectionReference(this.store, path);
  }

  async listCollections(): Promise<FakeCollectionReference[]> {
    const rootNames = new Set<string>();
    for (const key of this.store.keys()) {
      const rootName = key.split('/')[0];
      if (rootName) rootNames.add(rootName);
    }
    return [...rootNames].sort().map((name) => this.collection(name));
  }

  async recursiveDelete(reference: FakeCollectionReference): Promise<void> {
    for (const key of [...this.store.keys()]) {
      if (key === reference.path || key.startsWith(`${reference.path}/`)) {
        this.store.delete(key);
      }
    }
  }

  async terminate(): Promise<void> {
    this.store.clear();
  }
}

const fakeDb = new FakeFirestore();

jest.mock('firebase-admin/firestore', () => {
  const actual = jest.requireActual('firebase-admin/firestore') as Record<string, unknown>;
  return {
    ...actual,
    getFirestore: () => fakeDb,
  };
});

import {
  calculatePricing,
  type CalculatePricingRequest,
  type CalculatePricingResponse,
} from '../../src/pricing';

const PROJECT_ID = 'demo-vestipro-pricing-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

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

function authFor(uid: string): CallableRequest<CalculatePricingRequest>['auth'] {
  return {
    uid,
    token: { email: `${uid}@vestipro.test` },
    rawToken: 'raw-token',
  } as CallableRequest<CalculatePricingRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await fakeDb.listCollections();
  await Promise.all(collections.map((collection) => fakeDb.recursiveDelete(collection)));
}

async function seedBasePricingData(): Promise<void> {
  const orgRef = fakeDb.collection('organizations').doc('org-1');
  await orgRef.set({ name: 'Org 1' });
  await orgRef.collection('members').doc('rep-1').set({
    roleName: 'SALES_REP',
  });
  await orgRef.collection('priceLists').doc('price-list-1').set({
    companyId: 'company-1',
    currency: 'BRL',
    status: 'active',
    validFrom: Timestamp.fromDate(new Date('2026-08-01T00:00:00.000Z')),
  });
  await orgRef.collection('priceLists').doc('price-list-1').collection('items').doc('item-1').set({
    companyId: 'company-1',
    productId: 'product-1',
    variantId: null,
    price: 100,
  });
  await orgRef.collection('paymentTerms').doc('term-1').set({
    companyId: 'company-1',
    name: '30 dias',
    averageTermDays: 30,
    status: 'active',
    priceListIds: ['price-list-1'],
  });
  await orgRef.collection('discountPolicies').doc('policy-1').set({
    companyId: 'company-1',
    role: 'SALES_REP',
    maxDiscountPercent: 15,
    requiresApprovalAbovePercent: 10,
    priceListIds: ['price-list-1'],
    status: 'active',
  });
}

describe('calculatePricing', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await fakeDb.terminate();
  });

  it('calculates base pricing with a manual discount inside the limit', async () => {
    await seedBasePricingData();
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          customerSegment: 'vip',
          priceListId: 'price-list-1',
          paymentTermId: 'term-1',
          idempotencyKey: 'key-1',
          items: [
            {
              productId: 'product-1',
              quantity: 2,
              manualDiscountPercent: 5,
            },
          ],
        },
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.total).toBe(190);
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(false);
  });

  it('applies the highest-priority non-stackable campaign and marks approval above threshold', async () => {
    await seedBasePricingData();
    const orgRef = fakeDb.collection('organizations').doc('org-1');
    await orgRef.collection('promotionalCampaigns').doc('campaign-1').set({
      companyId: 'company-1',
      name: 'Liquidacao 1',
      customerSegment: 'vip',
      productIds: ['product-1'],
      collectionIds: [],
      categoryIds: [],
      discountType: 'percentage',
      discountValue: 10,
      stackableWithOtherCampaigns: false,
      priority: 1,
      status: 'active',
      validFrom: Timestamp.fromDate(new Date('2026-08-01T00:00:00.000Z')),
      validTo: Timestamp.fromDate(new Date('2026-12-31T00:00:00.000Z')),
    });
    await orgRef.collection('promotionalCampaigns').doc('campaign-2').set({
      companyId: 'company-1',
      name: 'Liquidacao 2',
      customerSegment: 'vip',
      productIds: ['product-1'],
      collectionIds: [],
      categoryIds: [],
      discountType: 'percentage',
      discountValue: 20,
      stackableWithOtherCampaigns: false,
      priority: 9,
      status: 'active',
      validFrom: Timestamp.fromDate(new Date('2026-08-01T00:00:00.000Z')),
      validTo: Timestamp.fromDate(new Date('2026-12-31T00:00:00.000Z')),
    });

    const wrapped = testEnv.wrap(calculatePricing);
    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          customerSegment: 'vip',
          priceListId: 'price-list-1',
          paymentTermId: 'term-1',
          idempotencyKey: 'key-2',
          items: [
            {
              productId: 'product-1',
              quantity: 1,
              manualDiscountPercent: 12,
            },
          ],
        },
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.items[0].appliedDiscounts[0].campaignId).toBe('campaign-2');
    expect(result.approvalRequired).toBe(true);
    expect(result.blocked).toBe(false);
  });

  it('blocks a manual discount above the maximum policy limit', async () => {
    await seedBasePricingData();
    const wrapped = testEnv.wrap(calculatePricing);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          customerSegment: 'vip',
          priceListId: 'price-list-1',
          paymentTermId: 'term-1',
          idempotencyKey: 'key-3',
          items: [
            {
              productId: 'product-1',
              quantity: 1,
              manualDiscountPercent: 18,
            },
          ],
        },
        authFor('rep-1'),
      ),
    )) as CalculatePricingResponse;

    expect(result.blocked).toBe(true);
    expect(result.items[0].validationStatus).toBe('blocked');
    expect(result.total).toBe(100);
  });

  it('returns the cached result for the same idempotency key and payload', async () => {
    await seedBasePricingData();
    const wrapped = testEnv.wrap(calculatePricing);
    const request = buildRequest(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        customerSegment: 'vip',
        priceListId: 'price-list-1',
        paymentTermId: 'term-1',
        idempotencyKey: 'key-4',
        items: [
          {
            productId: 'product-1',
            quantity: 1,
            manualDiscountPercent: 5,
          },
        ],
      },
      authFor('rep-1'),
    );

    const first = (await wrapped(request)) as CalculatePricingResponse;
    await fakeDb
      .collection('organizations')
      .doc('org-1')
      .collection('priceLists')
      .doc('price-list-1')
      .collection('items')
      .doc('item-1')
      .set({ companyId: 'company-1', productId: 'product-1', variantId: null, price: 250 });

    const second = (await wrapped(request)) as CalculatePricingResponse;

    expect(second.total).toBe(first.total);
    expect(second.idempotencyKey).toBe('key-4');
  });

  it('rejects reusing the same idempotency key with a different payload', async () => {
    await seedBasePricingData();
    const wrapped = testEnv.wrap(calculatePricing);

    await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          customerSegment: 'vip',
          priceListId: 'price-list-1',
          paymentTermId: 'term-1',
          idempotencyKey: 'key-5',
          items: [{ productId: 'product-1', quantity: 1 }],
        },
        authFor('rep-1'),
      ),
    );

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            customerSegment: 'vip',
            priceListId: 'price-list-1',
            paymentTermId: 'term-1',
            idempotencyKey: 'key-5',
            items: [{ productId: 'product-1', quantity: 2 }],
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'already-exists' });
  });
});

function lastSegment(path: string): string {
  const segments = path.split('/');
  return segments[segments.length - 1] ?? path;
}
