/**
 * Pure scheduling math shared by `runReportSchedules` (TASK-149) — kept
 * dependency-free (no `firebase-admin`) so it can be unit tested without an
 * Emulator, mirroring `ReportScheduleNextRunCalculator`
 * (`lib/features/reports/domain/services/report_schedule_next_run_calculator.dart`)
 * field-for-field. Both sides must stay in sync manually.
 */

export type ReportScheduleFrequency = 'daily' | 'weekly' | 'monthly';

export interface ReportScheduleTiming {
  frequency: ReportScheduleFrequency;
  /** ISO weekday, 1 = segunda-feira .. 7 = domingo. Only read when
   * `frequency === 'weekly'`. */
  weekday?: number | null;
  /** 1-28 (capped so every month always has a matching day). Only read when
   * `frequency === 'monthly'`. */
  dayOfMonth?: number | null;
  hour: number;
  minute: number;
}

/** Brazil has not observed daylight saving time since 2019, so
 * `America/Sao_Paulo` — the timezone every scheduled Cloud Function in this
 * codebase already runs in (`generateInsightsScheduled`,
 * `expireStockReservations`, `recomputeMonthlyAggregatesScheduled`) — is
 * treated as a fixed UTC-3 offset here rather than pulling in a full
 * timezone database. */
export const SAO_PAULO_UTC_OFFSET_HOURS = 3;
const SAO_PAULO_OFFSET_MS = SAO_PAULO_UTC_OFFSET_HOURS * 60 * 60 * 1000;

function toSaoPauloWallClock(instant: Date): Date {
  return new Date(instant.getTime() - SAO_PAULO_OFFSET_MS);
}

function fromSaoPauloWallClock(wallClock: Date): Date {
  return new Date(wallClock.getTime() + SAO_PAULO_OFFSET_MS);
}

function isoWeekday(date: Date): number {
  const day = date.getUTCDay(); // 0 = domingo .. 6 = sábado
  return day === 0 ? 7 : day;
}

/**
 * Computes when a `ReportSchedule` (TASK-149) is next due, expressed as a
 * UTC `Date` — always strictly after `from`. Mirrors
 * `ReportScheduleNextRunCalculator.compute` on the Flutter side
 * field-for-field.
 */
export function computeNextRunAt(
  timing: ReportScheduleTiming,
  from: Date,
): Date {
  const fromWallClock = toSaoPauloWallClock(from);
  let candidate = new Date(
    Date.UTC(
      fromWallClock.getUTCFullYear(),
      fromWallClock.getUTCMonth(),
      fromWallClock.getUTCDate(),
      timing.hour,
      timing.minute,
      0,
      0,
    ),
  );

  switch (timing.frequency) {
    case 'daily': {
      if (candidate.getTime() <= fromWallClock.getTime()) {
        candidate = new Date(candidate.getTime() + 24 * 60 * 60 * 1000);
      }
      break;
    }
    case 'weekly': {
      const targetWeekday = timing.weekday ?? 1;
      let deltaDays = (targetWeekday - isoWeekday(candidate) + 7) % 7;
      if (deltaDays === 0 && candidate.getTime() <= fromWallClock.getTime()) {
        deltaDays = 7;
      }
      candidate.setUTCDate(candidate.getUTCDate() + deltaDays);
      break;
    }
    case 'monthly': {
      const targetDay = Math.min(Math.max(timing.dayOfMonth ?? 1, 1), 28);
      candidate = new Date(
        Date.UTC(
          fromWallClock.getUTCFullYear(),
          fromWallClock.getUTCMonth(),
          targetDay,
          timing.hour,
          timing.minute,
          0,
          0,
        ),
      );
      if (candidate.getTime() <= fromWallClock.getTime()) {
        candidate = new Date(
          Date.UTC(
            fromWallClock.getUTCFullYear(),
            fromWallClock.getUTCMonth() + 1,
            targetDay,
            timing.hour,
            timing.minute,
            0,
            0,
          ),
        );
      }
      break;
    }
  }

  return fromSaoPauloWallClock(candidate);
}

/**
 * A stable identifier for the scheduled cycle whose due instant is
 * `nextRunAt` — the idempotency key `runReportSchedules`'s claim
 * transaction checks before ever generating a delivery, and the one a
 * Cloud Scheduler retry must resolve to identically so it never
 * double-sends. Mirrors
 * `ReportScheduleNextRunCalculator.cycleKeyFor` on the Flutter side.
 */
export function cycleKeyFor(nextRunAt: Date): string {
  return nextRunAt.toISOString();
}
