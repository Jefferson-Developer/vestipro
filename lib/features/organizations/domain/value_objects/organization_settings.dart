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
