import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import PDFDocument from 'pdfkit';

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
import { resolveColumnValueType } from './export-report-to-xlsx';

/** VestiPro's own default brand color (matches `PdfReportEncoder
 * ._defaultBrandColor` on the Flutter side, TASK-148) — applied whenever the
 * calling organization never configured `OrganizationSettings
 * .brandingPrimaryColorHex`. */
const DEFAULT_BRAND_COLOR = '#0F172A';

const PERIOD_PATTERN = /^(\d{4})-(\d{2})$/;
const MONTH_NAMES_PT_BR = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

export interface ReportPdfBranding {
  logoBytes?: Buffer;
  primaryColorHex?: string;
}

function isHexColor(value: unknown): value is string {
  return typeof value === 'string' && /^#[0-9A-Fa-f]{6}$/.test(value);
}

/** Resolves the calling organization's PDF branding (TASK-148) straight from
 * its own Firestore document (Admin SDK — never trusts anything the client
 * sent), downloading the logo image itself when a URL is configured. Never
 * throws: a broken/unreachable logo URL degrades to a color-only (or fully
 * default) [ReportPdfBranding] instead of failing the whole export. */
export async function resolveReportPdfBranding(
  db: FirebaseFirestore.Firestore,
  organizationId: string,
): Promise<ReportPdfBranding> {
  const snapshot = await db.collection('organizations').doc(organizationId).get();
  const settings = snapshot.data()?.settings as Record<string, unknown> | undefined;
  const primaryColorHex = isHexColor(settings?.brandingPrimaryColorHex)
    ? (settings!.brandingPrimaryColorHex as string)
    : undefined;
  const logoUrl = settings?.brandingLogoUrl;
  if (typeof logoUrl !== 'string' || logoUrl.length === 0) {
    return { primaryColorHex };
  }
  try {
    const response = await fetch(logoUrl);
    if (!response.ok) return { primaryColorHex };
    const arrayBuffer = await response.arrayBuffer();
    return { primaryColorHex, logoBytes: Buffer.from(arrayBuffer) };
  } catch {
    return { primaryColorHex };
  }
}

function formatDateCell(value: unknown): string {
  if (typeof value === 'string') {
    const match = PERIOD_PATTERN.exec(value);
    if (match) return `${match[2]}/${match[1]}`;
    return value;
  }
  return String(value);
}

function groupThousands(digits: string, locale: ExportLocale): string {
  const negative = digits.startsWith('-');
  const unsigned = negative ? digits.slice(1) : digits;
  const separator = locale === 'ptBr' ? '.' : ',';
  let grouped = '';
  for (let i = 0; i < unsigned.length; i++) {
    if (i > 0 && (unsigned.length - i) % 3 === 0) grouped += separator;
    grouped += unsigned[i];
  }
  return negative ? `-${grouped}` : grouped;
}

function formatDecimal(value: number, locale: ExportLocale, forceTwoDecimals: boolean): string {
  if (!Number.isFinite(value)) return '0';
  const isWhole = Number.isInteger(value);
  const fixed = isWhole && !forceTwoDecimals ? value.toFixed(0) : value.toFixed(2);
  const [intPart, decimalPart] = fixed.split('.');
  const grouped = groupThousands(intPart, locale);
  if (decimalPart === undefined) return grouped;
  return locale === 'ptBr' ? `${grouped},${decimalPart}` : `${grouped}.${decimalPart}`;
}

function asNumber(value: unknown): number | null {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number(value.replace(',', '.'));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

/** Mirrors `PdfReportEncoder._formatCell` (Flutter, TASK-148) — formats an
 * already-aggregated value for display, never recomputing it. */
export function formatPdfCell(
  value: unknown,
  valueType: ReportFieldConfig['valueType'],
  locale: ExportLocale,
): string {
  if (value === null || value === undefined) return '—';
  switch (valueType) {
    case 'date':
      return formatDateCell(value);
    case 'currency': {
      const number = asNumber(value);
      if (number === null) return String(value);
      const symbol = locale === 'ptBr' ? 'R$ ' : '$ ';
      return `${symbol}${formatDecimal(number, locale, true)}`;
    }
    case 'percentage': {
      const number = asNumber(value);
      if (number === null) return String(value);
      return `${formatDecimal(number, locale, true)}%`;
    }
    case 'number': {
      const number = asNumber(value);
      if (number === null) return String(value);
      return formatDecimal(number, locale, false);
    }
    default:
      return String(value);
  }
}

function periodLabel(filterPeriod: string | undefined): string {
  if (!filterPeriod) return 'Todos os períodos';
  const match = PERIOD_PATTERN.exec(filterPeriod);
  if (!match) return filterPeriod;
  const month = Number(match[2]);
  if (month < 1 || month > 12) return filterPeriod;
  return `${MONTH_NAMES_PT_BR[month - 1]} de ${match[1]}`;
}

function reportTitle(dimensions: readonly string[], metrics: readonly string[], catalog: readonly ReportFieldConfig[]): string {
  const labelFor = (id: string) => catalog.find((field) => field.id === id)?.label ?? id;
  const dimensionLabels = dimensions.map(labelFor).join(' + ');
  const metricLabels = metrics.map(labelFor).join(', ');
  if (!dimensionLabels && !metricLabels) return 'Relatório personalizado';
  if (!dimensionLabels) return metricLabels;
  if (!metricLabels) return dimensionLabels;
  return `${dimensionLabels} — ${metricLabels}`;
}

/** Builds the full PDF buffer (TASK-148): a cover page (title, período,
 * filtros aplicados), a table page (paginated automatically by pdfkit) and
 * a footer with page number + generation instant on every page. [branding]
 * is only ever applied when explicitly configured (a `logoBytes`/
 * `primaryColorHex` present) — otherwise VestiPro's own default identity is
 * used instead. Exported standalone so it can be unit tested without
 * touching Firestore/Storage. */
export async function buildReportPdfBuffer(params: {
  columns: readonly string[];
  rows: readonly Record<string, unknown>[];
  catalog: readonly ReportFieldConfig[];
  locale: ExportLocale;
  dimensions: readonly string[];
  metrics: readonly string[];
  filters: readonly { fieldId: string; value: string }[];
  branding: ReportPdfBranding;
  generatedAt: Date;
}): Promise<Buffer> {
  const { columns, rows, catalog, locale, dimensions, metrics, filters, branding, generatedAt } = params;
  const brandColor = branding.primaryColorHex ?? DEFAULT_BRAND_COLOR;
  const title = reportTitle(dimensions, metrics, catalog);
  const periodFilter = filters.find((filter) => filter.fieldId === 'period')?.value;
  const period = periodLabel(periodFilter);
  const labelFor = (id: string) => catalog.find((field) => field.id === id)?.label ?? id;

  return new Promise<Buffer>((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 40, bufferPages: true });
    const chunks: Buffer[] = [];
    doc.on('data', (chunk: Buffer) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    // ---- Cover page ----
    if (branding.logoBytes) {
      try {
        doc.image(branding.logoBytes, { fit: [160, 60] });
      } catch {
        // A corrupted/unsupported image format never blocks the export —
        // falls back to the text wordmark below instead.
        doc.fontSize(20).fillColor(brandColor).text('VestiPro', { continued: false });
      }
    } else {
      doc.fontSize(20).fillColor(brandColor).text('VestiPro');
    }
    doc.moveDown(4);
    doc.fontSize(24).fillColor(brandColor).text(title, { width: 500 });
    doc.moveDown(0.5);
    doc.fontSize(12).fillColor('black').text(`Período: ${period}`);
    doc.text(`${rows.length} ${rows.length === 1 ? 'linha' : 'linhas'} de dados`);
    if (filters.length > 0) {
      doc.moveDown(1);
      doc.fontSize(12).text('Filtros aplicados', { underline: true });
      for (const filter of filters) {
        doc.fontSize(10).text(`• ${labelFor(filter.fieldId)}: ${filter.value}`);
      }
    }
    doc.moveDown(2);
    doc.fontSize(9).fillColor('gray').text(`Gerado em ${generatedAt.toLocaleString('pt-BR')}`);

    // ---- Table page(s) ----
    doc.addPage();
    const valueTypes = new Map<string, ReportFieldConfig['valueType']>(
      columns.map((id) => [id, resolveColumnValueType(id, catalog)]),
    );
    const headers = columns.map(labelFor);
    const colWidth = (doc.page.width - 80) / Math.max(columns.length, 1);
    const startX = 40;
    let y = doc.y;

    const drawRow = (cells: readonly string[], bold: boolean) => {
      doc.fontSize(8).fillColor(bold ? 'white' : 'black');
      if (bold) {
        doc.rect(startX, y - 2, colWidth * columns.length, 16).fill(brandColor);
        doc.fillColor('white');
      }
      cells.forEach((cell, index) => {
        doc.text(cell, startX + index * colWidth, y, { width: colWidth, height: 16, ellipsis: true });
      });
      y += 16;
    };

    drawRow(headers, true);
    for (const row of rows) {
      if (y > doc.page.height - 60) {
        doc.addPage();
        y = doc.y;
        drawRow(headers, true);
      }
      const cells = columns.map((id) => formatPdfCell(row[id], valueTypes.get(id)!, locale));
      drawRow(cells, false);
    }

    // ---- Footer (page numbers) on every page ----
    const range = doc.bufferedPageRange();
    for (let i = range.start; i < range.start + range.count; i++) {
      doc.switchToPage(i);
      doc.fontSize(8).fillColor('gray').text(
        `Página ${i + 1 - range.start} de ${range.count} · Gerado em ${generatedAt.toLocaleString('pt-BR')}`,
        40,
        doc.page.height - 30,
        { width: doc.page.width - 80, align: 'center' },
      );
    }

    doc.end();
  });
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
 * Large-volume/branded PDF export (TASK-148): reuses the exact same RBAC
 * guard (`assertCanExportReports`), volume ceiling (`MAX_EXPORTABLE_ROWS`),
 * export-link lifetime (`EXPORT_LINK_TTL_MS`) and deterministic file-name
 * builder already established for CSV/XLSX (`export-shared.ts`) — the only
 * things that differ are the file format itself and the branding lookup.
 * Re-runs {@link runReportAggregation} — never trusting a `ReportQueryResult`
 * handed back by the client — under the caller's own role/tenant scope, and
 * independently resolves the organization's own branding server-side
 * (`resolveReportPdfBranding`) instead of trusting anything the client sent
 * for it, then writes the resulting PDF to a
 * `organizations/{organizationId}/exports/{uid}/{fileName}` Storage object
 * restricted to that same caller (`storage.rules`) and returns a
 * short-lived signed URL.
 */
export const exportReportToPdf = onCall<ExportReportInput>(async (request) => {
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
  const filters = Array.isArray(request.data?.filters)
    ? (request.data!.filters as { fieldId: string; value: string }[])
    : [];
  const catalog = catalogForRole(member.roleName as string);
  const generatedAt = new Date();
  const fileName = buildExportFileName({ dimensions, metrics, organizationId, generatedAt, extension: 'pdf' });
  const branding = await resolveReportPdfBranding(db, organizationId);
  const buffer = await buildReportPdfBuffer({
    columns,
    rows,
    catalog,
    locale,
    dimensions,
    metrics,
    filters,
    branding,
    generatedAt,
  });

  const objectPath = `organizations/${organizationId}/exports/${request.auth.uid}/${fileName}`;
  const bucket = getStorage().bucket();
  const file = bucket.file(objectPath);
  const expiresAt = new Date(generatedAt.getTime() + EXPORT_LINK_TTL_MS);
  await file.save(buffer, {
    contentType: 'application/pdf',
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
