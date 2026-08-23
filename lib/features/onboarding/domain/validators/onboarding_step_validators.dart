/// Pure client-side, per-step validation for the onboarding wizard
/// (TASK-038). Runs before [OnboardingBloc] allows advancing past a step or
/// completing the wizard, so [CompleteOnboardingUseCase] never has to reject
/// a payload the UI should have already blocked — same rationale as
/// `sign_up_form_validators.dart`. Free of Flutter/domain-entity imports.
library;

import '../value_objects/organization_segment.dart';

/// Returns a user-facing message when [value] is not a plausible
/// Organization name, or `null` when it passes this (intentionally loose)
/// client-side check.
String? validateOrganizationName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Informe o nome da organização.';
  }
  if (trimmed.length < 2) {
    return 'Informe um nome válido.';
  }
  return null;
}

/// Returns a user-facing message when no fashion segment has been chosen,
/// or `null` once one has.
String? validateOrganizationSegment(OrganizationSegment? value) {
  if (value == null) {
    return 'Selecione o segmento da organização.';
  }
  return null;
}

/// Returns a user-facing message when [value] is blank, or `null` when it
/// passes. Used for both [validateCurrency]/[validateCountry], which share
/// the exact same "must not be blank" rule (both are pre-filled with a
/// sensible default and only ever blank if the user explicitly clears the
/// field).
String? _validateRequiredCode(String value, String fieldLabel) {
  if (value.trim().isEmpty) {
    return 'Selecione $fieldLabel.';
  }
  return null;
}

String? validateCurrency(String value) =>
    _validateRequiredCode(value, 'a moeda');

String? validateCountry(String value) => _validateRequiredCode(value, 'o país');

String? validateDefaultLanguage(String value) =>
    _validateRequiredCode(value, 'o idioma padrão');
