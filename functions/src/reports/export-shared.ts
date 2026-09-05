import { HttpsError } from 'firebase-functions/v2/https';

/**
 * Shared by every report export callable (`exportReportToCsv`, TASK-146;
 * `exportReportToXlsx`, TASK-147) so the RBAC boundary, hard volume ceiling,
 * export-link lifetime and deterministic file naming are defined exactly
 * once — TASK-147 explicitly requires "reaproveitar a mesma estratégia de
 * volume grande delegado à Cloud Function definida em TASK-146 (não
 * duplicar lógica de exportação assíncrona)".
 */

/**
 * Mirrors `Capability.reportExport` (`lib/core/permissions/capability.dart`,
 * granted to OWNER/ADMIN/SALES_MANAGER/FINANCE in
 * `role_permission_matrix.dart`) — a strict subset of `REPORT_ROLES`
 * (`report-catalog.ts`): every role in `REPORT_ROLES` may *build/preview* a
 * report (`executeReportQuery`), but SALES_REP never gets to *export* one,
 * exactly as the Dart RBAC matrix and `storage.rules`/`firestore.rules`'
 * `roleHasCapability('report.export', ...)` already decide for every other
 * report.* surface.
 */
export const REPORT_EXPORT_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'FINANCE',
]);

/** Fails closed (`permission-denied`) unless [roleName] is one of
 * {@link REPORT_EXPORT_ROLES} — exported standalone (instead of inlined in
 * a callable body) so a unit test can assert the RBAC boundary without
 * spinning up the Firebase Emulator. */
export function assertCanExportReports(roleName: string): void {
  if (!REPORT_EXPORT_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode exportar relatórios.',
    );
  }
}

/** Hard ceiling on how many rows a single export (CSV or XLSX) ever
 * contains, regardless of what the client-side threshold
 * (`FeatureFlagRegistry.configReportExportMaxLocalRows`) is configured to —
 * a defense-in-depth cap independent of anything the client claims. */
export const MAX_EXPORTABLE_ROWS = 200_000;

/** Storage export files are kept for this long before Storage's own
 * lifecycle policy is expected to delete them (`storage.rules`' own comment
 * on `organizations/{organizationId}/exports/...`) — the signed URL returned
 * to the caller never outlives this window either. */
export const EXPORT_LINK_TTL_MS = 24 * 60 * 60 * 1000;

export type ExportLocale = 'ptBr' | 'enUs';

export function parseExportLocale(raw: unknown): ExportLocale {
  return raw === 'enUs' ? 'enUs' : 'ptBr';
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

/** Deterministic `<slug-do-relatorio>_<organizacao>_<timestamp>.<extension>`
 * file name (TASK-146/TASK-147) — mirrors
 * `ReportExportFileNameBuilder.build` on the Flutter side field-for-field
 * (only the extension varies by format), so a locally-generated and a
 * Cloud-Function-generated export are never ambiguous about which
 * report/organization/moment they came from. */
export function buildExportFileName(params: {
  dimensions: readonly string[];
  metrics: readonly string[];
  organizationId: string;
  generatedAt: Date;
  extension: string;
}): string {
  const reportSlug = slugify([...params.dimensions, ...params.metrics].join('-'));
  const organizationSlug = slugify(params.organizationId);
  return `${reportSlug}_${organizationSlug}_${timestampSlug(params.generatedAt)}.${params.extension}`;
}
