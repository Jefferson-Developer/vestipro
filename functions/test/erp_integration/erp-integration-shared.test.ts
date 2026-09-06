import { HttpsError } from 'firebase-functions/v2/https';

import {
  ERP_INTEGRATION_ROLES,
  applyFieldMapping,
  assertCanManageErpIntegration,
  computeIdempotencyKey,
  erpConflictPolicyFor,
  isInboundErpEntityType,
  nextRetryDelayMinutes,
  validateFieldMappingConfig,
  MAX_SYNC_ATTEMPTS,
} from '../../src/erp_integration/erp-integration-shared';

describe('assertCanManageErpIntegration', () => {
  it('allows only OWNER/ADMIN', () => {
    expect(ERP_INTEGRATION_ROLES.has('OWNER')).toBe(true);
    expect(ERP_INTEGRATION_ROLES.has('ADMIN')).toBe(true);
    expect(() => assertCanManageErpIntegration('OWNER')).not.toThrow();
    expect(() => assertCanManageErpIntegration('ADMIN')).not.toThrow();
  });

  it.each(['SALES_MANAGER', 'SALES_REP', 'SALES_ASSISTANT', 'FINANCE', 'READ_ONLY'])(
    'denies %s',
    (roleName) => {
      expect(() => assertCanManageErpIntegration(roleName)).toThrow(HttpsError);
    },
  );
});

describe('erpConflictPolicyFor', () => {
  it('is exhaustive and deterministic for every InboundErpEntityType', () => {
    expect(erpConflictPolicyFor('customer')).toBe('field_merge');
    expect(erpConflictPolicyFor('inventory')).toBe('last_write_wins');
    expect(erpConflictPolicyFor('price')).toBe('last_write_wins');
  });

  it('never resolves customer conflicts automatically as last_write_wins '
    + '(mirrors ConflictPolicyCatalog.customer => fieldMerge, Dart, TASK-110)', () => {
    expect(erpConflictPolicyFor('customer')).not.toBe('last_write_wins');
    expect(erpConflictPolicyFor('customer')).not.toBe('manual_resolution');
  });
});

describe('validateFieldMappingConfig', () => {
  it('accepts an empty/absent mapping', () => {
    expect(validateFieldMappingConfig(undefined)).toEqual({});
    expect(validateFieldMappingConfig(null)).toEqual({});
  });

  it('accepts a mapping whose target fields are all in the whitelist', () => {
    const result = validateFieldMappingConfig({
      customer: { codigo_cliente: 'document', razao_social: 'legalName' },
      inventory: { qtd_disponivel: 'erpQuantityOnHand' },
    });
    expect(result).toEqual({
      customer: { codigo_cliente: 'document', razao_social: 'legalName' },
      inventory: { qtd_disponivel: 'erpQuantityOnHand' },
    });
  });

  it('rejects an unknown entity type', () => {
    expect(() => validateFieldMappingConfig({ order: { total: 'amount' } })).toThrow(
      HttpsError,
    );
  });

  it('rejects a mapping targeting a field outside the whitelist for that '
    + 'entity — the "no-code" mapping is never a way to reach an arbitrary/'
    + 'sensitive field', () => {
    expect(() =>
      validateFieldMappingConfig({ customer: { qualquer: 'organizationId' } }),
    ).toThrow(HttpsError);
    expect(() =>
      validateFieldMappingConfig({ inventory: { estoque: 'quantityOnHand' } }),
    ).toThrow(HttpsError);
    expect(() =>
      validateFieldMappingConfig({ price: { preco: 'basePrice' } }),
    ).toThrow(HttpsError);
  });

  it('rejects a malformed shape', () => {
    expect(() => validateFieldMappingConfig('not-an-object')).toThrow(HttpsError);
    expect(() => validateFieldMappingConfig({ customer: 'not-an-object' })).toThrow(
      HttpsError,
    );
  });
});

describe('applyFieldMapping', () => {
  it('translates only the erp fields present in both the mapping and the '
    + 'raw record', () => {
    const mapped = applyFieldMapping(
      { codigo_cliente: 'document', razao_social: 'legalName' },
      { codigo_cliente: '11111111000191', outroCampo: 'ignorado' },
    );
    expect(mapped).toEqual({ document: '11111111000191' });
  });

  it('ignores erp fields absent from the mapping and never invents a '
    + 'value for a mapped field the raw record does not have', () => {
    const mapped = applyFieldMapping(
      { codigo_cliente: 'document' },
      { outroCampo: 'x' },
    );
    expect(mapped).toEqual({});
  });
});

describe('computeIdempotencyKey / isInboundErpEntityType', () => {
  it('is deterministic for the exact same input', () => {
    const input = {
      organizationId: 'org-1',
      direction: 'inbound',
      entityType: 'inventory',
      externalId: 'SKU-123',
      sourceVersion: '2026-01-01T00:00:00Z',
    };
    expect(computeIdempotencyKey(input)).toBe(computeIdempotencyKey({ ...input }));
  });

  it('changes when the organization changes, so two tenants never collide '
    + 'even for the exact same ERP record', () => {
    const base = {
      direction: 'inbound',
      entityType: 'inventory',
      externalId: 'SKU-123',
      sourceVersion: 'v1',
    };
    expect(computeIdempotencyKey({ organizationId: 'org-1', ...base })).not.toBe(
      computeIdempotencyKey({ organizationId: 'org-2', ...base }),
    );
  });

  it('changes when sourceVersion changes, so a real ERP-side update is '
    + 'never mistaken for an already-processed event', () => {
    const base = {
      organizationId: 'org-1',
      direction: 'inbound',
      entityType: 'price',
      externalId: 'SKU-123',
    };
    expect(computeIdempotencyKey({ ...base, sourceVersion: 'v1' })).not.toBe(
      computeIdempotencyKey({ ...base, sourceVersion: 'v2' }),
    );
  });

  it('classifies inbound entity types correctly and excludes "order"', () => {
    expect(isInboundErpEntityType('customer')).toBe(true);
    expect(isInboundErpEntityType('inventory')).toBe(true);
    expect(isInboundErpEntityType('price')).toBe(true);
    expect(isInboundErpEntityType('order')).toBe(false);
  });
});

describe('nextRetryDelayMinutes', () => {
  it('increases with more attempts, up to the backoff table length', () => {
    expect(nextRetryDelayMinutes(1)).toBe(5);
    expect(nextRetryDelayMinutes(2)).toBe(15);
    expect(nextRetryDelayMinutes(MAX_SYNC_ATTEMPTS)).toBe(1440);
    // Beyond the table, caps at the last (longest) backoff.
    expect(nextRetryDelayMinutes(MAX_SYNC_ATTEMPTS + 10)).toBe(1440);
  });
});
