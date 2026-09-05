import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import ExcelJS from 'exceljs';

import { requireNonEmptyString } from '../invites/invite-shared';
import { catalogForRole, REPORT_ROLES, type ReportFieldConfig } from './report-catalog';
import {
  runReportAggregation,
  type ReportAggregationMember,
} from './execute-report-query';
import {
  assertCanExportReports,
  buildExportFileName,
  EXPORT_LINK_TTL_MS,
  MAX_EXPORTABLE_ROWS,
  parseExportLocale,
  type ExportLocale,
} from './export-shared';

/** Mirrors `ReportColumnValueTypeResolver` (Flutter, TASK-147) — resolves
 * which cell type a `ReportQueryResult` column should be written as, using
 * the *server's own* catalog for the caller's role (never a client-supplied
 * schema). Comparison columns synthesized by `runReportAggregation`
 * (`<metric>Comparison`/`<metric>ChangePercent`) never appear in the
 * catalog themselves, so they fall back to their base metric's type
 * (`Comparison`) or are always a percentage (`ChangePercent`). */
export function resolveColumnValueType(
  columnId: string,
  catalog: readonly ReportFieldConfig[],
): ReportFieldConfig['valueType'] {
  if (columnId.endsWith('ChangePercent')) return 'percentage';
  if (columnId.endsWith('Comparison')) {
    const baseId = columnId.slice(0, -'Comparison'.length);
    return catalog.find((field) => field.id === baseId)?.valueType ?? 'number';
  }
  return catalog.find((field) => field.id === columnId)?.valueType ?? 'text';
}

const PERIOD_PATTERN = /^(\d{4})-(\d{2})$/;

/** Converts a raw aggregation value into what ExcelJS should actually
 * store for [valueType] — a real `Date` for a date column (never a
 * string), the fractional `0.xx` form for a percentage (Excel's own `%`
 * format multiplies by 100 for display), or the value unchanged for
 * number/currency/text. Never throws: an unparseable value degrades to its
 * `String(...)` form instead of crashing the export. */
function planCellValue(
  value: unknown,
  valueType: ReportFieldConfig['valueType'],
): string | number | Date {
  if (value === null || value === undefined) return '';
  switch (valueType) {
    case 'date': {
      if (typeof value !== 'string') return String(value);
      const match = PERIOD_PATTERN.exec(value);
      if (!match) return value;
      return new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, 1));
    }
    case 'percentage': {
      const num = typeof value === 'number' ? value : Number(value);
      return Number.isFinite(num) ? num / 100 : String(value);
    }
    case 'currency':
    case 'number': {
      const num = typeof value === 'number' ? value : Number(value);
      return Number.isFinite(num) ? num : String(value);
    }
    default:
      return typeof value === 'number' ? value : String(value);
  }
}

function numberFormatFor(
  valueType: ReportFieldConfig['valueType'],
  locale: ExportLocale,
): string | undefined {
  switch (valueType) {
    case 'date':
      // `yyyy-mm` — never a locale-dependent month name, so the rendered
      // text is unambiguous regardless of which Excel language the file is
      // opened in. The underlying cell is still a real Excel date (serial
      // number), never a string.
      return 'yyyy-mm';
    case 'currency':
      return locale === 'ptBr' ? '"R$" #,##0.00' : '"$" #,##0.00';
    case 'percentage':
      return '0.00%';
    case 'number':
      return '#,##0.##';
    default:
      return undefined;
  }
}

function columnLetter(zeroBasedIndex: number): string {
  let index = zeroBasedIndex;
  let letters = '';
  do {
    letters = String.fromCharCode(65 + (index % 26)) + letters;
    index = Math.floor(index / 26) - 1;
  } while (index >= 0);
  return letters;
}

/** Builds the full XLSX buffer (TASK-147) for [columns]/[rows]: a bold,
 * frozen header row, one column per entry in [columns], a native
 * `AutoFilter` spanning the whole data range, and every cell typed per
 * [catalog] (`resolveColumnValueType`) — never as generic text. Produces a
 * structurally valid workbook (header row only, no crash) even when [rows]
 * is empty. Exported standalone so it can be unit tested without touching
 * Firestore/Storage. */
export async function rowsToXlsxBuffer(
  columns: readonly string[],
  rows: readonly Record<string, unknown>[],
  catalog: readonly ReportFieldConfig[],
  locale: ExportLocale,
): Promise<Buffer> {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Relatório', {
    views: [{ state: 'frozen', ySplit: 1 }],
  });
  sheet.columns = columns.map((id) => ({ header: id, key: id, width: 18 }));
  sheet.getRow(1).eachCell((cell) => {
    cell.font = { bold: true };
  });

  const valueTypes = new Map<string, ReportFieldConfig['valueType']>(
    columns.map((id) => [id, resolveColumnValueType(id, catalog)]),
  );

  for (const row of rows) {
    const values: Record<string, string | number | Date> = {};
    for (const id of columns) {
      values[id] = planCellValue(row[id], valueTypes.get(id)!);
    }
    const addedRow = sheet.addRow(values);
    for (const id of columns) {
      const format = numberFormatFor(valueTypes.get(id)!, locale);
      if (format) addedRow.getCell(id).numFmt = format;
    }
  }

  const lastRow = rows.length + 1;
  const lastColumn = columnLetter(Math.max(columns.length - 1, 0));
  sheet.autoFilter = `A1:${lastColumn}${lastRow}`;

  return (await workbook.xlsx.writeBuffer()) as unknown as Buffer;
}

interface ExportReportInput {
  organizationId?: unknown;
  companyId?: unknown;
  dimensions?: unknown;
  metrics?: unknown;
  filters?: unknown;
  groupBy?: unknown;
  sortBy?: unknown;
  comparisonPeriod?: unknown;
  locale?: unknown;
}

/**
 * Large-volume XLSX export (TASK-147): reuses the exact same RBAC guard
 * (`assertCanExportReports`), volume ceiling (`MAX_EXPORTABLE_ROWS`),
 * export-link lifetime (`EXPORT_LINK_TTL_MS`) and deterministic file-name
 * builder `exportReportToCsv` (TASK-146) already established
 * (`export-shared.ts`) — the only thing that differs is the file format
 * itself. Re-runs {@link runReportAggregation} — never trusting a
 * `ReportQueryResult`/`ReportCatalog` handed back by the client — under the
 * caller's own role/tenant scope, then writes the resulting XLSX to a
 * `organizations/{organizationId}/exports/{uid}/{fileName}` Storage object
 * restricted to that same caller (`storage.rules`) and returns a
 * short-lived signed URL.
 */
export const exportReportToXlsx = onCall<ExportReportInput>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const db = getFirestore();
  const memberSnapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('members')
    .doc(request.auth.uid)
    .get();
  const member = memberSnapshot.data();
  if (!memberSnapshot.exists || member?.status !== 'active' || !REPORT_ROLES.has(member.roleName as string)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode executar relatórios.');
  }
  assertCanExportReports(member.roleName as string);
  const company = await db.collection('organizations').doc(organizationId).collection('companies').doc(companyId).get();
  if (!company.exists) throw new HttpsError('not-found', 'Empresa não encontrada nesta organização.');

  const { columns, rows } = await runReportAggregation({
    db,
    organizationId,
    companyId,
    member: member as ReportAggregationMember,
    authUid: request.auth.uid,
    data: request.data,
  });
  if (rows.length > MAX_EXPORTABLE_ROWS) {
    throw new HttpsError(
      'resource-exhausted',
      'O resultado excede o limite máximo de linhas exportáveis. Refine os filtros do relatório.',
    );
  }

  const locale = parseExportLocale(request.data?.locale);
  const dimensions = Array.isArray(request.data?.dimensions) ? (request.data!.dimensions as string[]) : [];
  const metrics = Array.isArray(request.data?.metrics) ? (request.data!.metrics as string[]) : [];
  const catalog = catalogForRole(member.roleName as string);
  const generatedAt = new Date();
  const fileName = buildExportFileName({ dimensions, metrics, organizationId, generatedAt, extension: 'xlsx' });
  const buffer = await rowsToXlsxBuffer(columns, rows, catalog, locale);

  const objectPath = `organizations/${organizationId}/exports/${request.auth.uid}/${fileName}`;
  const bucket = getStorage().bucket();
  const file = bucket.file(objectPath);
  const expiresAt = new Date(generatedAt.getTime() + EXPORT_LINK_TTL_MS);
  await file.save(buffer, {
    contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    metadata: { cacheControl: 'private, max-age=0', metadata: { requestedBy: request.auth.uid } },
  });
  const [downloadUrl] = await file.getSignedUrl({ action: 'read', expires: expiresAt });

  return {
    downloadUrl,
    expiresAt: expiresAt.toISOString(),
    fileName,
    rowCount: rows.length,
  };
});
