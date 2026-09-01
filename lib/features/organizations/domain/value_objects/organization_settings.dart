import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'organization_settings.freezed.dart';

/// Default `OrganizationSettings.positivacaoPeriodGranularity` for an
/// organization that never configured its own (TASK-117) — matches
/// `TargetPeriodGranularity.monthly.name` without importing that enum here.
const String defaultPositivacaoPeriodGranularity = 'monthly';

/// Default `OrganizationSettings.positivacaoEligibleOrderStatuses` (TASK-117):
/// which `OrderStatus.name` codes count as "the customer bought" until an
/// organization narrows/widens the set itself. Deliberately excludes
/// `draft`/`pendingSync`/`submitted`/`underReview` (not yet a firm commercial
/// commitment) and `rejected`/`cancelled` (never a sale).
const List<String> defaultPositivacaoEligibleOrderStatuses = <String>[
  'approved',
  'delivered',
  'invoiced',
  'partiallyInvoiced',
  'shipped',
];

/// Default `OrganizationSettings.rankingVisibilityMode` (TASK-118): an
/// organization that never configured its own shows the full nominal ranking
/// to every role that can view it — matches `RankingVisibilityMode
/// .fullRanking.code` without importing that enum here (same decoupling
/// technique already used by [defaultPositivacaoPeriodGranularity]).
const String defaultRankingVisibilityMode = 'full_ranking';

/// Every raw code [OrganizationSettings.rankingVisibilityMode] accepts —
/// kept here (not in the `targets` feature) so [OrganizationSettings
/// .validated] can reject a garbage code without importing
/// `RankingVisibilityMode`, same technique already used for
/// [OrganizationSettings.positivacaoPeriodGranularity].
const Set<String> validRankingVisibilityModes = <String>{
  'full_ranking',
  'relative_position_only',
};

/// Organization-wide defaults (currency, country, default language) that
/// Companies and Branches inherit unless they override them explicitly
/// (TASK-027).
@freezed
abstract class OrganizationSettings with _$OrganizationSettings {
  const OrganizationSettings._();

  const factory OrganizationSettings({
    required String currency,
    required String country,
    required String defaultLanguage,

    /// The fashion segment the Organization operates in (`apparel`,
    /// `footwear`, `accessories`, `multi_brand` — see
    /// `OrganizationSegment.code`), collected by the onboarding wizard
    /// (TASK-038). Nullable — and never validated here — because, unlike
    /// [currency]/[country]/[defaultLanguage], not every caller of this
    /// type sets it (e.g. a future settings update that only changes
    /// [currency] has no reason to also resend it); the wizard enforces its
    /// own "segment is required to finish onboarding" rule independently
    /// (`CompleteOnboardingUseCase`).
    String? segment,

    /// Optional commercial governance limit: when set, one active member
    /// cannot be assigned to more than this many Teams in the Organization.
    /// `null` means unlimited.
    int? maxTeamsPerUser,

    /// Extra customer form fields that this Organization requires beyond the
    /// hard minimum (document + legal/full name). Stored as stable field codes
    /// so the Organization model stays decoupled from the customers feature.
    @Default(<String>[]) List<String> requiredCustomerFields,

    /// Extra address type codes/labels available in the Customer form, e.g.
    /// `showroom|Showroom` or `warehouse|Deposito`.
    @Default(<String>[]) List<String> customerAddressTypes,

    /// Extra contact type codes/labels available in the Customer form, e.g.
    /// `logistics|Logistica`.
    @Default(<String>[]) List<String> customerContactTypes,

    /// Whether a Product can be associated with more than one `Collection`
    /// at once (TASK-066), e.g. a continuous product carried in both a core
    /// collection and a seasonal drop. `false` (the default) means
    /// `AssociateProductWithCollectionUseCase` replaces any previous
    /// association instead of adding a second one.
    @Default(false) bool allowMultipleCollectionsPerProduct,

    /// Reservation TTL for TASK-092. Server-side stock reservations must
    /// expire automatically, but the timeout is organization-configurable
    /// instead of hardcoded in the client.
    @Default(15) int stockReservationExpiresInMinutes,

    /// Positivação de carteira (TASK-117, EPIC-15/VESTI-087): reporting
    /// cadence used to derive the "current period" window a positivação
    /// dashboard/snapshot is computed for. Stored as the raw
    /// `TargetPeriodGranularity.name` string (`monthly`/`quarterly`/`yearly`)
    /// instead of importing that enum here, same decoupling technique as
    /// [customerAddressTypes]/[customerContactTypes] above — the `targets`
    /// feature owns decoding/validating it, this settings model only stores
    /// the string.
    @Default(defaultPositivacaoPeriodGranularity)
    String positivacaoPeriodGranularity,

    /// Which `OrderStatus.name` codes count as "the customer bought" for
    /// positivação (TASK-117). Deliberately not every [OrderStatus] — a
    /// `draft`/`pendingSync`/`cancelled`/`rejected` order must never count.
    /// Stored as raw strings for the same reason as
    /// [positivacaoPeriodGranularity]: this settings model never imports the
    /// `orders` feature's `OrderStatus` enum, the `targets` feature validates
    /// each code against it when parsing `PositivacaoSettings`.
    @Default(defaultPositivacaoEligibleOrderStatuses)
    List<String> positivacaoEligibleOrderStatuses,

    /// Minimum order total (in [currency]) for that order to count towards
    /// positivação, when the organization wants one — `null` means no
    /// minimum (any eligible-status order already counts), same
    /// nullable-means-unlimited/disabled convention as [maxTeamsPerUser].
    double? positivacaoMinOrderValue,

    /// Ranking comercial visibility rule (TASK-118, EPIC-15): whether a
    /// `SALES_REP` sees the full nominal ranking of their peers
    /// (`full_ranking`) or only their own relative position (e.g. "você
    /// está em 4º de 12", `relative_position_only`). Stored as a raw code
    /// (one of [validRankingVisibilityModes]) instead of importing
    /// `RankingVisibilityMode` here, same decoupling technique as
    /// [positivacaoPeriodGranularity]. Never changes what a
    /// `SALES_MANAGER`/`ADMIN`/`OWNER` sees — those roles always get the
    /// full ranking of the scope they manage, regardless of this setting;
    /// see `RankingCalculationService`'s own docs.
    @Default(defaultRankingVisibilityMode) String rankingVisibilityMode,
  }) = _OrganizationSettings;

  /// Builds validated [OrganizationSettings], trimming each value and
  /// rejecting blanks. Used by every caller that can create or change
  /// settings (create, update, future imports) so they all share the same
  /// guarantee instead of re-implementing it.
  ///
  /// [segment] is the one exception to "reject blanks": it stays optional
  /// (trimmed to `null` when blank) since it is not a value every caller of
  /// this factory has — see [OrganizationSettings.segment]'s own doc.
  factory OrganizationSettings.validated({
    required String currency,
    required String country,
    required String defaultLanguage,
    String? segment,
    int? maxTeamsPerUser,
    List<String> requiredCustomerFields = const <String>[],
    List<String> customerAddressTypes = const <String>[],
    List<String> customerContactTypes = const <String>[],
    bool allowMultipleCollectionsPerProduct = false,
    int stockReservationExpiresInMinutes = 15,
    String positivacaoPeriodGranularity = defaultPositivacaoPeriodGranularity,
    List<String> positivacaoEligibleOrderStatuses =
        defaultPositivacaoEligibleOrderStatuses,
    double? positivacaoMinOrderValue,
    String rankingVisibilityMode = defaultRankingVisibilityMode,
  }) {
    final fieldErrors = <String, String>{};
    final trimmedCurrency = currency.trim();
    final trimmedCountry = country.trim();
    final trimmedDefaultLanguage = defaultLanguage.trim();
    final trimmedSegment = segment?.trim();
    final normalizedRequiredCustomerFields =
        requiredCustomerFields
            .map((field) => field.trim())
            .where((field) => field.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    final normalizedCustomerAddressTypes = _normalizeSettingsList(
      customerAddressTypes,
    );
    final normalizedCustomerContactTypes = _normalizeSettingsList(
      customerContactTypes,
    );
    final trimmedPositivacaoPeriodGranularity = positivacaoPeriodGranularity
        .trim();
    final normalizedPositivacaoEligibleOrderStatuses = _normalizeSettingsList(
      positivacaoEligibleOrderStatuses,
    );
    final trimmedRankingVisibilityMode = rankingVisibilityMode.trim();

    if (trimmedCurrency.isEmpty) {
      fieldErrors['currency'] = 'Currency is required.';
    }
    if (trimmedCountry.isEmpty) {
      fieldErrors['country'] = 'Country is required.';
    }
    if (trimmedDefaultLanguage.isEmpty) {
      fieldErrors['defaultLanguage'] = 'Default language is required.';
    }
    if (maxTeamsPerUser != null && maxTeamsPerUser < 1) {
      fieldErrors['maxTeamsPerUser'] =
          'Max teams per user must be greater than zero.';
    }
    if (stockReservationExpiresInMinutes < 15 ||
        stockReservationExpiresInMinutes > 60) {
      fieldErrors['stockReservationExpiresInMinutes'] =
          'Stock reservation expiration must stay between 15 and 60 minutes.';
    }
    // `TargetPeriodGranularity.values.map((v) => v.name)` is not imported
    // here (see the field's own doc) — this only rejects garbage strings so
    // an org can never persist a code the `targets` feature cannot decode;
    // the `targets` feature itself independently rejects an unknown value
    // when parsing `PositivacaoSettings`.
    if (!const <String>{
      'monthly',
      'quarterly',
      'yearly',
    }.contains(trimmedPositivacaoPeriodGranularity)) {
      fieldErrors['positivacaoPeriodGranularity'] =
          'Positivação period granularity must be monthly, quarterly or '
          'yearly.';
    }
    if (normalizedPositivacaoEligibleOrderStatuses.isEmpty) {
      fieldErrors['positivacaoEligibleOrderStatuses'] =
          'At least one order status must count towards positivação.';
    }
    if (positivacaoMinOrderValue != null && positivacaoMinOrderValue < 0) {
      fieldErrors['positivacaoMinOrderValue'] =
          'Positivação minimum order value cannot be negative.';
    }
    if (!validRankingVisibilityModes.contains(trimmedRankingVisibilityMode)) {
      fieldErrors['rankingVisibilityMode'] =
          'Ranking visibility mode must be full_ranking or '
          'relative_position_only.';
    }

    if (fieldErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid organization settings.',
        code: 'invalid_organization_settings',
        fieldErrors: fieldErrors,
      );
    }

    return OrganizationSettings(
      currency: trimmedCurrency,
      country: trimmedCountry,
      defaultLanguage: trimmedDefaultLanguage,
      segment: (trimmedSegment == null || trimmedSegment.isEmpty)
          ? null
          : trimmedSegment,
      maxTeamsPerUser: maxTeamsPerUser,
      requiredCustomerFields: normalizedRequiredCustomerFields,
      customerAddressTypes: normalizedCustomerAddressTypes,
      customerContactTypes: normalizedCustomerContactTypes,
      allowMultipleCollectionsPerProduct: allowMultipleCollectionsPerProduct,
      stockReservationExpiresInMinutes: stockReservationExpiresInMinutes,
      positivacaoPeriodGranularity: trimmedPositivacaoPeriodGranularity,
      positivacaoEligibleOrderStatuses:
          normalizedPositivacaoEligibleOrderStatuses,
      positivacaoMinOrderValue: positivacaoMinOrderValue,
      rankingVisibilityMode: trimmedRankingVisibilityMode,
    );
  }
}

List<String> _normalizeSettingsList(Iterable<String> values) {
  final normalized = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
  normalized.sort();
  return normalized;
}
