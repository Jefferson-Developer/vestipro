import {
  DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY,
  ROLES_ALLOWED_TO_CONVERT_BACKORDER,
  ROLES_ALLOWED_TO_DECIDE_BACKORDER,
  ROLES_ALLOWED_TO_REQUEST_BACKORDER,
  ensureRequesterMayActOnBackorder,
  priorityWeight,
  requireBackorderOrigin,
  requireBackorderPriority,
  resolveAutoApproveMaxQuantity,
} from '../../src/backorder/backorder-shared';
import type { ReturnRequestOrder } from '../../src/returns/return-shared';

function buildOrder(overrides: Partial<ReturnRequestOrder> = {}): ReturnRequestOrder {
  return {
    id: 'order-1',
    organizationId: 'org-a',
    companyId: 'company-a',
    customerId: 'customer-a',
    sellerId: 'seller-a',
    orderNumber: '1001',
    currency: 'BRL',
    status: 'invoiced',
    items: [],
    ...overrides,
  };
}

describe('priorityWeight', () => {
  it('ranks urgent above high above normal above low', () => {
    expect(priorityWeight('urgent')).toBeGreaterThan(priorityWeight('high'));
    expect(priorityWeight('high')).toBeGreaterThan(priorityWeight('normal'));
    expect(priorityWeight('normal')).toBeGreaterThan(priorityWeight('low'));
  });
});

describe('requireBackorderOrigin', () => {
  it('accepts every known origin', () => {
    for (const origin of ['catalog', 'order', 'pre_book', 'manual']) {
      expect(requireBackorderOrigin(origin)).toBe(origin);
    }
  });

  it('rejects an unknown/missing origin', () => {
    expect(() => requireBackorderOrigin('bogus')).toThrow();
    expect(() => requireBackorderOrigin(undefined)).toThrow();
  });
});

describe('requireBackorderPriority', () => {
  it('defaults to normal when omitted', () => {
    expect(requireBackorderPriority(undefined)).toBe('normal');
    expect(requireBackorderPriority(null)).toBe('normal');
  });

  it('accepts every known priority', () => {
    for (const priority of ['low', 'normal', 'high', 'urgent']) {
      expect(requireBackorderPriority(priority)).toBe(priority);
    }
  });

  it('rejects an unknown priority', () => {
    expect(() => requireBackorderPriority('critical')).toThrow();
  });
});

describe('resolveAutoApproveMaxQuantity', () => {
  it('falls back to the default when the organization has no override', () => {
    expect(resolveAutoApproveMaxQuantity(undefined)).toBe(DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY);
    expect(resolveAutoApproveMaxQuantity({})).toBe(DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY);
  });

  it('uses the organization override when it is a valid non-negative number', () => {
    expect(resolveAutoApproveMaxQuantity({ backorderSettings: { autoApproveMaxQuantity: 5 } })).toBe(5);
    expect(resolveAutoApproveMaxQuantity({ backorderSettings: { autoApproveMaxQuantity: 0 } })).toBe(0);
  });

  it('ignores an invalid override', () => {
    expect(
      resolveAutoApproveMaxQuantity({ backorderSettings: { autoApproveMaxQuantity: -1 } }),
    ).toBe(DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY);
    expect(
      resolveAutoApproveMaxQuantity({ backorderSettings: { autoApproveMaxQuantity: 'lots' } }),
    ).toBe(DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY);
  });
});

describe('role grant sets', () => {
  it('lets OWNER/ADMIN/SALES_MANAGER/SALES_REP/CUSTOMER_PORTAL request backorders', () => {
    for (const role of ['OWNER', 'ADMIN', 'SALES_MANAGER', 'SALES_REP', 'CUSTOMER_PORTAL']) {
      expect(ROLES_ALLOWED_TO_REQUEST_BACKORDER.has(role)).toBe(true);
    }
    expect(ROLES_ALLOWED_TO_REQUEST_BACKORDER.has('FINANCE')).toBe(false);
  });

  it('only lets OWNER/ADMIN/SALES_MANAGER decide (approve/reject) a backorder', () => {
    for (const role of ['OWNER', 'ADMIN', 'SALES_MANAGER']) {
      expect(ROLES_ALLOWED_TO_DECIDE_BACKORDER.has(role)).toBe(true);
    }
    for (const role of ['SALES_REP', 'CUSTOMER_PORTAL', 'FINANCE']) {
      expect(ROLES_ALLOWED_TO_DECIDE_BACKORDER.has(role)).toBe(false);
    }
  });

  it('never lets CUSTOMER_PORTAL convert a backorder into a pedido', () => {
    expect(ROLES_ALLOWED_TO_CONVERT_BACKORDER.has('CUSTOMER_PORTAL')).toBe(false);
    expect(ROLES_ALLOWED_TO_CONVERT_BACKORDER.has('SALES_REP')).toBe(true);
  });
});

describe('ensureRequesterMayActOnBackorder', () => {
  const noopTransaction = {
    get: jest.fn(),
  } as unknown as FirebaseFirestore.Transaction;
  const organizationRef = { collection: jest.fn() } as unknown as FirebaseFirestore.DocumentReference;

  it('always allows OWNER/ADMIN, standalone or order-linked', async () => {
    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'OWNER',
        uid: 'someone-else',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        requesterTeamIds: [],
      }),
    ).resolves.toBeUndefined();
  });

  it('lets a SALES_REP act only on their own standalone backorder', async () => {
    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'SALES_REP',
        uid: 'seller-a',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        requesterTeamIds: [],
      }),
    ).resolves.toBeUndefined();

    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'SALES_REP',
        uid: 'seller-b',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        requesterTeamIds: [],
      }),
    ).rejects.toThrow();
  });

  it('lets a CUSTOMER_PORTAL act only on its own standalone customerId', async () => {
    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'CUSTOMER_PORTAL',
        uid: 'portal-user',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        portalCustomerId: 'customer-a',
        requesterTeamIds: [],
      }),
    ).resolves.toBeUndefined();

    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'CUSTOMER_PORTAL',
        uid: 'portal-user',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        portalCustomerId: 'customer-b',
        requesterTeamIds: [],
      }),
    ).rejects.toThrow();
  });

  it('delegates to ensureRequesterMayActOnOrder when a relatedOrder is present', async () => {
    const order = buildOrder({ sellerId: 'seller-a', customerId: 'customer-a' });

    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'SALES_REP',
        uid: 'seller-b',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        requesterTeamIds: [],
        relatedOrder: order,
      }),
    ).rejects.toThrow();

    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'SALES_REP',
        uid: 'seller-a',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        requesterTeamIds: [],
        relatedOrder: order,
      }),
    ).resolves.toBeUndefined();
  });

  it('rejects a role with no standing in the matrix', async () => {
    await expect(
      ensureRequesterMayActOnBackorder(noopTransaction, organizationRef, {
        roleName: 'FINANCE',
        uid: 'someone',
        sellerId: 'seller-a',
        customerId: 'customer-a',
        requesterTeamIds: [],
      }),
    ).rejects.toThrow();
  });
});
