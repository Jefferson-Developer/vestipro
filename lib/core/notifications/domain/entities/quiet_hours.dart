/// A user's own quiet-hours window (TASK-155): the local time range, on the
/// days configured, during which non-critical notifications must not
/// interrupt them.
///
/// Distinct from [CommunicationPreferences]'s own category/channel frequency
/// settings — quiet hours suppress *when* a notification is allowed to reach
/// the user (any category, evaluated only after
/// [CommunicationPreferences.allows] already let it through), not *what*
/// category/channel is muted.
///
/// Every instant this class evaluates is expressed as the recipient's own
/// local time, computed from [timezoneOffsetMinutes] — the raw UTC offset of
/// the recipient's own device at the moment it last synced (TASK-155's
/// "nunca assumir o timezone do servidor" requirement) — never the caller's
/// own timezone (e.g. the Cloud Function/backend runtime's), and never a
/// full IANA timezone database lookup: the codebase has no timezone-database
/// dependency today, and a raw offset re-captured on every device timezone
/// change (`SyncDeviceTimezoneUseCase`) is enough to place "now" correctly on
/// the recipient's own clock without adding one.
final class QuietHours {
  const QuietHours({
    this.enabled = false,
    this.startMinuteOfDay = _defaultStartMinuteOfDay,
    this.endMinuteOfDay = _defaultEndMinuteOfDay,
    this.activeWeekdays = kAllWeekdays,
    this.timezoneOffsetMinutes,
    this.timezoneUpdatedAt,
  }) : assert(
         startMinuteOfDay >= 0 && startMinuteOfDay < _minutesPerDay,
         'startMinuteOfDay must be within a single day (0-1439).',
       ),
       assert(
         endMinuteOfDay >= 0 && endMinuteOfDay < _minutesPerDay,
         'endMinuteOfDay must be within a single day (0-1439).',
       ),
       assert(
         startMinuteOfDay != endMinuteOfDay,
         'startMinuteOfDay and endMinuteOfDay must not be equal — an empty '
         'or full-day window is not a valid quiet-hours configuration.',
       );

  static const int _minutesPerDay = 24 * 60;

  /// 22:00 — the documented safe default (TASK-155) offered the first time a
  /// user opens the quiet-hours settings, before they ever change it.
  static const int _defaultStartMinuteOfDay = 22 * 60;

  /// 07:00.
  static const int _defaultEndMinuteOfDay = 7 * 60;

  /// [DateTime.weekday] values (1 = Monday .. 7 = Sunday) — every day active
  /// by default, so turning quiet hours on protects every night, not just
  /// weekdays, until the user narrows it down.
  static const Set<int> kAllWeekdays = <int>{1, 2, 3, 4, 5, 6, 7};

  /// Whether this recipient has quiet hours turned on at all. `false` by
  /// default (opt-in) — same "never silently change existing behavior"
  /// precedent [CommunicationPreferences.defaults] already sets for every
  /// other TASK-154 preference.
  final bool enabled;

  /// Inclusive start, in minutes since local midnight (0-1439).
  final int startMinuteOfDay;

  /// Exclusive end, in minutes since local midnight (0-1439). May be less
  /// than [startMinuteOfDay] — that is what makes the window cross
  /// midnight (e.g. 22:00-07:00), the common case for quiet hours.
  final int endMinuteOfDay;

  /// The [DateTime.weekday] values this window applies to. For an
  /// overnight window, the weekday checked is the day the window *started*
  /// on (see [isActiveAt]'s doc) — e.g. a Friday-only window still covers
  /// the early hours of Saturday morning.
  final Set<int> activeWeekdays;

  /// The recipient device's own UTC offset in minutes
  /// (`DateTime.now().timeZoneOffset.inMinutes`), captured and kept in sync
  /// by `SyncDeviceTimezoneUseCase` — `null` until the very first sync, in
  /// which case [isActiveAt] treats the recipient's local time as UTC
  /// (the least-wrong assumption before any real device has ever reported
  /// its own offset).
  final int? timezoneOffsetMinutes;

  /// When [timezoneOffsetMinutes] was last captured/confirmed unchanged.
  final DateTime? timezoneUpdatedAt;

  bool get crossesMidnight => startMinuteOfDay > endMinuteOfDay;

  QuietHours copyWith({
    bool? enabled,
    int? startMinuteOfDay,
    int? endMinuteOfDay,
    Set<int>? activeWeekdays,
    int? timezoneOffsetMinutes,
    DateTime? timezoneUpdatedAt,
  }) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay ?? this.endMinuteOfDay,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      timezoneUpdatedAt: timezoneUpdatedAt ?? this.timezoneUpdatedAt,
    );
  }

  DateTime _toLocal(DateTime instantUtc) =>
      instantUtc.toUtc().add(Duration(minutes: timezoneOffsetMinutes ?? 0));

  DateTime _toUtc(DateTime localInstant) =>
      localInstant.subtract(Duration(minutes: timezoneOffsetMinutes ?? 0));

  /// Whether [instantUtc] (any UTC instant — never assumed already local)
  /// falls inside this quiet-hours window, evaluated at the recipient's own
  /// local time. Always `false` when [enabled] is `false`.
  ///
  /// For an overnight window (e.g. 22:00-07:00): the evening part (minute
  /// of day >= [startMinuteOfDay]) is checked against *that* local day's
  /// weekday; the morning part after midnight (minute of day <
  /// [endMinuteOfDay]) is checked against the *previous* local day's
  /// weekday — the window "belongs" to the day it started on, so a
  /// Friday-only window still silences Saturday's early hours, not Friday's.
  bool isActiveAt(DateTime instantUtc) {
    if (!enabled) return false;
    final local = _toLocal(instantUtc);
    final minuteOfDay = local.hour * 60 + local.minute;

    if (!crossesMidnight) {
      return minuteOfDay >= startMinuteOfDay &&
          minuteOfDay < endMinuteOfDay &&
          activeWeekdays.contains(local.weekday);
    }

    if (minuteOfDay >= startMinuteOfDay) {
      return activeWeekdays.contains(local.weekday);
    }
    if (minuteOfDay < endMinuteOfDay) {
      final previousLocalWeekday = local
          .subtract(const Duration(days: 1))
          .weekday;
      return activeWeekdays.contains(previousLocalWeekday);
    }
    return false;
  }

  /// The next UTC instant at which this quiet-hours window ends, for the
  /// window instance that contains [instantUtc] — only meaningful when
  /// [isActiveAt] is `true` for the same instant.
  ///
  /// Used to compute `AppNotification.deliverAt`: a notification suppressed
  /// by quiet hours is written now (never lost, never re-evaluated later by
  /// a background job that might not run) with [deliverAt] set to this
  /// instant, and simply becomes visible in the central de notificações the
  /// moment `NotificationInboxRepository.listForUser` is called again after
  /// quiet hours end (see its own doc).
  DateTime nextAllowedInstant(DateTime instantUtc) {
    final local = _toLocal(instantUtc);
    final minuteOfDay = local.hour * 60 + local.minute;
    final localMidnight = DateTime.utc(local.year, local.month, local.day);
    final endsNextCalendarDay =
        crossesMidnight && minuteOfDay >= startMinuteOfDay;
    final endLocalDate = endsNextCalendarDay
        ? localMidnight.add(const Duration(days: 1))
        : localMidnight;
    final endLocal = endLocalDate.add(Duration(minutes: endMinuteOfDay));
    return _toUtc(endLocal);
  }
}
