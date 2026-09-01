enum PositivacaoSettingsLoadStatus { initial, loading, ready, failure }

enum PositivacaoSettingsSaveStatus { idle, submitting, success, failure }

/// Drives the positivação settings admin screen (TASK-117, EPIC-15/
/// VESTI-087): the organization-configurable rule
/// (`OrganizationSettings.positivacao*`) an OWNER/ADMIN edits — never a
/// hardcoded rule in the `targets` feature.
final class PositivacaoSettingsState {
  const PositivacaoSettingsState({
    this.loadStatus = PositivacaoSettingsLoadStatus.initial,
    this.saveStatus = PositivacaoSettingsSaveStatus.idle,
    this.organizationId = '',
    this.updatedBy = '',
    this.periodGranularity = 'monthly',
    this.eligibleOrderStatuses = const <String>{},
    this.minOrderValueInput = '',
    this.fieldErrors = const <String, String>{},
    this.failureMessage,
  });

  final PositivacaoSettingsLoadStatus loadStatus;
  final PositivacaoSettingsSaveStatus saveStatus;
  final String organizationId;
  final String updatedBy;
  final String periodGranularity;
  final Set<String> eligibleOrderStatuses;

  /// Raw text field input — empty means "no minimum".
  final String minOrderValueInput;
  final Map<String, String> fieldErrors;
  final String? failureMessage;

  bool get isBusy =>
      loadStatus == PositivacaoSettingsLoadStatus.loading ||
      saveStatus == PositivacaoSettingsSaveStatus.submitting;

  PositivacaoSettingsState copyWith({
    PositivacaoSettingsLoadStatus? loadStatus,
    PositivacaoSettingsSaveStatus? saveStatus,
    String? organizationId,
    String? updatedBy,
    String? periodGranularity,
    Set<String>? eligibleOrderStatuses,
    String? minOrderValueInput,
    Map<String, String>? fieldErrors,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return PositivacaoSettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      organizationId: organizationId ?? this.organizationId,
      updatedBy: updatedBy ?? this.updatedBy,
      periodGranularity: periodGranularity ?? this.periodGranularity,
      eligibleOrderStatuses:
          eligibleOrderStatuses ?? this.eligibleOrderStatuses,
      minOrderValueInput: minOrderValueInput ?? this.minOrderValueInput,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
