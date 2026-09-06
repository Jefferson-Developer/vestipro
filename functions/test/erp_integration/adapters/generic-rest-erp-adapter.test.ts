import { HttpsError } from 'firebase-functions/v2/https';

import { GenericRestErpAdapter } from '../../../src/erp_integration/adapters/generic-rest-erp-adapter';
import type {
  ErpIntegrationConfig,
  ErpIntegrationCredentials,
} from '../../../src/erp_integration/types';

function jsonResponse(body: unknown, ok = true, status = 200): Response {
  return {
    ok,
    status,
    json: async () => body,
  } as unknown as Response;
}

function buildConfig(
  overrides: Partial<ErpIntegrationConfig> = {},
): ErpIntegrationConfig {
  return {
    organizationId: 'org-1',
    adapterType: 'generic_rest',
    enabledEntityTypes: ['inventory', 'price'],
    fieldMappings: {},
    connection: {
      baseUrl: 'https://mock-erp.example.com',
      inventoryEndpoint: '/estoque',
      priceEndpoint: '/precos',
      orderEndpoint: '/pedidos',
      customerEndpoint: '/clientes',
    },
    isActive: true,
    ...overrides,
  };
}

const credentials: ErpIntegrationCredentials = {
  organizationId: 'org-1',
  secrets: { bearerToken: 'super-secret-token' },
};

describe('GenericRestErpAdapter (reference ErpAdapter implementation)', () => {
  it('pulls inventory records from the configured endpoint with bearer auth', async () => {
    const fetchMock = jest.fn().mockResolvedValue(
      jsonResponse([
        { id: 'SKU-1', quantidade: 10, dataAtualizacao: '2026-01-01' },
        { id: 'SKU-2', quantidade: 0, dataAtualizacao: '2026-01-02' },
      ]),
    );
    const adapter = new GenericRestErpAdapter(fetchMock as unknown as typeof fetch);

    const records = await adapter.pullInventory(buildConfig(), credentials);

    expect(fetchMock).toHaveBeenCalledWith(
      'https://mock-erp.example.com/estoque',
      expect.objectContaining({
        method: 'GET',
        headers: expect.objectContaining({
          Authorization: 'Bearer super-secret-token',
        }),
      }),
    );
    expect(records).toEqual([
      {
        externalId: 'SKU-1',
        rawFields: { id: 'SKU-1', quantidade: 10, dataAtualizacao: '2026-01-01' },
        sourceVersion: '2026-01-01',
      },
      {
        externalId: 'SKU-2',
        rawFields: { id: 'SKU-2', quantidade: 0, dataAtualizacao: '2026-01-02' },
        sourceVersion: '2026-01-02',
      },
    ]);
  });

  it('pushes an order to the configured endpoint and returns the ERP-assigned id', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValue(jsonResponse({ id: 'ERP-ORDER-99' }));
    const adapter = new GenericRestErpAdapter(fetchMock as unknown as typeof fetch);

    const result = await adapter.pushOrder(buildConfig(), credentials, {
      organizationId: 'org-1',
      orderId: 'order-1',
      externalCustomerId: 'ERP-CUST-1',
      payload: { total: 100 },
    });

    expect(result).toEqual({ externalId: 'ERP-ORDER-99' });
    expect(fetchMock).toHaveBeenCalledWith(
      'https://mock-erp.example.com/pedidos',
      expect.objectContaining({ method: 'POST', body: JSON.stringify({ total: 100 }) }),
    );
  });

  it('throws when the ERP responds with a non-2xx status, never silently '
    + 'swallowing a failed pull', async () => {
    const fetchMock = jest.fn().mockResolvedValue(jsonResponse(null, false, 500));
    const adapter = new GenericRestErpAdapter(fetchMock as unknown as typeof fetch);

    await expect(adapter.pullPrices(buildConfig(), credentials)).rejects.toThrow(
      HttpsError,
    );
  });

  it('throws when the configured connection is missing a required endpoint', async () => {
    const adapter = new GenericRestErpAdapter(jest.fn() as unknown as typeof fetch);
    const config = buildConfig({ connection: { baseUrl: 'https://mock-erp.example.com' } });

    await expect(adapter.pullInventory(config, credentials)).rejects.toThrow(
      HttpsError,
    );
  });

  it('throws when credentials are missing the bearer token, never sending '
    + 'an unauthenticated request', async () => {
    const fetchMock = jest.fn();
    const adapter = new GenericRestErpAdapter(fetchMock as unknown as typeof fetch);

    await expect(
      adapter.pullInventory(buildConfig(), { organizationId: 'org-1', secrets: {} }),
    ).rejects.toThrow(HttpsError);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
