import '../../../../core/errors/errors.dart';

final class OrganizationSettingsDto {
  const OrganizationSettingsDto({
    required this.currency,
    required this.country,
    required this.defaultLanguage,
    this.segment,
  });

  factory OrganizationSettingsDto.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    final country = json['country'];
    final defaultLanguage = json['defaultLanguage'];
    final segment = json['segment'];

    if (currency is! String ||
        country is! String ||
        defaultLanguage is! String ||
        (segment != null && segment is! String)) {
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currency': currency,
      'country': country,
      'defaultLanguage': defaultLanguage,
      if (segment != null) 'segment': segment,
    };
  }
}
