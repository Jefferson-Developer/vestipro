import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'organization_settings.freezed.dart';

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
  }) = _OrganizationSettings;

  /// Builds validated [OrganizationSettings], trimming each value and
  /// rejecting blanks. Used by every caller that can create or change
  /// settings (create, update, future imports) so they all share the same
  /// guarantee instead of re-implementing it.
  factory OrganizationSettings.validated({
    required String currency,
    required String country,
    required String defaultLanguage,
  }) {
    final fieldErrors = <String, String>{};
    final trimmedCurrency = currency.trim();
    final trimmedCountry = country.trim();
    final trimmedDefaultLanguage = defaultLanguage.trim();

    if (trimmedCurrency.isEmpty) {
      fieldErrors['currency'] = 'Currency is required.';
    }
    if (trimmedCountry.isEmpty) {
      fieldErrors['country'] = 'Country is required.';
    }
    if (trimmedDefaultLanguage.isEmpty) {
      fieldErrors['defaultLanguage'] = 'Default language is required.';
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
    );
  }
}
