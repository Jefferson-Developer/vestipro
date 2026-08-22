import '../../../../core/errors/errors.dart';

final class OrganizationSettingsDto {
  const OrganizationSettingsDto({
    required this.currency,
    required this.country,
    required this.defaultLanguage,
  });

  factory OrganizationSettingsDto.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    final country = json['country'];
    final defaultLanguage = json['defaultLanguage'];

    if (currency is! String ||
        country is! String ||
        defaultLanguage is! String) {
      throw const ValidationException(
        'Invalid organization settings payload.',
        code: 'invalid_organization_settings_payload',
      );
    }

    return OrganizationSettingsDto(
      currency: currency,
      country: country,
      defaultLanguage: defaultLanguage,
    );
  }

  final String currency;
  final String country;
  final String defaultLanguage;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currency': currency,
      'country': country,
      'defaultLanguage': defaultLanguage,
    };
  }
}
