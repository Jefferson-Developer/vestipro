import 'app_notification.dart';
import 'quiet_hours.dart';

/// Every surface a notification can actually reach the user through
/// (TASK-154). `inApp` is the central de notificações internas (TASK-151) —
/// the only channel every generator (TASK-152/TASK-153, and TASK-155 later)
/// actually writes to today; `push`/`email` are modeled and persisted now so
/// the preference exists ahead of whichever future task wires real push/
/// e-mail delivery, without a breaking schema change then.
enum CommunicationChannel { push, email, inApp }

/// How often a category × channel combination may actually notify the user.
enum CommunicationFrequency {
  /// Notifies as soon as the triggering event happens — today's behavior for
  /// every existing generator (TASK-152/TASK-153).
  immediate,

  /// Batched into a once-a-day summary instead of interrupting immediately.
  /// Persisted as a valid user choice; the batching engine itself is out of
  /// this task's scope (no scheduled Cloud Function exists yet to actually
  /// deliver a digest) — see `ShouldDispatchNotificationUseCase`'s doc for
  /// how a generator behaves in the meantime.
  dailyDigest,

  /// The user opted out entirely for this category × channel combination.
  disabled,
}

/// The safe default every category starts from before the user ever opens
/// the preferences screen (TASK-154's documented default): push and the
/// in-app central both `immediate`, e-mail `disabled`. Applied identically
/// to `crm`, `commercial` and `system` — critical system alerts stay on by
/// default same as everything else, they just additionally can never be
/// fully turned off (see [CommunicationPreferences.hasSystemCategoryFullyDisabled]).
const CategoryCommunicationPreference kDefaultCategoryCommunicationPreference =
    CategoryCommunicationPreference(
      channelFrequencies: <CommunicationChannel, CommunicationFrequency>{
        CommunicationChannel.push: CommunicationFrequency.immediate,
        CommunicationChannel.inApp: CommunicationFrequency.immediate,
        CommunicationChannel.email: CommunicationFrequency.disabled,
      },
    );

/// One category's (crm/commercial/system) preference across every
/// [CommunicationChannel].
final class CategoryCommunicationPreference {
  const CategoryCommunicationPreference({required this.channelFrequencies});

  final Map<CommunicationChannel, CommunicationFrequency> channelFrequencies;

  /// Falls back to [CommunicationFrequency.disabled] for a channel this
  /// preference never recorded a value for — never throws on a partially
  /// written/older document.
  CommunicationFrequency frequencyFor(CommunicationChannel channel) {
    return channelFrequencies[channel] ?? CommunicationFrequency.disabled;
  }

  /// `true` when every single [CommunicationChannel] is
  /// [CommunicationFrequency.disabled] — the one state TASK-154 forbids for
  /// [AppNotificationCategory.system].
  bool get isFullyDisabled {
    return CommunicationChannel.values.every(
      (channel) => frequencyFor(channel) == CommunicationFrequency.disabled,
    );
  }

  CategoryCommunicationPreference copyWithChannel(
    CommunicationChannel channel,
    CommunicationFrequency frequency,
  ) {
    return CategoryCommunicationPreference(
      channelFrequencies: <CommunicationChannel, CommunicationFrequency>{
        ...channelFrequencies,
        channel: frequency,
      },
    );
  }
}

/// A single user's communication preferences (TASK-154): per
/// [AppNotificationCategory], per [CommunicationChannel], how often they want
/// to be notified. Persisted at
/// `organizations/{organizationId}/communicationPreferences/{userId}` — one
/// document per user, read/written from every device that user signs into,
/// which is what makes a change made on one device reach every other one
/// (Firestore's own real-time listener, not a local-only cache).
final class CommunicationPreferences {
  const CommunicationPreferences({
    required this.organizationId,
    required this.userId,
    required this.categoryPreferences,
    this.quietHours = const QuietHours(),
    this.updatedAt,
  });

  /// The documented safe default (TASK-154) applied whenever [userId] has
  /// never configured anything yet — never a missing/`null` preference the
  /// rest of the app has to special-case.
  factory CommunicationPreferences.defaults({
    required String organizationId,
    required String userId,
  }) {
    return CommunicationPreferences(
      organizationId: organizationId,
      userId: userId,
      categoryPreferences:
          <AppNotificationCategory, CategoryCommunicationPreference>{
            for (final category in AppNotificationCategory.values)
              category: kDefaultCategoryCommunicationPreference,
          },
    );
  }

  final String organizationId;
  final String userId;
  final Map<AppNotificationCategory, CategoryCommunicationPreference>
  categoryPreferences;

  /// This recipient's quiet-hours window (TASK-155) — disabled by default,
  /// same opt-in convention as every other TASK-154 preference.
  final QuietHours quietHours;

  /// `null` until the very first save.
  final DateTime? updatedAt;

  /// Falls back to [kDefaultCategoryCommunicationPreference] for a category
  /// this document never recorded (e.g. a new category shipped after the
  /// user last saved).
  CategoryCommunicationPreference preferenceFor(
    AppNotificationCategory category,
  ) {
    return categoryPreferences[category] ??
        kDefaultCategoryCommunicationPreference;
  }

  CommunicationFrequency frequencyFor(
    AppNotificationCategory category,
    CommunicationChannel channel,
  ) {
    return preferenceFor(category).frequencyFor(channel);
  }

  /// Whether a notification through [channel] is currently allowed to reach
  /// this user for [category] — `false` only when the recorded frequency is
  /// [CommunicationFrequency.disabled]. Every notification generator
  /// (`ShouldDispatchNotificationUseCase`) gates on this before dispatching.
  bool allows(AppNotificationCategory category, CommunicationChannel channel) {
    return frequencyFor(category, channel) != CommunicationFrequency.disabled;
  }

  /// Returns a new [CommunicationPreferences] with [category]'s [channel]
  /// set to [frequency] — every other category/channel untouched. Does not
  /// itself enforce the "system category can never be fully disabled" rule;
  /// that validation lives in `SaveCommunicationPreferencesUseCase`, run
  /// right before persisting, so a caller can freely build (and reject)
  /// candidate states without this builder ever throwing.
  CommunicationPreferences withChannelFrequency({
    required AppNotificationCategory category,
    required CommunicationChannel channel,
    required CommunicationFrequency frequency,
  }) {
    final updatedCategoryPreference = preferenceFor(
      category,
    ).copyWithChannel(channel, frequency);
    return CommunicationPreferences(
      organizationId: organizationId,
      userId: userId,
      updatedAt: updatedAt,
      quietHours: quietHours,
      categoryPreferences:
          <AppNotificationCategory, CategoryCommunicationPreference>{
            ...categoryPreferences,
            category: updatedCategoryPreference,
          },
    );
  }

  /// Returns a new [CommunicationPreferences] with [quietHours] replacing
  /// this recipient's current window — every category/channel preference
  /// untouched.
  CommunicationPreferences withQuietHours(QuietHours quietHours) {
    return CommunicationPreferences(
      organizationId: organizationId,
      userId: userId,
      updatedAt: updatedAt,
      categoryPreferences: categoryPreferences,
      quietHours: quietHours,
    );
  }

  /// `true` when [AppNotificationCategory.system] would end up with every
  /// channel disabled — the single state TASK-154's business rule forbids
  /// persisting ("notificações críticas de sistema... não podem ser
  /// completamente desativadas — apenas o canal pode ser ajustado").
  bool get hasSystemCategoryFullyDisabled {
    return preferenceFor(AppNotificationCategory.system).isFullyDisabled;
  }
}
