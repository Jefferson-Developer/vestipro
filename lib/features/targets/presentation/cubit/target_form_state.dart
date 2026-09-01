import '../../domain/entities/target.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../../domain/value_objects/target_period_granularity.dart';
import '../../domain/value_objects/target_status.dart';

enum TargetFormLoadStatus { idle, loading, ready, failure }

enum TargetFormSaveStatus {
  idle,
  editing,
  submitting,
  success,
  failure,

  /// Terminal-but-not-saved state reached when `UpdateTargetUseCase` returns
  /// `target_value_below_achieved`: the form must show the warning and ask
  /// the user to confirm before calling `submit(confirmReduceBelowAchieved:
  /// true)` again — never silently retried.
  needsReduceConfirmation,
}

/// Draft/list state backing `TargetFormCubit` (TASK-115), mirroring the
/// shape `DiscountPolicyState`/`PromotionalCampaignState` already use for a
/// combined "cadastro + lista" admin form.
final class TargetFormState {
  const TargetFormState({
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.actorName = '',
    this.loadStatus = TargetFormLoadStatus.idle,
    this.saveStatus = TargetFormSaveStatus.idle,
    this.targets = const <Target>[],
    this.editingId,
    this.dimensionType = TargetDimensionType.salesRep,
    this.dimensionId = '',
    this.periodGranularity = TargetPeriodGranularity.monthly,
    this.startDate,
    this.endDate,
    this.metricType = TargetMetricType.revenue,
    this.targetValueInput = '',
    this.currency = 'BRL',
    this.status = TargetStatus.active,
    this.currentAchievedValue,
    this.fieldErrors = const <String, String>{},
    this.failureMessage,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final TargetFormLoadStatus loadStatus;
  final TargetFormSaveStatus saveStatus;
  final List<Target> targets;
  final String? editingId;
  final TargetDimensionType dimensionType;
  final String dimensionId;
  final TargetPeriodGranularity periodGranularity;
  final DateTime? startDate;
  final DateTime? endDate;
  final TargetMetricType metricType;
  final String targetValueInput;
  final String currency;
  final TargetStatus status;

  /// Known `achievedValueCache` for [editingId], when the caller supplied
  /// one (e.g. from the TASK-116 dashboard's local cache) — `null` while
  /// creating or when it is simply unknown yet.
  final double? currentAchievedValue;
  final Map<String, String> fieldErrors;
  final String? failureMessage;

  bool get isBusy =>
      loadStatus == TargetFormLoadStatus.loading ||
      saveStatus == TargetFormSaveStatus.submitting;
  bool get isEditing => editingId != null;
  bool get needsReduceConfirmation =>
      saveStatus == TargetFormSaveStatus.needsReduceConfirmation;

  TargetFormState copyWith({
    String? organizationId,
    String? companyId,
    String? userId,
    String? actorName,
    TargetFormLoadStatus? loadStatus,
    TargetFormSaveStatus? saveStatus,
    List<Target>? targets,
    String? editingId,
    bool clearEditingId = false,
    TargetDimensionType? dimensionType,
    String? dimensionId,
    TargetPeriodGranularity? periodGranularity,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    TargetMetricType? metricType,
    String? targetValueInput,
    String? currency,
    TargetStatus? status,
    double? currentAchievedValue,
    bool clearCurrentAchievedValue = false,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return TargetFormState(
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      targets: targets ?? this.targets,
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
      dimensionType: dimensionType ?? this.dimensionType,
      dimensionId: dimensionId ?? this.dimensionId,
      periodGranularity: periodGranularity ?? this.periodGranularity,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      metricType: metricType ?? this.metricType,
      targetValueInput: targetValueInput ?? this.targetValueInput,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      currentAchievedValue: clearCurrentAchievedValue
          ? null
          : (currentAchievedValue ?? this.currentAchievedValue),
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : (fieldErrors ?? this.fieldErrors),
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
