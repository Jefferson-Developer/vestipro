import {
  assertValidMapping,
  extractRawValues,
  isValidEmail,
  parseCep,
  parseCnpjCpf,
  validateCustomerImportRow,
} from '../../src/customers/customer-import-shared';

describe('parseCnpjCpf', () => {
  it('accepts a valid CPF regardless of mask', () => {
    expect(parseCnpjCpf('529.982.247-25')).toEqual({
      digits: '52998224725',
      type: 'individual',
    });
    expect(parseCnpjCpf('52998224725')).toEqual({
      digits: '52998224725',
      type: 'individual',
    });
  });

  it('accepts a valid CNPJ regardless of mask', () => {
    expect(parseCnpjCpf('11.222.333/0001-81')).toEqual({
      digits: '11222333000181',
      type: 'legalEntity',
    });
  });

  it('rejects a CPF with invalid check digits', () => {
    expect(parseCnpjCpf('529.982.247-26')).toBeNull();
  });

  it('rejects a CNPJ with invalid check digits', () => {
    expect(parseCnpjCpf('11.222.333/0001-82')).toBeNull();
  });

  it('rejects an all-repeated-digits CPF/CNPJ (never a real document)', () => {
    expect(parseCnpjCpf('111.111.111-11')).toBeNull();
    expect(parseCnpjCpf('11.111.111/1111-11')).toBeNull();
  });

  it('rejects a document with the wrong number of digits', () => {
    expect(parseCnpjCpf('123456')).toBeNull();
    expect(parseCnpjCpf('')).toBeNull();
  });
});

describe('parseCep', () => {
  it('accepts a valid 8-digit CEP regardless of mask', () => {
    expect(parseCep('01310-100')).toBe('01310100');
  });

  it('rejects an all-repeated-digits CEP', () => {
    expect(parseCep('11111-111')).toBeNull();
  });

  it('rejects a CEP with the wrong length', () => {
    expect(parseCep('123')).toBeNull();
  });
});

describe('isValidEmail', () => {
  it('accepts a well-formed e-mail', () => {
    expect(isValidEmail('contato@empresa.com.br')).toBe(true);
  });

  it('rejects a malformed e-mail', () => {
    expect(isValidEmail('contato@empresa')).toBe(false);
    expect(isValidEmail('contato empresa.com')).toBe(false);
  });
});

describe('assertValidMapping', () => {
  it('accepts a mapping with document and at least one name field', () => {
    expect(
      assertValidMapping({
        hasHeaderRow: true,
        columnByField: { document: 0, legalName: 1 },
      }),
    ).toEqual({ hasHeaderRow: true, columnByField: { document: 0, legalName: 1 } });
  });

  it('rejects a mapping missing the document column', () => {
    expect(() =>
      assertValidMapping({ hasHeaderRow: true, columnByField: { legalName: 0 } }),
    ).toThrow(/document/);
  });

  it('rejects a mapping with no name column at all', () => {
    expect(() =>
      assertValidMapping({ hasHeaderRow: true, columnByField: { document: 0 } }),
    ).toThrow(/nome/);
  });

  it('rejects an unknown field code (never trusts the client blindly)', () => {
    expect(() =>
      assertValidMapping({
        hasHeaderRow: true,
        columnByField: { document: 0, legalName: 1, notARealField: 2 },
      }),
    ).toThrow();
  });

  it('rejects a malformed mapping shape', () => {
    expect(() => assertValidMapping(null)).toThrow();
    expect(() => assertValidMapping('not-an-object')).toThrow();
  });
});

describe('extractRawValues', () => {
  it('extracts and trims only the mapped columns, out of order', () => {
    const row = ['  Acme Ltda  ', '11.222.333/0001-81', 'contato@acme.com'];
    const raw = extractRawValues(row, { legalName: 0, document: 1, primaryEmail: 2 });
    expect(raw).toEqual({
      legalName: 'Acme Ltda',
      document: '11.222.333/0001-81',
      primaryEmail: 'contato@acme.com',
    });
  });

  it('defaults a missing/undefined cell to an empty string', () => {
    const raw = extractRawValues(['only one cell'], { document: 0, legalName: 5 });
    expect(raw.legalName).toBe('');
  });
});

describe('validateCustomerImportRow', () => {
  it('accepts a valid legal-entity row (CNPJ + razão social)', () => {
    const result = validateCustomerImportRow({
      document: '11.222.333/0001-81',
      legalName: 'Acme Ltda',
      primaryEmail: 'contato@acme.com',
    });
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.fields.documentDigits).toBe('11222333000181');
      expect(result.fields.documentType).toBe('legalEntity');
      expect(result.fields.legalName).toBe('Acme Ltda');
      expect(result.fields.primaryEmail).toBe('contato@acme.com');
    }
  });

  it('falls back to nome fantasia when razão social is blank for a CNPJ', () => {
    const result = validateCustomerImportRow({
      document: '11.222.333/0001-81',
      legalName: '',
      tradeName: 'Acme Store',
    });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.fields.legalName).toBe('Acme Store');
  });

  it('accepts a valid individual row (CPF + nome completo)', () => {
    const result = validateCustomerImportRow({
      document: '529.982.247-25',
      fullName: 'Maria Silva',
    });
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.fields.documentType).toBe('individual');
      expect(result.fields.fullName).toBe('Maria Silva');
    }
  });

  it('rejects a row missing the document entirely', () => {
    const result = validateCustomerImportRow({ legalName: 'Acme Ltda' });
    expect(result.ok).toBe(false);
  });

  it('rejects a row with an invalid CNPJ/CPF', () => {
    const result = validateCustomerImportRow({
      document: '00.000.000/0000-00',
      legalName: 'Acme Ltda',
    });
    expect(result.ok).toBe(false);
  });

  it('rejects a CNPJ row with neither razão social nor nome fantasia', () => {
    const result = validateCustomerImportRow({ document: '11.222.333/0001-81' });
    expect(result.ok).toBe(false);
  });

  it('rejects a CPF row without nome completo', () => {
    const result = validateCustomerImportRow({ document: '529.982.247-25' });
    expect(result.ok).toBe(false);
  });

  it('rejects a row with a malformed e-mail', () => {
    const result = validateCustomerImportRow({
      document: '529.982.247-25',
      fullName: 'Maria Silva',
      primaryEmail: 'not-an-email',
    });
    expect(result.ok).toBe(false);
  });

  it('drops an incomplete address instead of rejecting the row', () => {
    const result = validateCustomerImportRow({
      document: '529.982.247-25',
      fullName: 'Maria Silva',
      addressStreet: 'Rua das Flores',
      // city/state/zip intentionally missing
    });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.fields.address).toBeNull();
  });

  it('builds a complete address block when every address field is valid', () => {
    const result = validateCustomerImportRow({
      document: '529.982.247-25',
      fullName: 'Maria Silva',
      addressStreet: 'Rua das Flores',
      addressNumber: '123',
      addressCity: 'São Paulo',
      addressState: 'SP',
      addressZipCode: '01310-100',
    });
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.fields.address).toEqual({
        street: 'Rua das Flores',
        number: '123',
        complement: null,
        district: null,
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01310100',
      });
    }
  });

  it('drops the address when the CEP is invalid, without rejecting the row', () => {
    const result = validateCustomerImportRow({
      document: '529.982.247-25',
      fullName: 'Maria Silva',
      addressStreet: 'Rua das Flores',
      addressCity: 'São Paulo',
      addressState: 'SP',
      addressZipCode: '11111-111',
    });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.fields.address).toBeNull();
  });
});
