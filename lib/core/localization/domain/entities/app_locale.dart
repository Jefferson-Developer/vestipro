/// The interface languages VestiPro actually ships today (TASK-174):
/// Portuguese and English, the two "primeiros idiomas suportados" the task
/// asks for. Adding a third language later means adding one more value here
/// plus its own `app_<code>.arb` — `l10n.yaml`/`flutter gen-l10n` already
/// regenerate `AppLocalizations` for whatever this enum lists.
enum AppLocale {
  /// Both the first supported language and the mandatory fallback (see
  /// [fallback]) — VestiPro's native language, so a corrupted/unsupported
  /// stored preference degrades here instead of ever showing a raw
  /// translation key or a blank string to the user.
  portuguese('pt', 'Português'),
  english('en', 'English');

  const AppLocale(this.languageCode, this.displayName);

  /// BCP-47 language code, matching the `@@locale` of the corresponding
  /// `app_<code>.arb` file and persisted verbatim in
  /// [LocalePreferenceLocalStore]/Firestore.
  final String languageCode;

  /// Each language's own endonym ("Português", "English") — deliberately
  /// never translated through `AppLocalizations` itself: a language picker
  /// conventionally lists every option in its own language, not in whatever
  /// language happens to be selected right now, so the user can always find
  /// their own language even if they landed on the wrong one by accident.
  final String displayName;

  /// The fallback used whenever a stored/device language code does not
  /// match any [AppLocale.values] — e.g. a device set to Spanish, or an
  /// older persisted preference for a language later discontinued. Never
  /// `null`/absent: TASK-174 requires the interface to "nunca exibe chave
  /// crua ao usuário", so resolution always lands on a real, fully
  /// translated [AppLocale].
  static const AppLocale fallback = AppLocale.portuguese;

  /// Resolves a raw language code (from local storage, Firestore, or
  /// `PlatformDispatcher.locale`) to a supported [AppLocale] — [fallback]
  /// for `null`, blank, or any code this app does not ship a translation
  /// for.
  static AppLocale fromLanguageCode(String? code) {
    final trimmed = code?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return AppLocale.values.firstWhere(
      (locale) => locale.languageCode == trimmed,
      orElse: () => fallback,
    );
  }
}
