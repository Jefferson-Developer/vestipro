import { HttpsError } from 'firebase-functions/v2/https';

import {
  ErpAdapterRegistry,
  buildDefaultErpAdapterRegistry,
} from '../../../src/erp_integration/adapters/erp-adapter-registry';
import type {
  ErpAdapter,
  ErpIntegrationConfig,
  ErpIntegrationCredentials,
  ErpPushCustomerInput,
  ErpPushOrderInput,
} from '../../../src/erp_integration/types';

class FakeConcreteErpAdapter implements ErpAdapter {
  readonly adapterType = 'fake_concrete_erp';
  pullInventory = jest.fn().mockResolvedValue([]);
  pullPrices = jest.fn().mockResolvedValue([]);
  pushOrder = jest
    .fn()
    .mockImplementation(async (_c: unknown, _cred: unknown, input: ErpPushOrderInput) => ({
      externalId: `fake-${input.orderId}`,
    }));
  pushCustomer = jest
    .fn()
    .mockImplementation(async (_c: unknown, _cred: unknown, input: ErpPushCustomerInput) => ({
      externalId: `fake-${input.customerId}`,
    }));
}

describe('ErpAdapterRegistry', () => {
  it('ships with the reference GenericRestErpAdapter registered by default', () => {
    const registry = buildDefaultErpAdapterRegistry();
    expect(registry.has('generic_rest')).toBe(true);
    expect(registry.resolve('generic_rest').adapterType).toBe('generic_rest');
  });

  it('throws a clear error for an adapterType nobody registered', () => {
    const registry = new ErpAdapterRegistry();
    expect(() => registry.resolve('unknown_erp')).toThrow(HttpsError);
  });

  it('supports adding a brand-new concrete ERP adapter without touching '
    + 'the registry class itself or any other adapter (TASK-169 acceptance '
    + 'criterion: "arquitetura permite adicionar um novo adapter... sem '
    + 'reescrever o núcleo")', async () => {
    const registry = new ErpAdapterRegistry();
    registry.register(new FakeConcreteErpAdapter());

    const adapter = registry.resolve('fake_concrete_erp');
    const result = await adapter.pushOrder(
      {} as ErpIntegrationConfig,
      {} as ErpIntegrationCredentials,
      { organizationId: 'org-1', orderId: 'order-9', externalCustomerId: null, payload: {} },
    );
    expect(result).toEqual({ externalId: 'fake-order-9' });
  });
});
