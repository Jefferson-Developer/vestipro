import '../../../../core/errors/errors.dart';

/// JSON-serializable shape of `OnboardingProgress`, persisted as a single
/// string value in local device storage (TASK-038,
/// `SharedPreferencesOnboardingProgressDataSource`).
final class OnboardingProgressDto {
  const OnboardingProgressDto({
    required this.stepIndex,
    required this.organizationName,
    required this.currency,
    required this.country,
    required this.defaultLanguage,
    this.segmentCode,
  });

  factory OnboardingProgressDto.fromJson(Map<String, dynamic> json) {
    final stepIndex = json['stepIndex'];
    final organizationName = json['organizationName'];
    final currency = json['currency'];
    final country = json['country'];
    final defaultLanguage = json['defaultLanguage'];
    final segmentCode = json['segmentCode'];

    if (stepIndex is! int ||
        organizationName is! String ||
        currency is! String ||
        country is! String ||
        defaultLanguage is! String ||
        (segmentCode != null && segmentCode is! String)) {
      throw const ValidationException(
        'Invalid onboarding progress payload.',
        code: 'invalid_onboarding_progress_payload',
      );
    }

    return OnboardingProgressDto(
      stepIndex: stepIndex,
      organizationName: organizationName,
      currency: currency,
      country: country,
      defaultLanguage: defaultLanguage,
      segmentCode: segmentCode as String?,
    );
  }

  /// Index into `OnboardingStep.values` — never the enum name itself, so a
  /// future step reorder is a deliberate migration, not an accident.
  final int stepIndex;
  final String organizationName;
  final String currency;
  final String country;
  final String defaultLanguage;
  final String? segmentCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stepIndex': stepIndex,
      'organizationName': organizationName,
      'currency': currency,
      'country': country,
      'defaultLanguage': defaultLanguage,
      if (segmentCode != null) 'segmentCode': segmentCode,
    };
  }
}
