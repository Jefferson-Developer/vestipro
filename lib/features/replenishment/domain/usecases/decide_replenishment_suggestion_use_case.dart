import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/replenishment_decision_result.dart';
import '../repositories/replenishment_repository.dart';
import '../value_objects/replenishment_decision_action.dart';

/// Accepts/adjusts/discards one `ReplenishmentSuggestion` (TASK-184,
/// EPIC-27) through the idempotent `decideReplenishmentSuggestion` Cloud
/// Function — the one and only place this decision is authorized/persisted
/// and a `ReplenishmentDraftOrder` is created; nothing here decides RBAC or
/// the resulting status itself, both are re-validated server-side.
///
/// [Capability.reportViewSensitive] is re-checked here as defense-in-depth
/// (same precedent [DecideOrderApprovalUseCase] already sets for
/// [Capability.orderApprove]) — `decideReplenishmentSuggestion` remains the
/// real, independent source of truth (OWNER/ADMIN/SALES_MANAGER only, see
/// that Function's own `ROLES_ALLOWED_TO_DECIDE`).
///
/// An `adjust` decision without a non-null, non-negative [adjustedQuantity]
/// never reaches the Cloud Function at all — validated here the same way
/// `DecideOrderApprovalUseCase` requires a non-blank rejection reason before
/// any network call.
@injectable
final class DecideReplenishmentSuggestionUseCase {
  const DecideReplenishmentSuggestionUseCase(
    this._repository,
    this._permissionService,
    this._analyticsService,
  );

  final ReplenishmentRepository _repository;
  final PermissionService _permissionService;
  final AnalyticsService _analyticsService;

  Future<AppResult<ReplenishmentDecisionResult>> call({
    required String organizationId,
    required String suggestionId,
    required String userId,
    required ReplenishmentDecisionAction action,
    int? adjustedQuantity,
    String? note,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedSuggestionId = suggestionId.trim();
    final trimmedUserId = userId.trim();
    final trimmedNote = note?.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedSuggestionId.isEmpty) {
      fieldErrors['suggestionId'] = 'SuggestionId is required.';
    }
    if (trimmedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (action == ReplenishmentDecisionAction.adjust &&
        (adjustedQuantity == null || adjustedQuantity < 0)) {
      fieldErrors['adjustedQuantity'] =
          'Informe uma quantidade ajustada válida (maior ou igual a zero).';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ReplenishmentDecisionResult>(
        ValidationFailure(
          'Invalid replenishment suggestion decision payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_replenishment_suggestion_decision_payload',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      capability: Capability.reportViewSensitive,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<ReplenishmentDecisionResult>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<ReplenishmentDecisionResult>(
        PermissionFailure(
          'User is not allowed to decide replenishment suggestions.',
          code: 'replenishment_suggestion_decide_denied',
        ),
      );
    }

    final result = await _repository.decide(
      organizationId: trimmedOrganizationId,
      suggestionId: trimmedSuggestionId,
      action: action,
      adjustedQuantity: action == ReplenishmentDecisionAction.adjust
          ? adjustedQuantity
          : null,
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    if (result case AppSuccess<ReplenishmentDecisionResult>(
      value: final decided,
    )) {
      await _analyticsService.logEvent(
        AnalyticsEvents.replenishmentSuggestionDecided,
        parameters: <String, Object?>{
          'organization_id': trimmedOrganizationId,
          'suggestion_id': decided.suggestionId,
          'action': action.code,
          'final_quantity': decided.finalQuantity,
        },
      );
    }
    return result;
  }
}
