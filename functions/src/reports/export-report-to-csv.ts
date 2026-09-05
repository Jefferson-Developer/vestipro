import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { requireNonEmptyString } from '../invites/invite-shared';
import { REPORT_ROLES } from './report-catalog';
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

// Re-exported so `functions/test/reports/export-report-to-csv.test.ts`'s
// existing imports keep working unchanged after the RBAC/filename/volume
// logic moved to `export-shared.ts` (TASK-147, reused by
// `export-report-to-xlsx.ts` too — "não duplicar lógica de exportação
// assíncrona").
export { assertCanExportReports, buildExportFileName };

/** Backward-compatible alias — kept so nothing outside this file needs to
 * know the type was renamed to the format-agnostic `ExportLocale` when
 * `export-report-to-xlsx.ts` (TASK-147) started sharing it. */
export type CsvLocale = ExportLocale;

/** RFC4180-ish field escaping — quotes a field only when it actually
 * contains the delimiter, a quote or a line break, doubling any embedded
 * quote, exactly like `CsvReportEncoder` on the Flutter side (kept in
 * intentional parity so the two independently-generated CSVs — client-side
 * small export vs. this server-side large export — read identically in
 * Excel). */
function escapeCsvField(delimiter: string, field: string): string {
  const needsQuoting =
    field.includes(delimiter) ||
    field.includes('"') ||
    field.includes('\n') ||
    field.includes('\r');
  if (!needsQuoting) return field;
  return `"${field.replace(/"/g, '""')}"`;
}

function formatCsvValue(value: unknown, locale: ExportLocale): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) return '';
    if (Number.isInteger(value)) return String(value);
    const fixed = value.toFixed(2);
    return locale === 'ptBr' ? fixed.replace('.', ',') : fixed;
  }
  return String(value);
}

/** Builds the full CSV text (UTF-8 BOM + header + rows, `\r\n` line
 * endings) for [columns]/[rows] — exported standalone so it can be unit
 * tested for accentuation, escaping and locale formatting without touching
 * Firestore/Storage. */
export function rowsToCsv(
  columns: readonly string[],
  rows: readonly Record<string, unknown>[],
  locale: ExportLocale,
): string {
  const delimiter = locale === 'ptBr' ? ';' : ',';
  const lines = [columns.map((column) => escapeCsvField(delimiter, column)).join(delimiter)];
  for (const row of rows) {
    lines.push(
      columns
        .map((column) => escapeCsvField(delimiter, formatCsvValue(row[column], locale)))
        .join(delimiter),
    );
  }
  return `﻿${lines.join('\r\n')}\r\n`;
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
 * Large-volume CSV export (TASK-146): re-runs the exact same
 * {@link runReportAggregation} `executeReportQuery` uses — never trusting a
 * `ReportQueryResult` handed back by the client — under the caller's own
 * role/tenant scope, then writes the resulting CSV to a
 * `organizations/{organizationId}/exports/{uid}/{fileName}` Storage object
 * restricted to that same caller (`storage.rules`) and returns a short-lived
 * signed URL. The Flutter client only calls this callable once the result of
 * an `executeReportQuery` preview already exceeded
 * `FeatureFlagRegistry.configReportExportMaxLocalRows` — that client-side
 * threshold is a UX decision only, never itself a security boundary: this
 * callable independently caps at {@link MAX_EXPORTABLE_ROWS}.
 */
export const exportReportToCsv = onCall<ExportReportInput>(async (request) => {
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
  const generatedAt = new Date();
  const fileName = buildExportFileName({ dimensions, metrics, organizationId, generatedAt, extension: 'csv' });
  const csv = rowsToCsv(columns, rows, locale);

  const objectPath = `organizations/${organizationId}/exports/${request.auth.uid}/${fileName}`;
  const bucket = getStorage().bucket();
  const file = bucket.file(objectPath);
  const expiresAt = new Date(generatedAt.getTime() + EXPORT_LINK_TTL_MS);
  await file.save(Buffer.from(csv, 'utf8'), {
    contentType: 'text/csv; charset=utf-8',
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
