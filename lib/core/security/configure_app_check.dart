import 'dart:developer' as developer;

import 'package:firebase_app_check/firebase_app_check.dart';

import '../environment/app_environment.dart';

/// Public (non-secret) reCAPTCHA v3 site key used to activate Firebase App
/// Check on Flutter Web in `production`. Site keys are meant to be public —
/// Google's own reCAPTCHA docs ship them embedded in client-side HTML/JS —
/// what must never be committed is a *secret*/server key, which VestiPro
/// never handles on the client (TASK-032).
///
/// Overridable per build via
/// `--dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY=...`, once App Check is
/// registered for the `vestipro` project in the Firebase Console (Project
/// settings → App Check) and a reCAPTCHA v3 site key is generated there.
/// Until that manual, one-time infra step happens, this stays empty and
/// [configureAppCheck] skips Web activation in `production` rather than
/// activate with a bogus key — see its own doc for why.
const String appCheckWebRecaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
);

/// Optional, pinned debug token for the Debug provider (Android/iOS/Web) in
/// `development`/`staging`, sourced from
/// `--dart-define=APP_CHECK_DEBUG_TOKEN=...`. Lets a CI pipeline that needs
/// a stable, already-registered token (e.g. for integration tests that
/// exercise the real `vestipro` project instead of the Emulator Suite) avoid
/// depending on whatever random token the SDK would otherwise auto-generate
/// on every run. Left empty for everyday local development: the SDK then
/// auto-generates a token and prints it to the device/browser log, and a
/// developer registers it once in *Firebase Console → App Check → Manage
/// debug tokens*.
///
/// Never commit a real value for this define into any checked-in launch
/// config/script — pass it only via the CI secret store, exactly like any
/// other credential.
const String appCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
);

/// Activates Firebase App Check (TASK-032) with the provider appropriate for
/// each platform and [environment] — the last piece of the Segurança e
/// Multi-Tenancy trio started by the Firestore/Storage Security Rules
/// (TASK-030/TASK-031): Security Rules decide *who* (which organization
/// Membership, which RBAC capability) can read/write a given document/file;
/// App Check adds a second, independent layer that lets the backend also
/// verify *what* is calling — a genuine VestiPro build, not a scripted bot
/// or a tampered APK — for Firestore, Storage and every Cloud Functions
/// callable. Neither layer replaces the other (see `AGENTS.md`).
///
/// Per ADR-0002, `development` and `staging` never touch the real
/// `vestipro` Firebase project — they exclusively use the Emulator Suite,
/// which does not enforce App Check at all. Both flavors still activate
/// with the **Debug provider** on every platform (Android/iOS/Web): this
/// keeps every developer's local run working, and — the one time a
/// developer *does* point a `dev`/`staging` build at the real project for
/// manual testing — keeps that build working too, by simply registering the
/// debug token the SDK prints to the device/browser log (or
/// [appCheckDebugToken], when pinned) in *Firebase Console → App Check →
/// Manage debug tokens*, without ever weakening the token requirement it
/// would otherwise have to satisfy. This is also why strict enforcement must
/// never be turned on for a `development`/`staging` build without a debug
/// provider already configured (TASK-032 restriction) — it already is,
/// unconditionally, by this function.
///
/// `production` (the only flavor that ever talks to the real project)
/// activates the real attestation providers requested by TASK-032:
/// - Android: [AndroidPlayIntegrityProvider] — the current Firebase
///   -recommended provider (supersedes the deprecated SafetyNet API).
/// - iOS/macOS: [AppleAppAttestWithDeviceCheckFallbackProvider] — App Attest
///   on iOS 14+/macOS 14+, transparently falling back to DeviceCheck on
///   older OS versions that do not support App Attest.
/// - Web: [ReCaptchaV3Provider] with [appCheckWebRecaptchaSiteKey], only
///   when that key has been provisioned. Until then, Web activation is
///   skipped entirely in `production` — activating with an empty/bogus site
///   key would make every Web Firestore/Storage/Functions call fail outright
///   the moment backend enforcement is turned on for that product, which is
///   strictly worse than temporarily running Web without an App Check token
///   while Security Rules/RBAC (TASK-029/030/031) keep doing their own,
///   independent authorization.
///
/// Enforcement itself (Monitor vs. Enforce, configured per product —
/// Firestore, Storage, Cloud Functions) is a Firebase Console-only setting,
/// not something the Flutter client controls. Recommended rollout, to keep
/// with TASK-032's "never break `development`" restriction: enable Monitor
/// mode first for every product once this activation ships, confirm in the
/// Console that legitimate traffic already carries valid tokens, then flip
/// to Enforce for `production` traffic.
///
/// Never throws (mirrors `configureRemoteConfig`/`configurePerformance`):
/// called fire-and-forget (`unawaited`) from the `FirebaseAppCheck` DI
/// provider (`lib/app/injection_module.dart`), so nothing downstream ever
/// awaits or catches this Future. A failure here simply means the app keeps
/// running exactly as it did before TASK-032 — Firestore/Storage/Functions
/// calls still work, still fully authorized by Security Rules/RBAC, just
/// without an App Check token attached until the next successful activation.
Future<void> configureAppCheck(
  FirebaseAppCheck appCheck, {
  required AppEnvironment environment,
}) async {
  try {
    await appCheck.setTokenAutoRefreshEnabled(true);

    if (environment.isProduction) {
      await appCheck.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
        providerWeb: appCheckWebRecaptchaSiteKey.isEmpty
            ? null
            : ReCaptchaV3Provider(appCheckWebRecaptchaSiteKey),
      );
    } else {
      final debugToken = appCheckDebugToken.isEmpty ? null : appCheckDebugToken;
      await appCheck.activate(
        providerAndroid: AndroidDebugProvider(debugToken: debugToken),
        providerApple: AppleDebugProvider(debugToken: debugToken),
        providerWeb: WebDebugProvider(debugToken: debugToken),
      );
    }
  } catch (error, stackTrace) {
    developer.log(
      'configureAppCheck failed to activate App Check; Firestore/Storage/'
      'Functions calls keep working (Security Rules/RBAC still enforce '
      'authorization on their own) but without an App Check token attached '
      'until the next successful activation.',
      name: 'vestipro.app_check',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
