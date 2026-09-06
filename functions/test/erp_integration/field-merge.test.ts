import { computeErpFieldMerge } from '../../src/erp_integration/field-merge';

describe('computeErpFieldMerge', () => {
  it('merges changes on disjoint fields without conflict', () => {
    const result = computeErpFieldMerge({
      base: { legalName: 'Malwee LTDA', addressCity: 'Jaraguá do Sul' },
      local: { legalName: 'Malwee Malhas LTDA', addressCity: 'Jaraguá do Sul' },
      remote: { legalName: 'Malwee LTDA', addressCity: 'Blumenau' },
    });

    expect(result.conflictingFields.size).toBe(0);
    expect(result.mergedData).toEqual({
      legalName: 'Malwee Malhas LTDA',
      addressCity: 'Blumenau',
    });
    expect(result.mergedFields.has('legalName')).toBe(true);
    expect(result.mergedFields.has('addressCity')).toBe(false);
  });

  it('reports a conflict instead of silently merging when the same field '
    + 'changed on both sides to different values', () => {
    const result = computeErpFieldMerge({
      base: { tradeName: 'Malwee' },
      local: { tradeName: 'Malwee Kids' },
      remote: { tradeName: 'Malwee Adulto' },
    });

    expect(result.conflictingFields.has('tradeName')).toBe(true);
    expect(result.mergedData).toEqual({});
    expect(result.mergedFields.size).toBe(0);
  });

  it('is not a conflict when both sides change the same field to the same '
    + 'value', () => {
    const result = computeErpFieldMerge({
      base: { document: '00000000000191' },
      local: { document: '11111111000191' },
      remote: { document: '11111111000191' },
    });

    expect(result.conflictingFields.size).toBe(0);
    expect(result.mergedData.document).toBe('11111111000191');
  });

  it('blocks the entire merge (not just the conflicting field) once any '
    + 'field conflicts, mirroring ConflictFieldMerge.compute (Dart, '
    + 'TASK-110)', () => {
    const result = computeErpFieldMerge({
      base: { a: '1', b: '1' },
      local: { a: '2', b: '2' },
      remote: { a: '2', b: '3' },
    });

    // `a` changed identically on both sides (no conflict by itself), but
    // `b` conflicts — the whole merge must be blocked, `a` is never applied
    // in isolation.
    expect(result.conflictingFields.has('b')).toBe(true);
    expect(result.mergedData).toEqual({});
  });

  it('treats a field absent from base as null there, so a field newly '
    + 'introduced identically on both sides is not a conflict', () => {
    const result = computeErpFieldMerge({
      base: {},
      local: { stateRegistration: 'ISENTO' },
      remote: { stateRegistration: 'ISENTO' },
    });

    expect(result.conflictingFields.size).toBe(0);
    expect(result.mergedData.stateRegistration).toBe('ISENTO');
  });
});
