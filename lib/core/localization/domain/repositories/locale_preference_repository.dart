import '../entities/app_locale.dart';

/// Source of truth for the current user's interface language (TASK-174).
///
/// Unlike `CommunicationPreferencesRepository` (Firestore is the source of
/// truth there, one document shared by every device), the language
/// preference is deliberately local-first: [getDeviceLocale] must never
/// depend on network — "idioma escolhido não pode depender de rede" is an
/// explicit TASK-174 requirement, since it is read at every app boot, before
/// this device may even have connectivity. Firestore only ever receives a
/// best-effort mirror of whatever this device already saved, so a support
/// agent (or a future cross-device reconciliation flow) can see what a user
/// last chose — no caller today reads that mirror back to drive the UI.
abstract interface class LocalePreferenceRepository {
  /// Instant, offline-safe read of this device's saved language —
  /// [AppLocale.fallback] the very first time the app runs on this device,
  /// before any explicit choice was ever saved locally.
  Future<AppLocale> getDeviceLocale();

  /// Persists [locale] as this device's language: the local write always
  /// happens first and is what [getDeviceLocale] reads back from then on,
  /// even fully offline. Best-effort mirrors the same value to
  /// `organizations/{organizationId}/localePreferences/{userId}` in
  /// Firestore for [organizationId]/[userId] — a mirror failure (offline,
  /// permission, transient error) is swallowed and never surfaces to the
  /// caller, since the local choice already "stuck" regardless.
  Future<void> setDeviceLocale({
    required AppLocale locale,
    required String organizationId,
    required String userId,
  });
}
