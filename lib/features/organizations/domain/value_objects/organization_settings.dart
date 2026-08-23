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
  }) {
    final fieldErrors = <String, String>{};
    final trimmedCurrency = currency.trim();
    final trimmedCountry = country.trim();
    final trimmedDefaultLanguage = defaultLanguage.trim();
    final trimmedSegment = segment?.trim();

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
      segment: (trimmedSegment == null || trimmedSegment.isEmpty)
          ? null
          : trimmedSegment,
    );
  }
}
