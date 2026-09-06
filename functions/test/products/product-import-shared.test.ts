import {
  assertValidLookup,
  assertValidMapping,
  deriveVariantSku,
  parseEan,
  parseSku,
  validateProductImportRow,
  type ProductImportLookupInput,
} from '../../src/products/product-import-shared';

describe('parseSku', () => {
  it('normalizes to upper case and accepts letters/numbers/separators', () => {
    expect(parseSku('camisa-01')).toBe('CAMISA-01');
    expect(parseSku(' AB_12 ')).toBe('AB_12');
  });

  it('rejects a SKU shorter than 2 characters', () => {
    expect(parseSku('A')).toBeNull();
    expect(parseSku('')).toBeNull();
  });

  it('rejects a SKU longer than 40 characters', () => {
    expect(parseSku('A'.repeat(41))).toBeNull();
  });

  it('rejects a SKU starting/ending with a separator or with invalid characters', () => {
    expect(parseSku('-ABC')).toBeNull();
    expect(parseSku('ABC-')).toBeNull();
    expect(parseSku('AB C')).toBeNull();
    expect(parseSku('AB@C')).toBeNull();
  });
});

describe('parseEan', () => {
  it('accepts a valid EAN-13 regardless of non-digit characters', () => {
    expect(parseEan('4006381333931')).toBe('4006381333931');
    expect(parseEan('400-638-133-3931')).toBe('4006381333931');
  });

  it('accepts a valid EAN-8', () => {
    expect(parseEan('96385074')).toBe('96385074');
  });

  it('rejects an EAN with an incorrect check digit', () => {
    expect(parseEan('4006381333930')).toBeNull();
    expect(parseEan('96385075')).toBeNull();
  });

  it('rejects a value with the wrong number of digits', () => {
    expect(parseEan('123456')).toBeNull();
    expect(parseEan('')).toBeNull();
  });
});

describe('deriveVariantSku', () => {
  it('joins productSku/colorCode/sizeLabel when short enough', () => {
    expect(
      deriveVariantSku({
        productSku: 'CAMISA-01',
        colorCode: 'AZ',
        colorId: 'color-1',
        sizeLabel: 'M',
        sizeId: 'size-1',
      }),
    ).toBe('CAMISA-01-AZ-M');
  });

  it('sanitizes non alphanumeric characters in color/size into a single dash', () => {
    expect(
      deriveVariantSku({
        productSku: 'CAMISA-01',
        colorCode: 'Azul Royal',
        colorId: 'color-1',
        sizeLabel: 'G1',
        sizeId: 'size-1',
      }),
    ).toBe('CAMISA-01-AZUL-ROYAL-G1');
  });

  it('falls back to ids when the human-readable form exceeds 40 characters', () => {
    const params = {
      productSku: 'CAMISA-REFERENCIA-MUITO-LONGA-0001',
      colorCode: 'AZUL-MARINHO-ESCURO',
      colorId: 'color-1',
      sizeLabel: 'GG',
      sizeId: 'size-1',
    };
    const humanReadable = `${params.productSku}-${params.colorCode}-${params.sizeLabel}`;
    expect(humanReadable.length).toBeGreaterThan(40);

    const sku = deriveVariantSku(params);
    expect(sku.length).toBeLessThanOrEqual(40);
    expect(sku).toBe(
      `${params.productSku}-${params.colorId}-${params.sizeId}`.slice(0, 40),
    );
  });
});

describe('assertValidMapping', () => {
  const validMapping = {
    hasHeaderRow: true,
    columnByField: {
      sku: 0,
      reference: 1,
      name: 2,
      colorName: 3,
      sizeLabel: 4,
    },
    sizeGridTemplateId: 'grid-1',
  };

  it('accepts a mapping with every required field and a size grid', () => {
    expect(assertValidMapping(validMapping)).toEqual(validMapping);
  });

  it('rejects a mapping missing a required field', () => {
    const columnByField: Record<string, number> = {};
    for (const [field, column] of Object.entries(validMapping.columnByField)) {
      if (field !== 'colorName') columnByField[field] = column;
    }
    expect(() =>
      assertValidMapping({ ...validMapping, columnByField }),
    ).toThrow(/colorName/);
  });

  it('rejects a mapping without a sizeGridTemplateId', () => {
    expect(() =>
      assertValidMapping({ ...validMapping, sizeGridTemplateId: '' }),
    ).toThrow();
  });

  it('rejects an unknown field code', () => {
    expect(() =>
      assertValidMapping({
        ...validMapping,
        columnByField: { ...validMapping.columnByField, notAField: 5 },
      }),
    ).toThrow(/notAField/);
  });
});

describe('assertValidLookup', () => {
  it('accepts a lookup with every map present (even if empty)', () => {
    const lookup = {
      categoryIdByName: {},
      collectionIdByName: {},
      colorIdByName: { azul: 'color-1' },
      sizeIdByLabel: { m: 'size-1' },
    };
    expect(assertValidLookup(lookup)).toEqual(lookup);
  });

  it('rejects a lookup missing a map', () => {
    expect(() =>
      assertValidLookup({ categoryIdByName: {}, collectionIdByName: {} }),
    ).toThrow();
  });
});

describe('validateProductImportRow', () => {
  const lookup: ProductImportLookupInput = {
    categoryIdByName: { camisaria: 'category-1' },
    collectionIdByName: { 'verao 2026': 'collection-1' },
    colorIdByName: { azul: 'color-1' },
    sizeIdByLabel: { m: 'size-1' },
  };

  const validRaw = {
    sku: 'camisa-01',
    reference: 'REF-01',
    name: 'Camisa Social',
    colorName: 'Azul',
    sizeLabel: 'M',
    categoryName: 'Camisaria',
    collectionName: 'Verao 2026',
    basePrice: '99,90',
    barcode: '4006381333931',
  };

  it('accepts a fully valid row and resolves color/size/category/collection ids', () => {
    const result = validateProductImportRow(validRaw, lookup);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.fields.colorId).toBe('color-1');
      expect(result.fields.sizeId).toBe('size-1');
      expect(result.fields.basePrice).toBeCloseTo(99.9);
      expect(result.fields.ean).toBe('4006381333931');
    }
  });

  it('rejects a row with an invalid SKU', () => {
    const result = validateProductImportRow({ ...validRaw, sku: '' }, lookup);
    expect(result.ok).toBe(false);
  });

  it('rejects a row whose color is not in the lookup', () => {
    const result = validateProductImportRow(
      { ...validRaw, colorName: 'Verde' },
      lookup,
    );
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toMatch(/Cor/);
  });

  it('rejects a row whose size is not in the selected grid', () => {
    const result = validateProductImportRow(
      { ...validRaw, sizeLabel: 'XG' },
      lookup,
    );
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toMatch(/Tamanho/);
  });

  it('rejects a row whose categoria is not registered', () => {
    const result = validateProductImportRow(
      { ...validRaw, categoryName: 'Inexistente' },
      lookup,
    );
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toMatch(/Categoria/);
  });

  it('rejects a row with an invalid base price', () => {
    const result = validateProductImportRow(
      { ...validRaw, basePrice: 'abacate' },
      lookup,
    );
    expect(result.ok).toBe(false);
  });

  it('rejects a row with an invalid barcode', () => {
    const result = validateProductImportRow(
      { ...validRaw, barcode: '1234567890123' },
      lookup,
    );
    expect(result.ok).toBe(false);
  });

  it('accepts a row without optional fields (category/collection/price/barcode)', () => {
    const result = validateProductImportRow(
      {
        sku: 'camisa-02',
        reference: 'REF-02',
        name: 'Camisa Basica',
        colorName: 'Azul',
        sizeLabel: 'M',
      },
      lookup,
    );
    expect(result.ok).toBe(true);
  });
});
