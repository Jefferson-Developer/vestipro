enum BrandingSettingsLoadStatus { initial, loading, ready, failure }

enum BrandingSettingsSaveStatus { idle, submitting, success, failure }

/// Drives the catalog branding admin screen (TASK-179, EPIC-25): the
/// organization-configurable white-label identity
/// (`OrganizationSettings.brandingLogoUrl`/`brandingPrimaryColorHex`,
/// TASK-148) an OWNER/ADMIN edits, with a live preview of the branded
/// catalog before publishing.
final class BrandingSettingsState {
  const BrandingSettingsState({
    this.loadStatus = BrandingSettingsLoadStatus.initial,
    this.saveStatus = BrandingSettingsSaveStatus.idle,
    this.organizationId = '',
    this.updatedBy = '',
    this.logoUrlInput = '',
    this.primaryColorHexInput = '',
    this.usesContrastFallback = false,
    this.fieldErrors = const <String, String>{},
    this.failureMessage,
  });

  final BrandingSettingsLoadStatus loadStatus;
  final BrandingSettingsSaveStatus saveStatus;
  final String organizationId;
  final String updatedBy;

  /// Raw text field input — empty means "not configured".
  final String logoUrlInput;

  /// Raw text field input, e.g. `#1F5364` — empty means "not configured".
  final String primaryColorHexInput;

  /// Whether [primaryColorHexInput], as currently typed, needs the Design
  /// System's automatic contrast fallback (`AppBrandTheme
  /// .needsContrastFallback`) to stay accessible — drives the inline
  /// warning shown next to the live preview. Recomputed on every
  /// [logoUrlInput]/[primaryColorHexInput] change, never only at submit
  /// time, so the warning is always live.
  final bool usesContrastFallback;

  final Map<String, String> fieldErrors;
  final String? failureMessage;

  bool get isBusy =>
      loadStatus == BrandingSettingsLoadStatus.loading ||
      saveStatus == BrandingSettingsSaveStatus.submitting;

  BrandingSettingsState copyWith({
    BrandingSettingsLoadStatus? loadStatus,
    BrandingSettingsSaveStatus? saveStatus,
    String? organizationId,
    String? updatedBy,
    String? logoUrlInput,
    String? primaryColorHexInput,
    bool? usesContrastFallback,
    Map<String, String>? fieldErrors,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return BrandingSettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      organizationId: organizationId ?? this.organizationId,
      updatedBy: updatedBy ?? this.updatedBy,
      logoUrlInput: logoUrlInput ?? this.logoUrlInput,
      primaryColorHexInput: primaryColorHexInput ?? this.primaryColorHexInput,
      usesContrastFallback: usesContrastFallback ?? this.usesContrastFallback,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
