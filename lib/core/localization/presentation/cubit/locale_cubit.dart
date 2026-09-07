import 'dart:async' show TimeoutException;

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../analytics/analytics.dart';
import '../../domain/entities/app_locale.dart';
import '../../domain/usecases/get_device_locale_use_case.dart';
import '../../domain/usecases/set_preferred_locale_use_case.dart';

/// Owns the interface language for the whole app (TASK-174): the single
/// [AppLocale] every screen renders in, read by `VestiProApp` and fed
/// straight into `MaterialApp.locale`.
///
/// Deliberately a long-lived `@lazySingleton` — unlike most feature Cubits
/// (page-scoped, created/disposed with their screen) — since it backs a
/// single root `BlocProvider` wrapping the whole `MaterialApp.router` for
/// the entire app lifetime, the same way `ThemeMode`/`Locale` themselves are
/// app-wide, not screen-scoped, concerns.
///
/// [loadInitial] is awaited once in `bootstrap()` *before* `runApp`, so the
/// very first frame already renders in the right language — no flash of the
/// wrong locale, no separate loading state to render for it.
@lazySingleton
final class LocaleCubit extends Cubit<AppLocale> {
  LocaleCubit(
    this._getDeviceLocale,
    this._setPreferredLocale,
    this._analyticsService,
  ) : super(AppLocale.fallback);

  final GetDeviceLocaleUseCase _getDeviceLocale;
  final SetPreferredLocaleUseCase _setPreferredLocale;
  final AnalyticsService _analyticsService;

  /// Loads whatever this device last saved (or [AppLocale.fallback] the
  /// first time it ever runs) — call once, before `runApp`.
  ///
  /// Bounded by a short timeout: this runs on the critical path of app boot
  /// (awaited *before* `runApp`), so a misbehaving local storage backend on
  /// some device must never be able to hang the whole app at a splash
  /// screen forever — it degrades to [AppLocale.fallback] instead, same
  /// "never block boot" contract `_resolveShowInsightsShortcut` already
  /// documents for `FeatureFlagService`.
  Future<void> loadInitial() async {
    late final AppLocale locale;
    try {
      locale = await _getDeviceLocale().timeout(const Duration(seconds: 2));
    } on TimeoutException {
      locale = AppLocale.fallback;
    }
    if (isClosed) return;
    emit(locale);
  }

  /// Switches the interface language (TASK-174's language selector).
  ///
  /// Emits [locale] immediately, *before* persistence completes — this is
  /// what makes the switch "imediata... sem reiniciar o app": every screen
  /// listening to this Cubit (the whole `MaterialApp` down) rebuilds in the
  /// new language on the very next frame, and since neither `AppRouter` nor
  /// any widget's `Key` changes because of it, the Element tree — and every
  /// open form's state — survives untouched, same guarantee a `ThemeMode`
  /// toggle would give.
  Future<void> changeLocale(
    AppLocale locale, {
    required String organizationId,
    required String userId,
  }) async {
    if (state == locale) return;

    emit(locale);

    await _setPreferredLocale(
      locale: locale,
      organizationId: organizationId,
      userId: userId,
    );
    await _analyticsService.logEvent(
      AnalyticsEvents.appLocaleChanged,
      parameters: <String, Object?>{'language_code': locale.languageCode},
    );
  }
}
