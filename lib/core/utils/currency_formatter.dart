import 'package:intl/intl.dart';

/// Formats a monetary value together with the ISO 4217 currency code it is
/// actually expressed in (TASK-175, multi-moeda) — the single place every
/// screen (catálogo, pedido, dashboard, relatório) turns a
/// `(value, currencyCode)` pair into user-facing text, so no screen ever
/// hardcodes a locale/symbol combination (`NumberFormat.currency(locale:
/// 'pt_BR', symbol: 'R\$')`) that would silently show the wrong currency the
/// moment a non-BRL Price List (`PriceList.currency`, TASK-083) is involved.
///
/// VestiPro never converts between currencies (`PriceList` business rule):
/// every value this formats already belongs to exactly one currency —
/// [format]/[formatWithCode] only ever render it, never recompute it.
final class CurrencyFormatter {
  const CurrencyFormatter._();

  /// VestiPro's original single-market currency — every order/Price List
  /// persisted before TASK-175 started denormalizing `currency` explicitly
  /// was implicitly this, so it is the one safe fallback wherever a caller
  /// cannot resolve a real currency code (never invented for anything new).
  static const String legacyDefaultCurrency = 'BRL';

  /// Renders [value] in [currencyCode] — grouping/decimal separators and
  /// symbol *position* follow [locale] (defaults to the current app locale,
  /// `Intl.getCurrentLocale()`, TASK-174), but the symbol itself always comes
  /// from [currencyCode] (via [_symbolFor]), never from [locale]: a `pt_BR`
  /// interface showing a USD Price List still renders "US$ 1.234,50", never
  /// "R$" — [locale] and [currencyCode] are independent axes, exactly like
  /// TASK-174's own "idioma da interface" and TASK-175's own "moeda da
  /// tabela de preço" are independent settings.
  ///
  /// Passes [currencyCode] itself as `NumberFormat.currency`'s `symbol`
  /// (never leaving it to look one up on its own): `intl` only resolves a
  /// currency's real symbol from CLDR data bundled per-locale, which is not
  /// guaranteed loaded for every (locale, currency) combination this app can
  /// show — falling back to a plain "BRL 1.234,50" for an unmapped code
  /// keeps the value unambiguous even then, just without a pretty glyph.
  static String format(double value, String currencyCode, {String? locale}) {
    return NumberFormat.currency(
      locale: locale ?? Intl.getCurrentLocale(),
      symbol: _symbolFor(currencyCode),
      decimalDigits: 2,
    ).format(value);
  }

  /// ISO 4217 code -> display symbol, for the currencies VestiPro's fashion
  /// B2B markets actually operate in today. Deliberately a small, explicit
  /// map instead of a full ISO 4217 table: an unmapped code still formats
  /// correctly (see [format]'s own docs), just showing the plain code
  /// instead of a glyph — adding a new market's currency here is a one-line
  /// change, never a reason to block a new Price List from being created
  /// with that currency in the meantime.
  static const Map<String, String> _symbolsByCurrencyCode = <String, String>{
    'BRL': r'R$',
    'USD': r'US$',
    'EUR': '€',
    'GBP': '£',
    'ARS': r'AR$',
    'CLP': r'CL$',
    'COP': r'CO$',
    'MXN': r'MX$',
    'PYG': '₲',
    'UYU': r'\$U',
  };

  static String _symbolFor(String currencyCode) {
    final normalized = currencyCode.trim().toUpperCase();
    return _symbolsByCurrencyCode[normalized] ?? normalized;
  }

  /// Same as [format], but always appends the explicit ISO 4217 code (e.g.
  /// `"R$ 1.234,50 BRL"`) — the "indicação visual clara de qual moeda está
  /// sendo exibida... sem depender de o usuário inferir apenas pelo símbolo"
  /// TASK-175 requires everywhere a monetary value is shown: several
  /// currencies share a symbol (`$` alone is USD, CAD, MXN, ARS...), so the
  /// symbol alone is never enough to tell them apart.
  static String formatWithCode(
    double value,
    String currencyCode, {
    String? locale,
  }) {
    return '${format(value, currencyCode, locale: locale)} $currencyCode';
  }
}
