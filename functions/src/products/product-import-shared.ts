import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

/**
 * Shared by every product-import Cloud Function (TASK-168:
 * `startProductImportJob`, `processProductImportJob`) — mirrors
 * `customer-import-shared.ts` (TASK-167)'s rationale: RBAC, the field
 * vocabulary and row-validation rules are defined exactly once.
 *
 * `Sku`/`Ean` validation below are intentional TypeScript ports of
 * `lib/features/products/domain/value_objects/sku.dart`/`ean.dart`
 * (TASK-064), kept algorithm-for-algorithm identical so a value accepted/
 * rejected client-side is never accepted/rejected differently here. The
 * variant-SKU derivation mirrors
 * `GenerateProductVariantsUseCase._deriveSku` (Dart, TASK-072) exactly, so a
 * variant created by this import is indistinguishable from one the app's own
 * "gerar variantes" action would have produced for the same product/color/
 * size.
 */

/** Mirrors `Capability.productImport`
 * (`lib/core/permissions/capability.dart`) — granted only to OWNER/ADMIN
 * (`RolePermissionMatrix`'s full/near-full sets), unlike
 * `CUSTOMER_IMPORT_ROLES` which also includes SALES_MANAGER: bulk catalog
 * creation stays with whoever already manages the catalog
 * (`Capability.catalogManage`'s same scope). */
export const PRODUCT_IMPORT_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

export function assertCanImportProducts(roleName: string): void {
  if (!PRODUCT_IMPORT_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode importar produtos.',
    );
  }
}

/** Mirrors `kProductImportMaxFileSizeBytes` (Flutter). */
export const MAX_IMPORT_FILE_SIZE_BYTES = 15 * 1024 * 1024;

/** Same defense-in-depth ceiling as `MAX_IMPORT_ROWS` (customers, TASK-167)
 * — a larger catalog needs to be split across multiple import jobs. */
export const MAX_IMPORT_ROWS = 20_000;

export const PRODUCT_IMPORT_FIELD_CODES: ReadonlySet<string> = new Set<
  string
>([
  'sku',
  'reference',
  'name',
  'shortDescription',
  'brand',
  'categoryName',
  'subcategoryName',
  'collectionName',
  'colorName',
  'sizeLabel',
  'basePrice',
  'barcode',
]);

const REQUIRED_PRODUCT_IMPORT_FIELDS: ReadonlySet<string> = new Set<string>([
  'sku',
  'reference',
  'name',
  'colorName',
  'sizeLabel',
]);

export interface ProductImportMappingInput {
  hasHeaderRow: boolean;
  columnByField: Record<string, number>;
  sizeGridTemplateId: string;
}

/** Validates the shape of a mapping sent to `startProductImportJob` —
 * mirrors `validateProductImportMapping` (Flutter), re-checked here since a
 * forged/stale client mapping must never be trusted. */
export function assertValidMapping(
  mapping: unknown,
): ProductImportMappingInput {
  if (
    typeof mapping !== 'object' ||
    mapping === null ||
    typeof (mapping as Record<string, unknown>).hasHeaderRow !== 'boolean' ||
    typeof (mapping as Record<string, unknown>).columnByField !== 'object' ||
    typeof (mapping as Record<string, unknown>).sizeGridTemplateId !==
      'string' ||
    ((mapping as Record<string, unknown>).sizeGridTemplateId as string).trim()
      .length === 0
  ) {
    throw new HttpsError('invalid-argument', 'mapping é obrigatório e inválido.');
  }
  const columnByField = (mapping as Record<string, unknown>).columnByField as Record<
    string,
    unknown
  >;
  const parsed: Record<string, number> = {};
  for (const [field, column] of Object.entries(columnByField)) {
    if (!PRODUCT_IMPORT_FIELD_CODES.has(field) || typeof column !== 'number') {
      throw new HttpsError('invalid-argument', `Campo de mapeamento inválido: ${field}.`);
    }
    parsed[field] = column;
  }
  for (const required of REQUIRED_PRODUCT_IMPORT_FIELDS) {
    if (!(required in parsed)) {
      throw new HttpsError(
        'invalid-argument',
        `O mapeamento precisa incluir uma coluna para "${required}".`,
      );
    }
  }
  return {
    hasHeaderRow: (mapping as Record<string, unknown>).hasHeaderRow as boolean,
    columnByField: parsed,
    sizeGridTemplateId: (
      (mapping as Record<string, unknown>).sizeGridTemplateId as string
    ).trim(),
  };
}

export interface ProductImportLookupInput {
  categoryIdByName: Record<string, string>;
  collectionIdByName: Record<string, string>;
  colorIdByName: Record<string, string>;
  sizeIdByLabel: Record<string, string>;
}

function assertStringRecord(value: unknown, field: string): Record<string, string> {
  if (typeof value !== 'object' || value === null) {
    throw new HttpsError('invalid-argument', `lookup.${field} é obrigatório e inválido.`);
  }
  const parsed: Record<string, string> = {};
  for (const [key, entry] of Object.entries(value as Record<string, unknown>)) {
    if (typeof entry !== 'string') {
      throw new HttpsError('invalid-argument', `lookup.${field} é inválido.`);
    }
    parsed[key] = entry;
  }
  return parsed;
}

/** Validates the shape of the client-resolved name/label -> id lookup sent
 * to `startProductImportJob` — see `ProductImportLookup` (Flutter)'s docs
 * for why this resolution can only happen client-side today
 * (Category/Collection/ProductColor/SizeGridTemplate have no remote/
 * Firestore-backed store yet). */
export function assertValidLookup(lookup: unknown): ProductImportLookupInput {
  if (typeof lookup !== 'object' || lookup === null) {
    throw new HttpsError('invalid-argument', 'lookup é obrigatório e inválido.');
  }
  const data = lookup as Record<string, unknown>;
  return {
    categoryIdByName: assertStringRecord(data.categoryIdByName, 'categoryIdByName'),
    collectionIdByName: assertStringRecord(
      data.collectionIdByName,
      'collectionIdByName',
    ),
    colorIdByName: assertStringRecord(data.colorIdByName, 'colorIdByName'),
    sizeIdByLabel: assertStringRecord(data.sizeIdByLabel, 'sizeIdByLabel'),
  };
}

/** Extracts the raw, trimmed text of every mapped field from one parsed
 * spreadsheet [row] — mirrors `extractRawValues` (customers, TASK-167). */
export function extractRawValues(
  row: readonly unknown[],
  columnByField: Record<string, number>,
): Record<string, string> {
  const raw: Record<string, string> = {};
  for (const [field, column] of Object.entries(columnByField)) {
    const cell = row[column];
    raw[field] = cell === null || cell === undefined ? '' : String(cell).trim();
  }
  return raw;
}

// ---------------------------------------------------------------------
// Sku (mirrors lib/features/products/domain/value_objects/sku.dart)
// ---------------------------------------------------------------------

const SKU_FORMAT_PATTERN = /^[A-Z0-9]+(?:[_-][A-Z0-9]+)*$/;

/** Normalizes+validates a raw SKU exactly like `Sku.parse` (Dart). Returns
 * `null` (never throws) for anything invalid — a single bad row must never
 * interrupt the batch. */
export function parseSku(raw: string): string | null {
  const normalized = raw.trim().toUpperCase();
  if (normalized.length < 2 || normalized.length > 40) return null;
  if (!SKU_FORMAT_PATTERN.test(normalized)) return null;
  return normalized;
}

function skuSegment(value: string): string {
  const normalized = value
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return normalized.length === 0 ? 'UNICO' : normalized;
}

/** Derives a variant SKU exactly like `GenerateProductVariantsUseCase
 * ._deriveSku` (Dart, TASK-072): `{productSku}-{colorCode}-{sizeLabel}`,
 * falling back to ids when the human-readable form would exceed 40 chars. */
export function deriveVariantSku(params: {
  productSku: string;
  colorCode: string;
  colorId: string;
  sizeLabel: string;
  sizeId: string;
}): string {
  const raw = `${params.productSku}-${skuSegment(params.colorCode)}-${skuSegment(
    params.sizeLabel,
  )}`;
  if (raw.length <= 40) return raw;
  const compact = `${params.productSku}-${params.colorId}-${params.sizeId}`;
  return compact.length <= 40 ? compact : compact.slice(0, 40);
}

// ---------------------------------------------------------------------
// Ean (mirrors lib/features/products/domain/value_objects/ean.dart)
// ---------------------------------------------------------------------

function digitAt(digits: string, index: number): number {
  return digits.charCodeAt(index) - 48;
}

function hasValidEanCheckDigit(digits: string): boolean {
  let sum = 0;
  for (let offset = 1; offset < digits.length; offset += 1) {
    const digit = digitAt(digits, digits.length - 1 - offset);
    const weight = offset % 2 === 1 ? 3 : 1;
    sum += digit * weight;
  }
  const expected = (10 - (sum % 10)) % 10;
  return digitAt(digits, digits.length - 1) === expected;
}

/** Normalizes+validates a raw EAN-8/EAN-13 exactly like `Ean.parse` (Dart).
 * Returns `null` (never throws) for anything invalid. */
export function parseEan(raw: string): string | null {
  const digits = raw.replace(/\D/g, '');
  if (digits.length !== 13 && digits.length !== 8) return null;
  if (!hasValidEanCheckDigit(digits)) return null;
  return digits;
}

// ---------------------------------------------------------------------
// Row validation
// ---------------------------------------------------------------------

export interface ProductImportRowFields {
  sku: string;
  reference: string;
  name: string | null;
  shortDescription: string | null;
  brand: string | null;
  categoryName: string | null;
  subcategoryName: string | null;
  collectionName: string | null;
  colorId: string;
  colorRaw: string;
  sizeId: string;
  sizeLabelRaw: string;
  basePrice: number | null;
  ean: string | null;
}

export type ProductRowValidation =
  | { ok: true; fields: ProductImportRowFields }
  | { ok: false; reason: string };

function orNull(value: string | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : null;
}

/** Validates one spreadsheet row's mapped raw values against the
 * client-resolved [lookup] — never throws: any rejection reason is returned
 * as data so the caller can record it and keep processing the remaining
 * rows ("nenhuma linha inválida pode interromper as demais",
 * AGENTS.md). */
export function validateProductImportRow(
  raw: Record<string, string>,
  lookup: ProductImportLookupInput,
): ProductRowValidation {
  const sku = parseSku(raw.sku ?? '');
  if (!sku) {
    return { ok: false, reason: 'SKU ausente ou em formato inválido.' };
  }

  const reference = orNull(raw.reference);
  if (!reference) {
    return { ok: false, reason: 'Referência ausente.' };
  }

  const colorRaw = raw.colorName ?? '';
  if (colorRaw.trim().length === 0) {
    return { ok: false, reason: 'Cor ausente.' };
  }
  const colorId = lookup.colorIdByName[colorRaw.trim().toLowerCase()];
  if (!colorId) {
    return {
      ok: false,
      reason: `Cor "${colorRaw.trim()}" não cadastrada na paleta da organização.`,
    };
  }

  const sizeLabelRaw = raw.sizeLabel ?? '';
  if (sizeLabelRaw.trim().length === 0) {
    return { ok: false, reason: 'Tamanho ausente.' };
  }
  const sizeId = lookup.sizeIdByLabel[sizeLabelRaw.trim().toLowerCase()];
  if (!sizeId) {
    return {
      ok: false,
      reason: `Tamanho "${sizeLabelRaw.trim()}" não existe na grade selecionada.`,
    };
  }

  const categoryRaw = orNull(raw.categoryName);
  let categoryName: string | null = null;
  if (categoryRaw) {
    if (!lookup.categoryIdByName[categoryRaw.toLowerCase()]) {
      return {
        ok: false,
        reason: `Categoria "${categoryRaw}" não cadastrada.`,
      };
    }
    categoryName = categoryRaw;
  }

  const subcategoryRaw = orNull(raw.subcategoryName);
  let subcategoryName: string | null = null;
  if (subcategoryRaw) {
    if (!lookup.categoryIdByName[subcategoryRaw.toLowerCase()]) {
      return {
        ok: false,
        reason: `Subcategoria "${subcategoryRaw}" não cadastrada.`,
      };
    }
    subcategoryName = subcategoryRaw;
  }

  const collectionRaw = orNull(raw.collectionName);
  let collectionName: string | null = null;
  if (collectionRaw) {
    if (!lookup.collectionIdByName[collectionRaw.toLowerCase()]) {
      return {
        ok: false,
        reason: `Coleção "${collectionRaw}" não cadastrada.`,
      };
    }
    collectionName = collectionRaw;
  }

  let basePrice: number | null = null;
  const basePriceRaw = orNull(raw.basePrice);
  if (basePriceRaw) {
    const normalized = basePriceRaw.replace(/\./g, '').replace(',', '.');
    const parsed = Number.parseFloat(normalized);
    if (!Number.isFinite(parsed) || parsed < 0) {
      return { ok: false, reason: 'Preço base inválido.' };
    }
    basePrice = parsed;
  }

  let ean: string | null = null;
  const barcodeRaw = orNull(raw.barcode);
  if (barcodeRaw) {
    const parsedEan = parseEan(barcodeRaw);
    if (!parsedEan) {
      return { ok: false, reason: 'Código de barras (EAN) inválido.' };
    }
    ean = parsedEan;
  }

  return {
    ok: true,
    fields: {
      sku,
      reference,
      name: orNull(raw.name),
      shortDescription: orNull(raw.shortDescription),
      brand: orNull(raw.brand),
      categoryName,
      subcategoryName,
      collectionName,
      colorId,
      colorRaw: colorRaw.trim(),
      sizeId,
      sizeLabelRaw: sizeLabelRaw.trim(),
      basePrice,
      ean,
    },
  };
}

/** Builds the exact `organizations/{organizationId}/products/{id}` document
 * shape `ProductDto.toJson()` (Flutter, TASK-064) expects, for a freshly
 * created product — search text/prefixes mirror
 * `ProductSearchNormalizer` (Flutter, TASK-069) so an imported product is
 * immediately findable by `FirestoreProductRemoteSearchDataSource`, exactly
 * like one created through the app itself. */
export function buildProductDocumentFromFields(params: {
  organizationId: string;
  companyId: string;
  fields: ProductImportRowFields;
  categoryId: string | null;
  subcategoryId: string | null;
  collectionId: string | null;
  sizeGridTemplateId: string;
  createdBy: string;
  now: Timestamp;
}): DocumentData {
  const { organizationId, companyId, fields, createdBy, now } = params;
  const name = fields.name ?? fields.reference;
  const searchValues = [name, fields.sku, fields.reference].filter(
    (value): value is string => value.trim().length > 0,
  );
  const searchText = searchValues
    .map(normalizeSearchValue)
    .filter((value) => value.length > 0)
    .join(' ');
  const searchPrefixes = Array.from(prefixesForValues(searchValues)).sort();

  return {
    organizationId,
    companyId,
    sku: fields.sku,
    reference: fields.reference,
    name,
    shortDescription: fields.shortDescription,
    fullDescription: null,
    brand: fields.brand,
    collectionId: params.collectionId,
    seasonId: null,
    line: null,
    categoryId: params.categoryId,
    subcategoryId: params.subcategoryId,
    gender: null,
    targetAudience: null,
    fabric: null,
    composition: null,
    supplierId: null,
    ncm: null,
    ean: null,
    tags: [],
    colorIds: [],
    sizeGridTemplateId: params.sizeGridTemplateId,
    status: 'draft',
    launchDate: null,
    seoTitle: null,
    seoDescription: null,
    seoSlug: null,
    media: [],
    customFieldValues: [],
    createdAt: now,
    createdBy,
    updatedAt: now,
    updatedBy: createdBy,
    deletedAt: null,
    version: 1,
    syncStatus: 'synced',
    searchText,
    searchPrefixes,
  };
}

/** Builds the exact `organizations/{organizationId}/productVariants/{id}`
 * document shape `ProductVariantDto.toJson()` (Flutter, TASK-072) expects. */
export function buildProductVariantDocumentFromFields(params: {
  organizationId: string;
  productId: string;
  fields: ProductImportRowFields;
  variantSku: string;
  sizeGridTemplateId: string;
  createdBy: string;
  now: Timestamp;
}): DocumentData {
  const { organizationId, productId, fields, variantSku, createdBy, now } = params;
  return {
    organizationId,
    productId,
    colorId: fields.colorId,
    sizeGridTemplateId: params.sizeGridTemplateId,
    sizeId: fields.sizeId,
    sku: variantSku,
    ean: fields.ean,
    status: 'active',
    createdAt: now,
    createdBy,
    updatedAt: now,
    updatedBy: createdBy,
    version: 1,
    syncStatus: 'synced',
  };
}

// ---------------------------------------------------------------------
// Search normalization (mirrors
// lib/features/products/domain/services/product_search_normalizer.dart)
// ---------------------------------------------------------------------

const DIACRITICS: Readonly<Record<string, string>> = {
  á: 'a', à: 'a', â: 'a', ã: 'a', ä: 'a', å: 'a', ā: 'a', ă: 'a', ą: 'a',
  ç: 'c', ć: 'c', ĉ: 'c', ċ: 'c', č: 'c',
  ď: 'd', đ: 'd',
  é: 'e', è: 'e', ê: 'e', ë: 'e', ē: 'e', ĕ: 'e', ė: 'e', ę: 'e', ě: 'e',
  í: 'i', ì: 'i', î: 'i', ï: 'i', ī: 'i', ĭ: 'i', į: 'i',
  ñ: 'n', ń: 'n', ņ: 'n', ň: 'n',
  ó: 'o', ò: 'o', ô: 'o', õ: 'o', ö: 'o', ō: 'o', ŏ: 'o', ő: 'o',
  ú: 'u', ù: 'u', û: 'u', ü: 'u', ū: 'u', ŭ: 'u', ů: 'u', ű: 'u', ų: 'u',
  ý: 'y', ÿ: 'y',
};

const NON_SEARCH_CHARS = /[^a-z0-9]+/g;
const SPACES = /\s+/g;
const MAX_PREFIX_LENGTH = 32;

export function normalizeSearchValue(value: string): string {
  if (value.trim().length === 0) return '';
  let normalized = '';
  for (const char of value.toLowerCase()) {
    normalized += DIACRITICS[char] ?? char;
  }
  return normalized.replace(NON_SEARCH_CHARS, ' ').replace(SPACES, ' ').trim();
}

function addPrefixes(prefixes: Set<string>, value: string): void {
  const normalized = value.trim();
  if (normalized.length === 0) return;
  const maxLength = Math.min(normalized.length, MAX_PREFIX_LENGTH);
  for (let length = 1; length <= maxLength; length += 1) {
    prefixes.add(normalized.slice(0, length));
  }
}

export function prefixesForValues(values: readonly string[]): Set<string> {
  const prefixes = new Set<string>();
  for (const value of values) {
    const normalized = normalizeSearchValue(value);
    if (normalized.length === 0) continue;
    addPrefixes(prefixes, normalized);
    for (const token of normalized.split(' ')) {
      addPrefixes(prefixes, token);
    }
  }
  return prefixes;
}
