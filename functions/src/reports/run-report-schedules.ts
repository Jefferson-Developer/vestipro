import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { REPORT_ROLES, catalogForRole } from './report-catalog';
import {
  runReportAggregation,
  type ReportAggregationMember,
} from './execute-report-query';
import { rowsToCsv } from './export-report-to-csv';
import { rowsToXlsxBuffer } from './export-report-to-xlsx';
import {
  buildReportPdfBuffer,
  resolveReportPdfBranding,
  type ReportPdfBranding,
} from './export-report-to-pdf';
import {
  buildExportFileName,
  EXPORT_LINK_TTL_MS,
  MAX_EXPORTABLE_ROWS,
  parseExportLocale,
  REPORT_EXPORT_ROLES,
  type ExportLocale,
} from './export-shared';
import {
  computeNextRunAt,
  cycleKeyFor,
  type ReportScheduleFrequency,
} from './report-schedules-shared';

/**
 * Periodic delivery of every due `ReportSchedule` (TASK-149): re-executes
 * the referenced `SavedReport`'s `ReportDefinition` (TASK-144/TASK-145)
 * independently for each recipient — never trusting the schedule creator's
 * own role/scope — and uploads the export in the schedule's configured
 * format (CSV/XLSX/PDF, TASK-146/TASK-147/TASK-148), reusing exactly the
 * same encoders/RBAC/volume-ceiling logic those callables already
 * established.
 *
 * Runs frequently (every 15 minutes) rather than exactly at each schedule's
 * due minute — a schedule fires on the first run whose `now` is at or past
 * its `nextRunAt`, so actual delivery time may lag the configured time by up
 * to ~15 minutes. Acceptable for a report digest; `tasks.md` sets no tighter
 * SLA for TASK-149.
 */
export const runReportSchedules = onSchedule(
  {
    schedule: 'every 15 minutes',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    const summary = await runReportSchedulesHandler(getFirestore(), new Date());
    logger.info('runReportSchedules finished', summary);
  },
);

export interface RunReportSchedulesSummary {
  schedulesClaimed: number;
  schedulesSkipped: number;
  deliveriesSent: number;
  deliveriesFailed: number;
}

interface ClaimedSchedule {
  ref: DocumentReference;
  id: string;
  organizationId: string;
  companyId: string;
  savedReportId: string;
  format: 'csv' | 'xlsx' | 'pdf';
  locale: ExportLocale;
  recipientUserIds: string[];
  cycleKey: string;
}

interface CycleOutcome {
  deliveriesSent: number;
  deliveriesFailed: number;
  status: 'success' | 'partialFailure' | 'failure';
  error: string | null;
}

/**
 * Iterates every non-deleted/active Organization looking for `reportSchedules`
 * due to run (`status == 'active' && nextRunAt <= now`) — same
 * per-organization iteration `expireStockReservations`/
 * `generateInsightsScheduled` already use, instead of a cross-tenant
 * `collectionGroup` query.
 */
export async function runReportSchedulesHandler(
  db: Firestore,
  now: Date,
): Promise<RunReportSchedulesSummary> {
  const summary: RunReportSchedulesSummary = {
    schedulesClaimed: 0,
    schedulesSkipped: 0,
    deliveriesSent: 0,
    deliveriesFailed: 0,
  };

  const organizationsSnapshot = await db.collection('organizations').get();
  for (const organizationDoc of organizationsSnapshot.docs) {
    const orgData = organizationDoc.data();
    if (orgData.deletedAt != null || orgData.status === 'inactive') continue;

    const dueSnapshot = await organizationDoc.ref
      .collection('reportSchedules')
      .where('status', '==', 'active')
      .where('nextRunAt', '<=', Timestamp.fromDate(now))
      .get();

    for (const scheduleSnapshot of dueSnapshot.docs) {
      const claimed = await claimScheduleCycle(db, scheduleSnapshot.ref, now);
      if (!claimed) {
        summary.schedulesSkipped += 1;
        continue;
      }
      summary.schedulesClaimed += 1;
      const outcome = await executeReportScheduleCycle(db, claimed);
      summary.deliveriesSent += outcome.deliveriesSent;
      summary.deliveriesFailed += outcome.deliveriesFailed;
      await finalizeScheduleCycle(claimed.ref, outcome);
    }
  }

  return summary;
}

/**
 * Atomically claims one due cycle: verifies (fresh, inside the transaction)
 * that the schedule is still `active`, still due and — the actual
 * idempotency guard — that `lastRunCycleKey` does not already match this
 * cycle's key (meaning a previous invocation, including a Cloud Scheduler
 * retry racing this one, already claimed it). Advances `nextRunAt` and
 * records `lastRunCycleKey` *before* any delivery is generated, so even a
 * mid-flight crash never causes this exact cycle to be claimed twice —
 * worst case, that one cycle's delivery is skipped instead of duplicated,
 * a deliberate trade-off ("nenhum agendamento duplica envios em caso de
 * retry", TASK-149's non-negotiable requirement).
 */
async function claimScheduleCycle(
  db: Firestore,
  scheduleRef: DocumentReference,
  now: Date,
): Promise<ClaimedSchedule | null> {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(scheduleRef);
    const data = snapshot.data();
    if (!snapshot.exists || !data) return null;
    if (data.status !== 'active') return null;

    const dueAt = (data.nextRunAt as Timestamp).toDate();
    if (dueAt.getTime() > now.getTime()) return null;

    const cycleKey = cycleKeyFor(dueAt);
    if (data.lastRunCycleKey === cycleKey) return null;

    const nextRunAt = computeNextRunAt(
      {
        frequency: data.frequency as ReportScheduleFrequency,
        weekday: (data.weekday as number | null | undefined) ?? null,
        dayOfMonth: (data.dayOfMonth as number | null | undefined) ?? null,
        hour: data.hour as number,
        minute: data.minute as number,
      },
      dueAt,
    );

    transaction.update(scheduleRef, {
      nextRunAt: Timestamp.fromDate(nextRunAt),
      lastRunAt: Timestamp.fromDate(now),
      lastRunCycleKey: cycleKey,
      // Transiently `null` ("em execução") until `finalizeScheduleCycle`
      // overwrites it with the real outcome a few seconds later — never
      // left stuck at an optimistic value if the function crashes
      // mid-flight.
      lastRunStatus: null,
      lastRunError: null,
      updatedAt: Timestamp.fromDate(now),
      updatedBy: 'report-schedule-runner',
      version: FieldValue.increment(1),
    });

    return {
      ref: scheduleRef,
      id: scheduleRef.id,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      savedReportId: data.savedReportId as string,
      format: data.format as 'csv' | 'xlsx' | 'pdf',
      locale: parseExportLocale(data.locale),
      recipientUserIds: Array.isArray(data.recipientUserIds)
        ? (data.recipientUserIds as string[])
        : [],
      cycleKey,
    };
  });
}

async function finalizeScheduleCycle(
  scheduleRef: DocumentReference,
  outcome: CycleOutcome,
): Promise<void> {
  await scheduleRef.update({
    lastRunStatus: outcome.status,
    lastRunError: outcome.error,
    updatedAt: Timestamp.now(),
  });
}

/**
 * Delivers one claimed cycle to every configured recipient, independently:
 * one recipient's failure (inactive membership, insufficient role, an
 * aggregation error) is recorded and skipped, never aborting delivery to
 * the remaining recipients ("Falha de geração/envio é registrada e visível
 * ao criador do agendamento, nunca falha silenciosa", TASK-149).
 */
async function executeReportScheduleCycle(
  db: Firestore,
  schedule: ClaimedSchedule,
): Promise<CycleOutcome> {
  const savedReportSnapshot = await db
    .collection('organizations')
    .doc(schedule.organizationId)
    .collection('savedReports')
    .doc(schedule.savedReportId)
    .get();
  const savedReport = savedReportSnapshot.data();
  if (!savedReportSnapshot.exists || !savedReport) {
    // TASK-145's `DeleteSavedReport` already blocks deleting a saved report
    // an active schedule references — this branch only ever guards a data
    // inconsistency reached some other way (e.g. manual ops), never the
    // normal client flow.
    await recordDelivery(db, schedule, {
      recipientUserId: 'n/a',
      status: 'failed',
      reason: 'saved_report_not_found',
    });
    return {
      deliveriesSent: 0,
      deliveriesFailed: 1,
      status: 'failure',
      error: 'A visualização salva referenciada não existe mais.',
    };
  }
  const definition = savedReport.definition as Record<string, unknown>;
  const dimensions = Array.isArray(definition.dimensions)
    ? (definition.dimensions as string[])
    : [];
  const metrics = Array.isArray(definition.metrics)
    ? (definition.metrics as string[])
    : [];
  const filters = Array.isArray(definition.filters)
    ? (definition.filters as { fieldId: string; value: string }[])
    : [];

  let deliveriesSent = 0;
  let deliveriesFailed = 0;
  let firstError: string | null = null;
  let brandingCache: ReportPdfBranding | null = null;

  for (const recipientUserId of schedule.recipientUserIds) {
    try {
      const memberSnapshot = await db
        .collection('organizations')
        .doc(schedule.organizationId)
        .collection('members')
        .doc(recipientUserId)
        .get();
      const member = memberSnapshot.data();
      if (!memberSnapshot.exists || !member || member.status !== 'active') {
        deliveriesFailed += 1;
        firstError ??= 'Um ou mais destinatários não estão mais ativos.';
        await recordDelivery(db, schedule, {
          recipientUserId,
          status: 'skipped',
          reason: 'recipient_inactive',
        });
        continue;
      }

      // "Agendamento com dado financeiro sensível respeita o RBAC do
      // destinatário no momento do envio, não o RBAC de quem criou o
      // agendamento" (TASK-149) — every check below re-resolves the
      // *recipient's* own current role, never the schedule creator's.
      const roleName = member.roleName as string;
      if (!REPORT_ROLES.has(roleName)) {
        deliveriesFailed += 1;
        firstError ??= 'Um ou mais destinatários não têm perfil habilitado '
          + 'para relatórios.';
        await recordDelivery(db, schedule, {
          recipientUserId,
          status: 'skipped',
          reason: 'recipient_cannot_view_reports',
        });
        continue;
      }
      if (!REPORT_EXPORT_ROLES.has(roleName)) {
        deliveriesFailed += 1;
        firstError ??= 'Um ou mais destinatários não podem exportar '
          + 'relatórios.';
        await recordDelivery(db, schedule, {
          recipientUserId,
          status: 'skipped',
          reason: 'recipient_cannot_export_reports',
        });
        continue;
      }

      const aggregationMember: ReportAggregationMember = {
        roleName,
        teamIds: Array.isArray(member.teamIds)
          ? (member.teamIds as string[])
          : undefined,
      };
      const { columns, rows } = await runReportAggregation({
        db,
        organizationId: schedule.organizationId,
        companyId: schedule.companyId,
        member: aggregationMember,
        authUid: recipientUserId,
        data: definition as {
          dimensions?: unknown;
          metrics?: unknown;
          filters?: unknown;
          groupBy?: unknown;
          sortBy?: unknown;
          comparisonPeriod?: unknown;
        },
      });
      if (rows.length > MAX_EXPORTABLE_ROWS) {
        deliveriesFailed += 1;
        firstError ??= 'O resultado excede o limite máximo de linhas '
          + 'exportáveis.';
        await recordDelivery(db, schedule, {
          recipientUserId,
          status: 'failed',
          reason: 'result_too_large',
        });
        continue;
      }

      const generatedAt = new Date();
      const fileName = buildExportFileName({
        dimensions,
        metrics,
        organizationId: schedule.organizationId,
        generatedAt,
        extension: schedule.format,
      });

      let buffer: Buffer;
      let contentType: string;
      if (schedule.format === 'csv') {
        buffer = Buffer.from(rowsToCsv(columns, rows, schedule.locale), 'utf8');
        contentType = 'text/csv; charset=utf-8';
      } else if (schedule.format === 'xlsx') {
        const catalog = catalogForRole(roleName);
        buffer = await rowsToXlsxBuffer(columns, rows, catalog, schedule.locale);
        contentType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else {
        const catalog = catalogForRole(roleName);
        brandingCache ??= await resolveReportPdfBranding(
          db,
          schedule.organizationId,
        );
        buffer = await buildReportPdfBuffer({
          columns,
          rows,
          catalog,
          locale: schedule.locale,
          dimensions,
          metrics,
          filters,
          branding: brandingCache,
          generatedAt,
        });
        contentType = 'application/pdf';
      }

      const objectPath =
        `organizations/${schedule.organizationId}/exports/${recipientUserId}/${fileName}`;
      const bucket = getStorage().bucket();
      const file = bucket.file(objectPath);
      const expiresAt = new Date(generatedAt.getTime() + EXPORT_LINK_TTL_MS);
      await file.save(buffer, {
        contentType,
        metadata: {
          cacheControl: 'private, max-age=0',
          metadata: {
            requestedBy: 'report-schedule-runner',
            scheduleId: schedule.id,
          },
        },
      });
      const [downloadUrl] = await file.getSignedUrl({
        action: 'read',
        expires: expiresAt,
      });

      await recordDelivery(db, schedule, {
        recipientUserId,
        status: 'delivered',
        fileName,
        downloadUrl,
        expiresAt,
        rowCount: rows.length,
      });
      deliveriesSent += 1;
    } catch (error) {
      deliveriesFailed += 1;
      const message = error instanceof Error ? error.message : String(error);
      firstError ??= message;
      logger.error('runReportSchedules failed to deliver to a recipient', {
        organizationId: schedule.organizationId,
        scheduleId: schedule.id,
        recipientUserId,
        error,
      });
      await recordDelivery(db, schedule, {
        recipientUserId,
        status: 'failed',
        reason: message,
      });
    }
  }

  const status: CycleOutcome['status'] =
    deliveriesFailed === 0
      ? 'success'
      : deliveriesSent === 0
        ? 'failure'
        : 'partialFailure';

  return {
    deliveriesSent,
    deliveriesFailed,
    status,
    error: status === 'success' ? null : firstError,
  };
}

/**
 * Append-only outcome log, one document per recipient per cycle
 * (`organizations/{organizationId}/reportScheduleDeliveries`) — the
 * "notificação interna" queue TASK-151 (Central de Notificações, not built
 * yet) is expected to read from, and in the meantime what
 * `firestore.rules` already lets a recipient (their own deliveries) or a
 * `report.schedule` holder (every delivery, to diagnose a failure) read
 * directly. The document id is deterministic
 * (`{scheduleId}_{cycleKey}_{recipientUserId}`) as a second, defense-in-depth
 * idempotency guard on top of the claim transaction: even if this function
 * were ever invoked twice for the same already-claimed cycle, the second
 * call's `recordDelivery` would just overwrite the same document instead of
 * creating a duplicate.
 */
async function recordDelivery(
  db: Firestore,
  schedule: ClaimedSchedule,
  params: {
    recipientUserId: string;
    status: 'delivered' | 'failed' | 'skipped';
    reason?: string;
    fileName?: string;
    downloadUrl?: string;
    expiresAt?: Date;
    rowCount?: number;
  },
): Promise<void> {
  const deliveryId = sanitizeForId(
    `${schedule.id}_${schedule.cycleKey}_${params.recipientUserId}`,
  );
  await db
    .collection('organizations')
    .doc(schedule.organizationId)
    .collection('reportScheduleDeliveries')
    .doc(deliveryId)
    .set({
      organizationId: schedule.organizationId,
      scheduleId: schedule.id,
      savedReportId: schedule.savedReportId,
      recipientUserId: params.recipientUserId,
      cycleKey: schedule.cycleKey,
      status: params.status,
      format: schedule.format,
      reason: params.reason ?? null,
      fileName: params.fileName ?? null,
      downloadUrl: params.downloadUrl ?? null,
      expiresAt: params.expiresAt ? Timestamp.fromDate(params.expiresAt) : null,
      rowCount: params.rowCount ?? null,
      generatedAt: Timestamp.now(),
    });
}

function sanitizeForId(value: string): string {
  return value.replace(/[^a-zA-Z0-9_-]/g, '-');
}
