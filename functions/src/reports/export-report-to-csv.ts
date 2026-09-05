import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { requireNonEmptyString } from '../invites/invite-shared';
import { REPORT_ROLES } from './report-catalog';
import {
  runReportAggregation,
  type ReportAggregationMember,
} from './execute-report-query';

/**
 * Mirrors `Capability.reportExport` (`lib/core/permissions/capability.dart`,
 * granted to OWNER/ADMIN/SALES_MANAGER/FINANCE in
 * `role_permission_matrix.dart`) — a strict subset of {@link REPORT_ROLES}:
 * every role in {@link REPORT_ROLES} may *build/preview* a report
 * (`executeReportQuery`), but SALES_REP never gets to *export* one, exactly
 * as the Dart RBAC matrix and `storage.rules`/`firestore.rules`'
 * `roleHasCapability('report.export', ...)` already decide for every other
 * report.* surface (TASK-146). Kept as its own set instead of reusing
 * `FINANCIAL_ROLES` because the two overlap but are not the same thing
 * (SALES_MANAGER exports reports but never sees financial-sensitive fields).
 */
export const REPORT_EXPORT_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'FINANCE',
]);

/** Fails closed (`permission-denied`) unless [roleName] is one of
 * {@link REPORT_EXPORT_ROLES} — exported standalone (instead of inlined in
 * the callable body) so a unit test can assert the RBAC boundary without
 * spinning up the Firebase Emulator, same "pure guard function" shape as
 * `catalogForRole`'s own role check. */
export function assertCanExportReports(roleName: string): void {
  if (!REPORT_EXPORT_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode exportar relatórios.',
    );
  }
}

/** Hard ceiling on how many rows a single CSV export ever contains,
 * regardless of what the client-side threshold
 * (`FeatureFlagRegistry.configReportExportMaxLocalRows`) is configured to —
 * a defense-in-depth cap independent of anything the client claims. */
const MAX_EXPORTABLE_ROWS = 200_000;

/** Storage export files are kept for this long before Storage's own
 * lifecycle policy is expected to delete them (`storage.rules`' own comment
 * on `organizations/{organizationId}/exports/...`) — the signed URL returned
 * to the caller never outlives this window either. */
const EXPORT_LINK_TTL_MS = 24 * 60 * 60 * 1000;

export type CsvLocale = 'ptBr' | 'enUs';

function parseLocale(raw: unknown): CsvLocale {
  return raw === 'enUs' ? 'enUs' : 'ptBr';
}

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

function formatCsvValue(value: unknown, locale: CsvLocale): string {
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
  locale: CsvLocale,
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

function slugify(value: string): string {
  const normalized = value
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return normalized.length > 0 ? normalized : 'relatorio';
}

function timestampSlug(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return (
    `${date.getUTCFullYear()}${pad(date.getUTCMonth() + 1)}${pad(date.getUTCDate())}` +
    `-${pad(date.getUTCHours())}${pad(date.getUTCMinutes())}${pad(date.getUTCSeconds())}`
  );
}

/** Deterministic `<slug-do-relatorio>_<organizacao>_<timestamp>.csv` file
 * name (TASK-146) — mirrors
 * `ReportExportFileNameBuilder.build` on the Flutter side field-for-field, so
 * a locally-generated and a Cloud-Function-generated export are never
 * ambiguous about which report/organization/moment they came from. */
export function buildExportFileName(params: {
  dimensions: readonly string[];
  metrics: readonly string[];
  organizationId: string;
  generatedAt: Date;
}): string {
  const reportSlug = slugify([...params.dimensions, ...params.metrics].join('-'));
  const organizationSlug = slugify(params.organizationId);
  return `${reportSlug}_${organizationSlug}_${timestampSlug(params.generatedAt)}.csv`;
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

  const locale = parseLocale(request.data?.locale);
  const dimensions = Array.isArray(request.data?.dimensions) ? (request.data!.dimensions as string[]) : [];
  const metrics = Array.isArray(request.data?.metrics) ? (request.data!.metrics as string[]) : [];
  const generatedAt = new Date();
  const fileName = buildExportFileName({ dimensions, metrics, organizationId, generatedAt });
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
