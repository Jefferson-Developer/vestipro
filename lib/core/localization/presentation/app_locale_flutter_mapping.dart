import 'package:flutter/widgets.dart' show Locale;

import '../domain/entities/app_locale.dart';

/// Converts the Flutter-free [AppLocale] domain enum to a real Flutter
/// [Locale] — kept out of `domain/` on purpose ("Domain sem Flutter/
/// Firebase/Drift/widgets"), this is the one place `MaterialApp.locale`
/// (via [LocaleCubit]) reaches for it.
extension AppLocaleFlutterMapping on AppLocale {
  Locale get toFlutterLocale => Locale(languageCode);
}
