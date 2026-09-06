import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

/**
 * Shared by every customer-import Cloud Function (TASK-167:
 * `startCustomerImportJob`, `processCustomerImportJob`,
 * `resolveCustomerImportDuplicateRow`) so the RBAC boundary, field
 * vocabulary, row-validation rules and CPF/CNPJ check-digit algorithm are
 * defined exactly once — same "não duplicar lógica" rationale
 * `export-shared.ts` (TASK-146/147) already documents for report exports.
 *
 * The CPF/CNPJ validation below is an intentional TypeScript port of
 * `lib/features/customers/domain/value_objects/cnpj_cpf.dart` (TASK-048):
 * Cloud Functions run in Node, so the Dart value object itself cannot be
 * reused here — kept algorithm-for-algorithm identical (same weights, same
 * "all digits repeated" rejection) so a document accepted/rejected
 * client-side (`CreateCustomerUseCase`) is never accepted/rejected
 * differently by this import path.
 */

/** Mirrors `Capability.customerImport`
 * (`lib/core/permissions/capability.dart`, granted to
 * OWNER/ADMIN/SALES_MANAGER in `role_permission_matrix.dart`). */
export const CUSTOMER_IMPORT_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

export function assertCanImportCustomers(roleName: string): void {
  if (!CUSTOMER_IMPORT_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode importar clientes.',
    );
  }
}

/** Mirrors `kCustomerImportMaxFileSizeBytes` (Flutter) — the same ceiling
 * enforced again server-side, independent of anything the client claims. */
export const MAX_IMPORT_FILE_SIZE_BYTES = 15 * 1024 * 1024;

/** Hard ceiling on how many data rows a single import job ever processes —
 * a defense-in-depth cap so one job can never run unbounded inside a single
 * Cloud Function invocation. Importing a larger base means splitting the
 * source spreadsheet into multiple files/jobs (documented limitation, see
 * TASK-167-...-CONCLUIDA.md). */
export const MAX_IMPORT_ROWS = 20_000;

export const CUSTOMER_IMPORT_FIELD_CODES: ReadonlySet<string> = new Set<
  string
>([
  'document',
  'legalName',
  'tradeName',
  'fullName',
  'stateRegistration',
  'primaryEmail',
  'primaryPhone',
  'classification',
  'potential',
  'segment',
  'originChannel',
  'addressStreet',
  'addressNumber',
  'addressComplement',
  'addressDistrict',
  'addressCity',
  'addressState',
  'addressZipCode',
]);

export interface CustomerImportMappingInput {
  hasHeaderRow: boolean;
  columnByField: Record<string, number>;
}

/** Validates the shape of a mapping sent to `startCustomerImportJob` —
 * mirrors `validateCustomerImportMapping` (Flutter), re-checked here since a
 * forged/stale client mapping must never be trusted. */
export function assertValidMapping(mapping: unknown): CustomerImportMappingInput {
  if (
    typeof mapping !== 'object' ||
    mapping === null ||
    typeof (mapping as Record<string, unknown>).hasHeaderRow !== 'boolean' ||
    typeof (mapping as Record<string, unknown>).columnByField !== 'object'
  ) {
    throw new HttpsError('invalid-argument', 'mapping é obrigatório e inválido.');
  }
  const columnByField = (mapping as Record<string, unknown>).columnByField as Record<
    string,
    unknown
  >;
  const parsed: Record<string, number> = {};
  for (const [field, column] of Object.entries(columnByField)) {
    if (!CUSTOMER_IMPORT_FIELD_CODES.has(field) || typeof column !== 'number') {
      throw new HttpsError('invalid-argument', `Campo de mapeamento inválido: ${field}.`);
    }
    parsed[field] = column;
  }
  if (!('document' in parsed)) {
    throw new HttpsError(
      'invalid-argument',
      'O mapeamento precisa incluir uma coluna para "document" (CNPJ/CPF).',
    );
  }
  if (
    !('legalName' in parsed) &&
    !('tradeName' in parsed) &&
    !('fullName' in parsed)
  ) {
    throw new HttpsError(
      'invalid-argument',
      'O mapeamento precisa incluir ao menos uma coluna de nome.',
    );
  }
  return {
    hasHeaderRow: (mapping as Record<string, unknown>).hasHeaderRow as boolean,
    columnByField: parsed,
  };
}

/** Extracts the raw, trimmed text of every mapped field from one parsed
 * spreadsheet [row] (already split into cells by the caller). */
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

const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export function isValidEmail(value: string): boolean {
  return EMAIL_PATTERN.test(value);
}

function digitAt(digits: string, index: number): number {
  return digits.charCodeAt(index) - 48;
}

function hasOnlyRepeatedDigits(digits: string): boolean {
  const first = digits.charCodeAt(0);
  for (let i = 1; i < digits.length; i += 1) {
    if (digits.charCodeAt(i) !== first) return false;
  }
  return true;
}

function cpfCheckDigit(digits: string, length: number): number {
  let sum = 0;
  for (let index = 0; index < length; index += 1) {
    sum += digitAt(digits, index) * (length + 1 - index);
  }
  const remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}

function isValidCpf(digits: string): boolean {
  if (hasOnlyRepeatedDigits(digits)) return false;
  const first = cpfCheckDigit(digits, 9);
  const second = cpfCheckDigit(digits, 10);
  return digitAt(digits, 9) === first && digitAt(digits, 10) === second;
}

function cnpjCheckDigit(digits: string, weights: readonly number[]): number {
  let sum = 0;
  for (let index = 0; index < weights.length; index += 1) {
    sum += digitAt(digits, index) * weights[index];
  }
  const remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}

const CNPJ_FIRST_WEIGHTS = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
const CNPJ_SECOND_WEIGHTS = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

function isValidCnpj(digits: string): boolean {
  if (hasOnlyRepeatedDigits(digits)) return false;
  const first = cnpjCheckDigit(digits, CNPJ_FIRST_WEIGHTS);
  const second = cnpjCheckDigit(digits, CNPJ_SECOND_WEIGHTS);
  return digitAt(digits, 12) === first && digitAt(digits, 13) === second;
}

export type CustomerImportDocumentType = 'individual' | 'legalEntity';

/** Normalizes+validates a raw CPF/CNPJ string exactly like
 * `CnpjCpf.parse` (Dart) does — returns `null` for anything invalid
 * (wrong length, bad check digits, all-repeated digits) instead of
 * throwing, since a single bad row must never interrupt the batch. */
export function parseCnpjCpf(
  raw: string,
): { digits: string; type: CustomerImportDocumentType } | null {
  const digits = raw.replace(/\D/g, '');
  if (digits.length === 11) {
    return isValidCpf(digits) ? { digits, type: 'individual' } : null;
  }
  if (digits.length === 14) {
    return isValidCnpj(digits) ? { digits, type: 'legalEntity' } : null;
  }
  return null;
}

/** Same "8 digits, not all repeated" rule as `Cep.parse` (Dart) — returns
 * `null` (never throws) for an invalid CEP, since an address is optional:
 * an invalid CEP only ever drops the address block for that row, it never
 * rejects the whole row. */
export function parseCep(raw: string): string | null {
  const digits = raw.replace(/\D/g, '');
  if (digits.length !== 8) return null;
  if (/^(\d)\1{7}$/.test(digits)) return null;
  return digits;
}

export interface CustomerImportAddress {
  street: string;
  number: string | null;
  complement: string | null;
  district: string | null;
  city: string;
  state: string;
  zipCode: string;
}

export interface CustomerImportRowFields {
  documentDigits: string;
  documentType: CustomerImportDocumentType;
  legalName: string | null;
  tradeName: string | null;
  fullName: string | null;
  stateRegistration: string | null;
  primaryEmail: string | null;
  primaryPhone: string | null;
  classification: string | null;
  potential: string | null;
  segment: string | null;
  originChannel: string | null;
  address: CustomerImportAddress | null;
}

export type CustomerRowValidation =
  | { ok: true; fields: CustomerImportRowFields }
  | { ok: false; reason: string };

function orNull(value: string | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : null;
}

/** Validates one spreadsheet row's mapped raw values and, when valid,
 * builds the exact field set `processCustomerImportJob` needs to create a
 * `Customer` document — mirrors `validateCustomerIdentity` +
 * `CreateCustomerUseCase`'s field rules (Dart) closely enough that a row
 * accepted here would also be accepted by that use case. Never throws: any
 * rejection reason is returned as data so the caller can record it in the
 * per-row report and keep processing the remaining rows. */
export function validateCustomerImportRow(
  raw: Record<string, string>,
): CustomerRowValidation {
  const documentRaw = raw.document ?? '';
  if (documentRaw.length === 0) {
    return { ok: false, reason: 'CNPJ/CPF ausente.' };
  }
  const parsedDocument = parseCnpjCpf(documentRaw);
  if (!parsedDocument) {
    return {
      ok: false,
      reason: 'CNPJ/CPF em formato inválido ou com dígito verificador incorreto.',
    };
  }

  const legalName = orNull(raw.legalName);
  const tradeName = orNull(raw.tradeName);
  const fullName = orNull(raw.fullName);

  if (parsedDocument.type === 'legalEntity') {
    if (!legalName && !tradeName) {
      return {
        ok: false,
        reason: 'Informe razão social ou nome fantasia para CNPJ.',
      };
    }
  } else if (!fullName) {
    return { ok: false, reason: 'Informe o nome completo para CPF.' };
  }

  const primaryEmail = orNull(raw.primaryEmail);
  if (primaryEmail && !isValidEmail(primaryEmail)) {
    return { ok: false, reason: 'E-mail em formato inválido.' };
  }

  let address: CustomerImportAddress | null = null;
  const street = orNull(raw.addressStreet);
  const city = orNull(raw.addressCity);
  const state = orNull(raw.addressState);
  const zipCodeRaw = raw.addressZipCode ?? '';
  const zipCode = zipCodeRaw.length > 0 ? parseCep(zipCodeRaw) : null;
  if (street && city && state && zipCode) {
    address = {
      street,
      number: orNull(raw.addressNumber),
      complement: orNull(raw.addressComplement),
      district: orNull(raw.addressDistrict),
      city,
      state,
      zipCode,
    };
  }

  return {
    ok: true,
    fields: {
      documentDigits: parsedDocument.digits,
      documentType: parsedDocument.type,
      legalName: parsedDocument.type === 'legalEntity' ? legalName ?? tradeName : null,
      tradeName: parsedDocument.type === 'legalEntity' ? tradeName : null,
      fullName: parsedDocument.type === 'individual' ? fullName : null,
      stateRegistration:
        parsedDocument.type === 'legalEntity' ? orNull(raw.stateRegistration) : null,
      primaryEmail,
      primaryPhone: orNull(raw.primaryPhone),
      classification: orNull(raw.classification),
      potential: orNull(raw.potential),
      segment: orNull(raw.segment),
      originChannel: orNull(raw.originChannel),
      address,
    },
  };
}

/** Builds the exact `organizations/{organizationId}/customers/{id}`
 * document shape `CustomerDto.toJson()` (Flutter, TASK-048) expects, from
 * one validated row's [CustomerImportRowFields] — shared by
 * `processCustomerImportJob` (the original batch import) and
 * `resolveCustomerImportDuplicateRow`'s `createAnyway` decision, so a
 * customer created either way is indistinguishable in Firestore. */
export function buildCustomerDocumentFromFields(params: {
  organizationId: string;
  companyId: string;
  fields: CustomerImportRowFields;
  createdBy: string;
  now: Timestamp;
}): DocumentData {
  const { organizationId, companyId, fields, createdBy, now } = params;
  return {
    organizationId,
    companyId,
    type: fields.documentType,
    document: fields.documentDigits,
    legalName: fields.legalName,
    tradeName: fields.tradeName,
    fullName: fields.fullName,
    stateRegistration: fields.stateRegistration,
    primaryEmail: fields.primaryEmail,
    primaryPhone: fields.primaryPhone,
    status: 'prospect',
    classification: fields.classification,
    potential: fields.potential,
    segment: fields.segment,
    originChannel: fields.originChannel ?? 'import',
    responsibleSellerId: null,
    sourceLeadId: null,
    registeredAt: now,
    lastPurchaseAt: null,
    commercialScore: null,
    healthScore: null,
    healthScoreBand: null,
    scoreUpdatedAt: null,
    scoreFormulaVersion: null,
    scoreDataCoverage: null,
    addresses: fields.address
      ? [
          {
            id: 'import-address',
            typeCode: 'headquarters',
            typeLabel: 'Sede',
            street: fields.address.street,
            number: fields.address.number,
            complement: fields.address.complement,
            district: fields.address.district,
            city: fields.address.city,
            state: fields.address.state,
            zipCode: fields.address.zipCode,
            country: 'BR',
            isPrimary: true,
          },
        ]
      : [],
    contacts: [],
    tags: [],
    customFields: {},
    createdAt: now,
    createdBy,
    updatedAt: now,
    updatedBy: createdBy,
    deletedAt: null,
    version: 1,
    syncStatus: 'synced',
  };
}
