import type { DocumentData } from 'firebase-admin/firestore';

/**
 * Server-side port of the exact TASK-154/TASK-155 gates every client-side
 * notification generator already calls before writing an `AppNotification`
 * (`ShouldDispatchNotificationUseCase`/`ResolveNotificationDeliveryTimeUseCase`,
 * `lib/core/notifications/domain/usecases/`) — every existing generator in
 * this codebase runs on-device (Dart), never from a Cloud Function, so
 * `generateDailyRepSummary` (the first *server-side* notification generator)
 * needs its own reading of `organizations/{organizationId}/communicationPreferences/{userId}`
 * to honor the exact same two rules: `tasks.md`/TASK-188: "Respeitar
 * preferências de comunicação e quiet hours do usuário ao disparar a
 * notificação". Both functions below are deliberately pure ports of
 * `lib/core/notifications/domain/entities/quiet_hours.dart`'s own
 * `isActiveAt`/`nextAllowedInstant` and
 * `communication_preferences.dart`'s own `allows` — kept in lockstep with
 * that Dart source rather than reinvented; a future change to either must
 * update both sides.
 */

const MINUTES_PER_DAY = 24 * 60;

/** Raw shape of `communicationPreferences/{userId}`'s own `quietHours` map
 * (`CommunicationPreferencesDto.quietHours`'s own doc comment) — `null`/
 * missing degrades to "disabled", the same default `CommunicationPreferences.defaults`
 * already documents. */
export interface DailyRepSummaryQuietHours {
  enabled: boolean;
  startMinuteOfDay: number;
  endMinuteOfDay: number;
  /** `DateTime.weekday` values, 1 (Monday) .. 7 (Sunday). */
  activeWeekdays: readonly number[];
  timezoneOffsetMinutes: number | null;
}

const DISABLED_QUIET_HOURS: DailyRepSummaryQuietHours = {
  enabled: false,
  startMinuteOfDay: 22 * 60,
  endMinuteOfDay: 7 * 60,
  activeWeekdays: [1, 2, 3, 4, 5, 6, 7],
  timezoneOffsetMinutes: null,
};

/** Parses `communicationPreferences/{userId}`'s raw document data into
 * {@link DailyRepSummaryQuietHours} (disabled default for a missing/malformed
 * field — never throws on an old/partial document, mirroring
 * `CommunicationPreferencesMapper`'s own degrade-to-default behavior) and
 * whether the `commercial` category still allows the `inApp` channel. */
export function parseDailyRepSummaryPreferences(data: DocumentData | undefined): {
  allowsCommercialInApp: boolean;
  quietHours: DailyRepSummaryQuietHours;
} {
  const categories = data?.categories;
  const commercialFrequencies =
    categories && typeof categories === 'object'
      ? (categories as Record<string, unknown>).commercial
      : undefined;
  const inAppFrequency =
    commercialFrequencies && typeof commercialFrequencies === 'object'
      ? (commercialFrequencies as Record<string, unknown>).inApp
      : undefined;
  // Absent/malformed degrades to "allowed" (the documented safe default,
  // `immediate`, is anything but `disabled`) — never silently swallows a
  // notification the recipient never actually muted.
  const allowsCommercialInApp = inAppFrequency !== 'disabled';

  const rawQuietHours = data?.quietHours;
  const quietHours: DailyRepSummaryQuietHours =
    rawQuietHours && typeof rawQuietHours === 'object'
      ? {
          enabled: (rawQuietHours as Record<string, unknown>).enabled === true,
          startMinuteOfDay: normalizedMinuteOfDay(
            (rawQuietHours as Record<string, unknown>).startMinuteOfDay,
            DISABLED_QUIET_HOURS.startMinuteOfDay,
          ),
          endMinuteOfDay: normalizedMinuteOfDay(
            (rawQuietHours as Record<string, unknown>).endMinuteOfDay,
            DISABLED_QUIET_HOURS.endMinuteOfDay,
          ),
          activeWeekdays: normalizedWeekdays(
            (rawQuietHours as Record<string, unknown>).activeWeekdays,
          ),
          timezoneOffsetMinutes:
            typeof (rawQuietHours as Record<string, unknown>).timezoneOffsetMinutes === 'number'
              ? ((rawQuietHours as Record<string, unknown>).timezoneOffsetMinutes as number)
              : null,
        }
      : DISABLED_QUIET_HOURS;

  return { allowsCommercialInApp, quietHours };
}

function normalizedMinuteOfDay(value: unknown, fallback: number): number {
  return typeof value === 'number' && value >= 0 && value < MINUTES_PER_DAY ? value : fallback;
}

function normalizedWeekdays(value: unknown): readonly number[] {
  if (!Array.isArray(value)) return DISABLED_QUIET_HOURS.activeWeekdays;
  const weekdays = value.filter(
    (item): item is number => typeof item === 'number' && item >= 1 && item <= 7,
  );
  return weekdays.length > 0 ? weekdays : DISABLED_QUIET_HOURS.activeWeekdays;
}

function toLocal(instantUtc: Date, quietHours: DailyRepSummaryQuietHours): Date {
  const offsetMinutes = quietHours.timezoneOffsetMinutes ?? 0;
  return new Date(instantUtc.getTime() + offsetMinutes * 60_000);
}

function toUtc(localInstant: Date, quietHours: DailyRepSummaryQuietHours): Date {
  const offsetMinutes = quietHours.timezoneOffsetMinutes ?? 0;
  return new Date(localInstant.getTime() - offsetMinutes * 60_000);
}

/** Port of `QuietHours.isActiveAt` (Dart) — every date below is manipulated
 * with its UTC getters/setters only, since [toLocal] already applied the
 * recipient's own raw offset, exactly mirroring the Dart source's own
 * `DateTime.utc(...)`-based arithmetic. */
export function isDailyRepSummaryQuietHoursActiveAt(
  quietHours: DailyRepSummaryQuietHours,
  instantUtc: Date,
): boolean {
  if (!quietHours.enabled) return false;
  const local = toLocal(instantUtc, quietHours);
  const minuteOfDay = local.getUTCHours() * 60 + local.getUTCMinutes();
  const weekday = isoWeekday(local);
  const crossesMidnight = quietHours.startMinuteOfDay > quietHours.endMinuteOfDay;

  if (!crossesMidnight) {
    return (
      minuteOfDay >= quietHours.startMinuteOfDay &&
      minuteOfDay < quietHours.endMinuteOfDay &&
      quietHours.activeWeekdays.includes(weekday)
    );
  }

  if (minuteOfDay >= quietHours.startMinuteOfDay) {
    return quietHours.activeWeekdays.includes(weekday);
  }
  if (minuteOfDay < quietHours.endMinuteOfDay) {
    const previousLocal = new Date(local.getTime() - 24 * 60 * 60_000);
    return quietHours.activeWeekdays.includes(isoWeekday(previousLocal));
  }
  return false;
}

/** Port of `QuietHours.nextAllowedInstant` (Dart). Only meaningful when
 * {@link isDailyRepSummaryQuietHoursActiveAt} is `true` for the same
 * [instantUtc]. */
export function nextAllowedInstantAfterDailyRepSummaryQuietHours(
  quietHours: DailyRepSummaryQuietHours,
  instantUtc: Date,
): Date {
  const local = toLocal(instantUtc, quietHours);
  const minuteOfDay = local.getUTCHours() * 60 + local.getUTCMinutes();
  const localMidnight = new Date(
    Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate()),
  );
  const crossesMidnight = quietHours.startMinuteOfDay > quietHours.endMinuteOfDay;
  const endsNextCalendarDay = crossesMidnight && minuteOfDay >= quietHours.startMinuteOfDay;
  const endLocalDate = endsNextCalendarDay
    ? new Date(localMidnight.getTime() + 24 * 60 * 60_000)
    : localMidnight;
  const endLocal = new Date(endLocalDate.getTime() + quietHours.endMinuteOfDay * 60_000);
  return toUtc(endLocal, quietHours);
}

/** `1` (Monday) .. `7` (Sunday), matching Dart's `DateTime.weekday` — a plain
 * UTC `Date` treats Sunday as `0`, so this shifts it into the same 1-7 range
 * `activeWeekdays` is stored in. */
function isoWeekday(date: Date): number {
  const jsWeekday = date.getUTCDay();
  return jsWeekday === 0 ? 7 : jsWeekday;
}

/** Resolves this notification's `deliverAt` (`null` = deliver now) — the
 * daily rep summary is always `informative` priority (never `critical`), so
 * quiet hours always apply, mirroring every other non-critical generator
 * (`ProcessCrmTaskReminderUseCase`). */
export function resolveDailyRepSummaryDeliveryTime(
  quietHours: DailyRepSummaryQuietHours,
  instantUtc: Date,
): Date | null {
  if (!isDailyRepSummaryQuietHoursActiveAt(quietHours, instantUtc)) return null;
  return nextAllowedInstantAfterDailyRepSummaryQuietHours(quietHours, instantUtc);
}
