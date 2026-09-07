import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_locale.dart';

/// Persists the current device's language preference to disk — the one
/// piece of state [LocalePreferenceRepositoryImpl.getDeviceLocale] reads at
/// every app boot, before Firebase/network are known to be reachable.
/// `SharedPreferences`-backed, same offline-first convention as
/// `SharedPreferencesPushRegistrationLocalStore` (TASK-150).
abstract interface class LocalePreferenceLocalStore {
  /// `null` when this device has never saved a language yet.
  Future<AppLocale?> read();

  Future<void> write(AppLocale locale);
}

@LazySingleton(as: LocalePreferenceLocalStore)
final class SharedPreferencesLocalePreferenceLocalStore
    implements LocalePreferenceLocalStore {
  static const _languageCodeKey = 'locale_preference_language_code';

  @override
  Future<AppLocale?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode == null) return null;
    return AppLocale.fromLanguageCode(languageCode);
  }

  @override
  Future<void> write(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
  }
}
