import '../../../../core/errors/errors.dart';
import '../../domain/value_objects/organization_settings.dart';

final class OrganizationSettingsDto {
  const OrganizationSettingsDto({
    required this.currency,
    required this.country,
    required this.defaultLanguage,
    this.segment,
    this.maxTeamsPerUser,
    this.requiredCustomerFields = const <String>[],
    this.customerAddressTypes = const <String>[],
    this.customerContactTypes = const <String>[],
    this.allowMultipleCollectionsPerProduct = false,
    this.stockReservationExpiresInMinutes = 15,
    this.positivacaoPeriodGranularity = defaultPositivacaoPeriodGranularity,
    this.positivacaoEligibleOrderStatuses =
        defaultPositivacaoEligibleOrderStatuses,
    this.positivacaoMinOrderValue,
    this.rankingVisibilityMode = defaultRankingVisibilityMode,
  });

  factory OrganizationSettingsDto.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    final country = json['country'];
    final defaultLanguage = json['defaultLanguage'];
    final segment = json['segment'];
    final maxTeamsPerUser = json['maxTeamsPerUser'];
    final rawRequiredCustomerFields = json['requiredCustomerFields'];
    final rawCustomerAddressTypes = json['customerAddressTypes'];
    final rawCustomerContactTypes = json['customerContactTypes'];
    final allowMultipleCollectionsPerProduct =
        json['allowMultipleCollectionsPerProduct'];
    final stockReservationExpiresInMinutes =
        json['stockReservationExpiresInMinutes'];
    final positivacaoPeriodGranularity = json['positivacaoPeriodGranularity'];
    final rawPositivacaoEligibleOrderStatuses =
        json['positivacaoEligibleOrderStatuses'];
    final positivacaoMinOrderValue = json['positivacaoMinOrderValue'];
    final rankingVisibilityMode = json['rankingVisibilityMode'];

    if (currency is! String ||
        country is! String ||
        defaultLanguage is! String ||
        (segment != null && segment is! String) ||
        (maxTeamsPerUser != null && maxTeamsPerUser is! int) ||
        (stockReservationExpiresInMinutes != null &&
            stockReservationExpiresInMinutes is! int) ||
        (allowMultipleCollectionsPerProduct != null &&
            allowMultipleCollectionsPerProduct is! bool) ||
        (positivacaoPeriodGranularity != null &&
            positivacaoPeriodGranularity is! String) ||
        (positivacaoMinOrderValue != null &&
            positivacaoMinOrderValue is! num) ||
        (rankingVisibilityMode != null && rankingVisibilityMode is! String)) {
      throw const ValidationException(
        'Invalid organization settings payload.',
        code: 'invalid_organization_settings_payload',
      );
    }

    return OrganizationSettingsDto(
      currency: currency,
      country: country,
      defaultLanguage: defaultLanguage,
      segment: segment as String?,
      maxTeamsPerUser: maxTeamsPerUser as int?,
      requiredCustomerFields: _stringListFromJson(rawRequiredCustomerFields),
      customerAddressTypes: _stringListFromJson(rawCustomerAddressTypes),
      customerContactTypes: _stringListFromJson(rawCustomerContactTypes),
      allowMultipleCollectionsPerProduct:
          allowMultipleCollectionsPerProduct as bool? ?? false,
      stockReservationExpiresInMinutes:
          stockReservationExpiresInMinutes as int? ?? 15,
      positivacaoPeriodGranularity:
          positivacaoPeriodGranularity as String? ??
          defaultPositivacaoPeriodGranularity,
      positivacaoEligibleOrderStatuses:
          rawPositivacaoEligibleOrderStatuses == null
          ? defaultPositivacaoEligibleOrderStatuses
          : _stringListFromJson(rawPositivacaoEligibleOrderStatuses),
      positivacaoMinOrderValue: (positivacaoMinOrderValue as num?)?.toDouble(),
      rankingVisibilityMode:
          rankingVisibilityMode as String? ?? defaultRankingVisibilityMode,
    );
  }

  final String currency;
  final String country;
  final String defaultLanguage;

  /// The Organization's fashion segment (TASK-038), or `null` for
  /// Organizations created before that field existed. Omitted by [toJson]
  /// instead of written as an explicit `null` key — same rationale as
  /// [OrganizationSettings.segment]'s own doc. Note this does **not** by
  /// itself protect a previously-stored [segment] from a future
  /// `updateSettings` call that omits it: `FirestoreOrganizationDataSource
  /// .updateSettings` writes the whole `settings` map with `update()`
  /// (whole-map replace, not a merge), same as every other field of
  /// [OrganizationSettings] — a caller updating settings must always
  /// resend every value it wants to keep.
  final String? segment;
  final int? maxTeamsPerUser;
  final List<String> requiredCustomerFields;
  final List<String> customerAddressTypes;
  final List<String> customerContactTypes;

  /// See `OrganizationSettings.allowMultipleCollectionsPerProduct`'s own
  /// doc. Same whole-map-replace caveat as [segment]: a future
  /// `updateSettings` call must resend `true` to keep it, or it resets to
  /// the `false` default.
  final bool allowMultipleCollectionsPerProduct;
  final int stockReservationExpiresInMinutes;

  /// See `OrganizationSettings.positivacaoPeriodGranularity`/
  /// `positivacaoEligibleOrderStatuses`/`positivacaoMinOrderValue`'s own docs
  /// (TASK-117). Always written (like [stockReservationExpiresInMinutes]),
  /// never conditionally omitted, so [fromJson] never needs to guess whether
  /// a missing key means "not configured yet" vs. "explicitly cleared".
  final String positivacaoPeriodGranularity;
  final List<String> positivacaoEligibleOrderStatuses;
  final double? positivacaoMinOrderValue;

  /// See `OrganizationSettings.rankingVisibilityMode`'s own doc (TASK-118).
  /// Always written, never conditionally omitted — same rationale as
  /// [positivacaoPeriodGranularity].
  final String rankingVisibilityMode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currency': currency,
      'country': country,
      'defaultLanguage': defaultLanguage,
      if (segment != null) 'segment': segment,
      if (maxTeamsPerUser != null) 'maxTeamsPerUser': maxTeamsPerUser,
      if (requiredCustomerFields.isNotEmpty)
        'requiredCustomerFields': requiredCustomerFields,
      if (customerAddressTypes.isNotEmpty)
        'customerAddressTypes': customerAddressTypes,
      if (customerContactTypes.isNotEmpty)
        'customerContactTypes': customerContactTypes,
      if (allowMultipleCollectionsPerProduct)
        'allowMultipleCollectionsPerProduct': true,
      'stockReservationExpiresInMinutes': stockReservationExpiresInMinutes,
      'positivacaoPeriodGranularity': positivacaoPeriodGranularity,
      'positivacaoEligibleOrderStatuses': positivacaoEligibleOrderStatuses,
      if (positivacaoMinOrderValue != null)
        'positivacaoMinOrderValue': positivacaoMinOrderValue,
      'rankingVisibilityMode': rankingVisibilityMode,
    };
  }
}

List<String> _stringListFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid organization settings payload.',
      code: 'invalid_organization_settings_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}
